package com.autosales.eval;

import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.fail;

/**
 * Agent regression suite v1 — opt-in, drives the live deploy.
 *
 * <h2>Activation</h2>
 * Class is gated on a system property so {@code mvn test} skips it entirely
 * (zero overhead in the normal cycle, no Cloud Run dependency for unit tests):
 *
 * <pre>
 *   ./mvnw.cmd test -Dtest=AgentRegressionTest -Deval.run=true \
 *                   -Deval.target=https://autosales-frontend-...run.app
 * </pre>
 *
 * <h2>What it does</h2>
 * For each YAML under {@code eval/prompts/}:
 * <ol>
 *   <li>Login as the configured user → JWT</li>
 *   <li>POST the prompt to {@code /api/agent} (persistent mode, fresh conversation)</li>
 *   <li>GET {@code /api/admin/agent-trace/{conversationId}} for the tool-call audit</li>
 *   <li>Evaluate assertions (reply shape, tool-calls observed, latency, tokens, proposal)</li>
 * </ol>
 *
 * <h2>Output</h2>
 * Standard JUnit per-test pass/fail to console + a unified report at
 * {@code target/eval-report.md} containing per-prompt timing, observed tool
 * calls, reply excerpts, and assertion failures. The markdown is designed to
 * paste into a PR description.
 *
 * <h2>Why HTTP, not in-process Spring</h2>
 * v1 deliberately exercises the real production path — JWT, CORS, nginx /api
 * proxy, Cloud SQL, Vertex AI quota. That's the production-readiness theme.
 * v2 may add an in-process mode for faster smoke during local development.
 */
@EnabledIfSystemProperty(named = "eval.run", matches = "true")
public class AgentRegressionTest {

    @TestFactory
    Stream<DynamicTest> runRegressionCorpus() throws IOException {
        String target = System.getProperty("eval.target");
        if (target == null || target.isBlank()) {
            throw new IllegalStateException(
                    "Missing -Deval.target=<base URL>. Typically the frontend Cloud Run URL " +
                            "(e.g. https://autosales-frontend-XXXX-uc.a.run.app). The runner posts to " +
                            "${target}/api/agent and reads ${target}/api/admin/agent-trace/{convId}.");
        }

        EvalDriver driver = new EvalDriver(target);
        List<EvalPrompt> corpus = driver.loadCorpus(Path.of("eval", "prompts"));
        if (corpus.isEmpty()) {
            throw new IllegalStateException(
                    "No prompts found under eval/prompts/. Add at least one t-*.yml file.");
        }

        return corpus.stream()
                .map(prompt -> DynamicTest.dynamicTest(prompt.id(), () -> {
                    EvalDriver.Result result = driver.run(prompt);
                    if (!result.passed()) {
                        fail(result.failureSummary());
                    }
                }))
                .onClose(() -> {
                    try {
                        driver.writeReport(Path.of("target", "eval-report.md"));
                    } catch (IOException ignore) {
                        // Report-writing failure shouldn't mask test results.
                    }
                });
    }
}
