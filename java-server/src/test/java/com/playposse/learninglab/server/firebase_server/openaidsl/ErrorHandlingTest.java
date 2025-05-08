// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ErrorHandlingTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

class ErrorHandlingTest {

    private ChatConfig       defaults;
    private FakeOpenAiClient fakeClient;

    private static final Label<String> L0 = Label.of("step0", String.class);
    private static final Label<String> L1 = Label.of("step1", String.class);

    @BeforeEach
    void setup() {
        defaults   = new DefaultsBuilder().build();
        fakeClient = new FakeOpenAiClient();
    }

    @Test
    void clientExceptionDoesNotStopChain() {
        // only stub step1; step0 will throw IllegalStateException
        fakeClient.whenContains("step1", "R1");

        Chain chain = ChainBuilder
                .start(defaults)
                .step("step0")
                .user("step0")
                .parse(Parsers.string())
                .label(L0)
                .endStep()
                .step("step1")
                .user("step1")
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);

        // step0 errored
        assertFalse(result.has(L0),    "step0 should have no value");
        assertTrue(result.hasError(L0), "step0 should record an error");
        ErrorInfo err0 = result.getError(L0);
        assertEquals("step0", err0.stepName());
        assertTrue(err0.cause() instanceof IllegalStateException);

        // step1 succeeded
        assertTrue(result.has(L1));
        assertFalse(result.hasError(L1));
        assertEquals("R1", result.get(L1));

        // exactly two call logs
        assertEquals(2, result.callLogs().size());
    }

    @Test
    void parserExceptionDoesNotStopChain() {
        // stub both calls so the fake never falls back
        fakeClient.whenContains("step0", "IGNORED");
        fakeClient.whenContains("step1", "X1");

        Chain chain = ChainBuilder
                .start(defaults)
                // step0 uses a parser that always throws
                .step("step0")
                .user("step0")
                .parse(input -> { throw new RuntimeException("parse fail"); })
                .label(L0)
                .endStep()
                // step1 should still run
                .step("step1")
                .user("step1")
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);

        // step0 parser error
        assertFalse(result.has(L0));
        assertTrue(result.hasError(L0));
        ErrorInfo err0 = result.getError(L0);
        assertEquals("step0", err0.stepName());
        assertTrue(err0.cause() instanceof RuntimeException);
        assertEquals("parse fail", err0.cause().getMessage());

        // step1 still runs
        assertTrue(result.has(L1));
        assertEquals("X1", result.get(L1));

        // two call logs
        assertEquals(2, result.callLogs().size());
    }
}
