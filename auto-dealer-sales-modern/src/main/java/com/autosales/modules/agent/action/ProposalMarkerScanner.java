package com.autosales.modules.agent.action;

/**
 * Single-pass scanner that pulls a [[PROPOSE]]...[[/PROPOSE]] block out of a
 * streaming LLM response while preserving user-visible prose untouched.
 *
 * Design — the agent skill instructs Claude to emit a marker pair at the END
 * of the response; the scanner forwards all content up to the OPEN marker and
 * holds everything afterwards. When the CLOSE marker arrives, the JSON body is
 * extracted; trailing prose (rare) is forwarded too.
 *
 * Not thread-safe — one scanner per stream.
 */
public final class ProposalMarkerScanner {

    public static final String OPEN  = "[[PROPOSE]]";
    public static final String CLOSE = "[[/PROPOSE]]";

    /** Holdback: if the tail of the buffer matches a prefix of OPEN, don't forward it yet. */
    private static final int HOLDBACK = OPEN.length() - 1;

    private final StringBuilder buffer = new StringBuilder();
    private int forwardedUpTo = 0;
    private int openStart = -1;
    private int openEnd   = -1;
    private int closeStart = -1;
    private String extractedJson;

    /**
     * Feed a delta chunk. Returns the substring to forward to the user now
     * (may be empty). Guaranteed: returned text never contains any part of the
     * marker.
     */
    public String onDelta(String chunk) {
        if (chunk == null || chunk.isEmpty()) return "";
        buffer.append(chunk);
        StringBuilder out = new StringBuilder();

        if (openStart < 0) {
            int idx = buffer.indexOf(OPEN, forwardedUpTo);
            if (idx >= 0) {
                if (idx > forwardedUpTo) out.append(buffer, forwardedUpTo, idx);
                openStart = idx;
                openEnd = idx + OPEN.length();
                forwardedUpTo = openEnd;
            } else {
                int safe = buffer.length() - HOLDBACK;
                if (safe > forwardedUpTo) {
                    out.append(buffer, forwardedUpTo, safe);
                    forwardedUpTo = safe;
                }
            }
        }

        if (openStart >= 0 && extractedJson == null) {
            int idx = buffer.indexOf(CLOSE, openEnd);
            if (idx >= 0) {
                closeStart = idx;
                extractedJson = buffer.substring(openEnd, idx).trim();
                forwardedUpTo = idx + CLOSE.length();
                if (buffer.length() > forwardedUpTo) {
                    out.append(buffer, forwardedUpTo, buffer.length());
                    forwardedUpTo = buffer.length();
                }
            }
        }

        return out.toString();
    }

    /**
     * Called when the stream ends. Returns any remaining buffered prose that
     * was held pending marker resolution. If a proposal block was never closed,
     * the held content surfaces as normal prose (degraded — user sees raw marker).
     */
    public String flush() {
        if (forwardedUpTo >= buffer.length()) return "";
        if (openStart >= 0 && extractedJson == null) {
            String tail = buffer.substring(forwardedUpTo);
            forwardedUpTo = buffer.length();
            return tail;
        }
        String tail = buffer.substring(forwardedUpTo);
        forwardedUpTo = buffer.length();
        return tail;
    }

    public boolean hasProposal() { return extractedJson != null; }

    public String extractedJson() { return extractedJson; }

    /**
     * Returns the full buffered content with the proposal block removed.
     * Useful for the non-stream path where the entire response is available
     * at once and we want to persist clean prose.
     */
    public String cleanedContent() {
        if (openStart < 0) return buffer.toString();
        int afterClose = closeStart >= 0 ? closeStart + CLOSE.length() : buffer.length();
        String head = buffer.substring(0, openStart);
        String tail = afterClose < buffer.length() ? buffer.substring(afterClose) : "";
        return head + tail;
    }
}
