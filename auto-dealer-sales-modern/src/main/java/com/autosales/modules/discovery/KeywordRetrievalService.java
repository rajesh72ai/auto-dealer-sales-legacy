package com.autosales.modules.discovery;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;


/**
 * Per-turn retrieval over the auto-extracted endpoint catalog
 * ({@link ToolDescriptorExtractor#getCatalog()}).
 *
 * <p>Given the user's message, we tokenize it (lowercase, drop stop words),
 * score every {@link AutoToolDescriptor} by overlap against the descriptor's
 * name, path, description, and tags, and return the top-K matches above a
 * minimum-relevance threshold. The agent merges the retrieved descriptors
 * with its hand-curated tool catalog before sending the turn to Gemini —
 * giving the LLM access to ~98 auto-discovered read endpoints in addition
 * to the 32 curated tools.
 *
 * <p><b>Safety filter is non-negotiable.</b> Only descriptors with
 * {@code safetyLevel} of {@code PUBLIC_READ} or {@code INTERNAL_READ} are
 * considered. Writes, admin-only, and AGENT_NO endpoints are excluded
 * before scoring. {@link AutoDescriptorRouter} re-checks the safety level
 * at invocation time as a belt-and-suspenders guarantee.
 */
@Service
@RequiredArgsConstructor
public class KeywordRetrievalService {

    private static final Logger log = LoggerFactory.getLogger(KeywordRetrievalService.class);

    /** Only these safety levels are eligible for auto-discovery exposure. */
    private static final Set<String> ALLOWED_SAFETY = Set.of("PUBLIC_READ", "INTERNAL_READ");

    /**
     * English stop words — too generic to be useful as relevance signal.
     * We keep "list", "get", "show", "find" out of the stop set because
     * those align with verb-flavored tool names and help disambiguate.
     */
    private static final Set<String> STOP_WORDS = Set.of(
            "a","an","the","is","are","was","were","be","been","being","have","has","had",
            "do","does","did","will","would","shall","should","can","could","may","might","must",
            "of","to","in","on","at","by","for","with","about","into","through","during",
            "before","after","above","below","from","up","down","out","off","over","under",
            "again","further","then","once","here","there","when","where","why","how",
            "what","which","who","whom","this","that","these","those",
            "i","me","my","we","our","you","your","he","him","his","she","her","it","its",
            "they","them","their","and","or","but","not","no","nor","so","just",
            "please","tell","give","want","need","like"
    );

    /**
     * Minimum score for a descriptor to be returned. Below this, the match
     * is treated as noise. Tunable; 5 ≈ at least one strong (name) hit OR
     * two weaker (description) hits.
     */
    private static final int MIN_SCORE = 5;

    private final ToolDescriptorExtractor extractor;

    /**
     * Retrieve the top-K auto-discovered descriptors most relevant to the
     * user message. Returns an empty list for blank input or when no
     * descriptor scores above {@link #MIN_SCORE}.
     */
    public List<AutoToolDescriptor> retrieve(String userMessage, int topK) {
        if (userMessage == null || userMessage.isBlank()) return List.of();
        Set<String> tokens = tokenize(userMessage);
        if (tokens.isEmpty()) return List.of();

        List<Scored> scored = new ArrayList<>();
        for (AutoToolDescriptor d : extractor.getCatalog()) {
            if (d.getSafetyLevel() == null || !ALLOWED_SAFETY.contains(d.getSafetyLevel())) continue;
            if (!"GET".equalsIgnoreCase(d.getHttpMethod())) continue; // belt-and-suspenders
            int score = score(d, tokens);
            if (score >= MIN_SCORE) scored.add(new Scored(d, score));
        }
        scored.sort((a, b) -> Integer.compare(b.score(), a.score()));
        List<AutoToolDescriptor> result = scored.stream()
                .limit(topK)
                .map(Scored::descriptor)
                .toList();
        if (log.isDebugEnabled()) {
            log.debug("KeywordRetrievalService: tokens={}, candidates={}, returned={} (top score={})",
                    tokens, scored.size(), result.size(),
                    scored.isEmpty() ? 0 : scored.get(0).score());
        }
        return result;
    }

    private int score(AutoToolDescriptor d, Set<String> tokens) {
        String name = d.getName() == null ? "" : d.getName().toLowerCase(Locale.ROOT);
        String path = d.getPath() == null ? "" : d.getPath().toLowerCase(Locale.ROOT);
        String desc = d.getDescription() == null ? "" : d.getDescription().toLowerCase(Locale.ROOT);
        Set<String> tags = d.getTags() == null
                ? Set.of()
                : d.getTags().stream().map(t -> t.toLowerCase(Locale.ROOT)).collect(Collectors.toSet());

        int score = 0;
        for (String token : tokens) {
            // For each token try the literal form AND a singularized variant
            // ("lots" → "lot", "campaigns" → "campaign", "claims" → "claim").
            // Names and paths use singular nouns; users often type plural.
            for (String variant : variants(token)) {
                // Name hits are the strongest signal — synthetic names are derived
                // from path + verb so they encode the endpoint's purpose tightly.
                if (name.contains(variant)) score += 5;
                // Path matches rank just below name (same source material, less curated).
                if (path.contains(variant)) score += 4;
                // Tag matches — domain-flavored (customer, deal, inventory, etc.).
                if (tags.contains(variant)) score += 3;
                // Description matches are weakest — auto-generated text often padded
                // with verbs ("read", "create", etc.) that match too easily.
                if (desc.contains(variant)) score += 2;
            }
        }
        return score;
    }

    /**
     * Expand a token to itself plus a naive singular form. Avoids pulling in
     * a full stemmer dependency for what is, at the demo's scale, a handful
     * of suffixes that matter ("lots" → "lot", "claims" → "claim",
     * "incentives" → "incentive", "policies" → "policy").
     */
    private static List<String> variants(String token) {
        if (token.length() < 4) return List.of(token);
        if (token.endsWith("ies")) return List.of(token, token.substring(0, token.length() - 3) + "y");
        if (token.endsWith("es") && token.length() > 4) return List.of(token, token.substring(0, token.length() - 2));
        if (token.endsWith("s")) return List.of(token, token.substring(0, token.length() - 1));
        return List.of(token);
    }

    private Set<String> tokenize(String s) {
        return Arrays.stream(s.toLowerCase(Locale.ROOT).split("[^a-z0-9]+"))
                .filter(t -> t.length() > 1)
                .filter(t -> !STOP_WORDS.contains(t))
                .collect(Collectors.toCollection(HashSet::new));
    }

    private record Scored(AutoToolDescriptor descriptor, int score) {}
}
