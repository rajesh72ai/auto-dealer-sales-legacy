package com.autosales.modules.agent.action;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ProposalMarkerScannerTest {

    @Test
    void plainProse_isForwardedWithHoldback() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        String out1 = s.onDelta("Hello there, ");
        String out2 = s.onDelta("world!");
        String flushed = s.flush();
        assertEquals("Hello there, world!", out1 + out2 + flushed);
        assertFalse(s.hasProposal());
    }

    @Test
    void extractsMarkerFromCleanStream() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        StringBuilder forwarded = new StringBuilder();
        forwarded.append(s.onDelta("Summary of what I'll do: "));
        forwarded.append(s.onDelta("create a deal.\n\n"));
        forwarded.append(s.onDelta("[[PROPOSE]]"));
        forwarded.append(s.onDelta("{\"toolName\":\"create_deal\","));
        forwarded.append(s.onDelta("\"payload\":{\"customerId\":7}}"));
        forwarded.append(s.onDelta("[[/PROPOSE]]"));
        forwarded.append(s.flush());

        assertEquals("Summary of what I'll do: create a deal.\n\n", forwarded.toString());
        assertTrue(s.hasProposal());
        assertTrue(s.extractedJson().contains("\"toolName\":\"create_deal\""));
    }

    @Test
    void markerSpanningChunks_buffersUntilComplete() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        StringBuilder forwarded = new StringBuilder();
        forwarded.append(s.onDelta("OK "));
        forwarded.append(s.onDelta("[["));
        forwarded.append(s.onDelta("PROP"));
        forwarded.append(s.onDelta("OSE]]{"));
        forwarded.append(s.onDelta("\"x\":1}[[/PROPOSE]]"));
        forwarded.append(s.flush());

        assertEquals("OK ", forwarded.toString());
        assertTrue(s.hasProposal());
        assertEquals("{\"x\":1}", s.extractedJson());
    }

    @Test
    void trailingProseAfterCloseIsForwarded() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        StringBuilder forwarded = new StringBuilder();
        forwarded.append(s.onDelta("Plan: proceed. [[PROPOSE]]{\"a\":1}[[/PROPOSE]]\n\nReady."));
        forwarded.append(s.flush());
        assertEquals("Plan: proceed. \n\nReady.", forwarded.toString());
        assertTrue(s.hasProposal());
    }

    @Test
    void unclosedMarker_fallsBackToRawAtFlush() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        StringBuilder forwarded = new StringBuilder();
        forwarded.append(s.onDelta("Will create. [[PROPOSE]]{\"toolName\":\"create_deal\""));
        forwarded.append(s.flush());
        assertFalse(s.hasProposal());
        assertTrue(forwarded.toString().contains("{\"toolName\":\"create_deal\""));
    }

    @Test
    void cleanedContent_removesMarkerBlock() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        s.onDelta("Before. [[PROPOSE]]{\"x\":1}[[/PROPOSE]] After.");
        s.flush();
        assertEquals("Before.  After.", s.cleanedContent());
    }

    @Test
    void noMarker_cleanedEqualsInput() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        s.onDelta("Just prose.");
        s.flush();
        assertEquals("Just prose.", s.cleanedContent());
    }

    @Test
    void holdbackNeverReleasesMarkerPrefix() {
        ProposalMarkerScanner s = new ProposalMarkerScanner();
        String out = s.onDelta("Ok[[PROPO");
        assertFalse(out.contains("[["));
    }
}
