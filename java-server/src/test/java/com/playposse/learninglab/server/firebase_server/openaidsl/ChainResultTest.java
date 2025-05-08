// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ChainResultTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.JsonNode;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.*;

class ChainResultTest {

    private ChatConfig      defaults;
    private FakeOpenAiClient fakeClient;

    private static final Label<String> STEP0 = Label.of("step0", String.class);
    private static final Label<String> STEP1 = Label.of("step1", String.class);
    private static final Label<String> STEP2 = Label.of("step2", String.class);

    @BeforeEach
    void setUp() {
        defaults   = new DefaultsBuilder().build();
        fakeClient = new FakeOpenAiClient();
    }

    @Test
    void testAsMapAsStringKeyMapAndToJson() throws Exception {
        // stub two steps
        fakeClient.whenContains("a", "A");
        fakeClient.whenContains("b", "B");

        Chain chain = ChainBuilder
                .start(defaults)
                .step("step0")
                .user("a")
                .parse(Parsers.string())
                .label(STEP0)
                .endStep()
                .step("step1")
                .user("b")
                .parse(Parsers.string())
                .label(STEP1)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);

        // asMap: Label<?> -> Object
        Map<Label<?>, Object> map = result.asMap();
        assertEquals(2, map.size());
        assertEquals("A", map.get(STEP0));
        assertEquals("B", map.get(STEP1));

        // asStringKeyMap: String -> Object
        Map<String,Object> skm = result.asStringKeyMap();
        assertEquals(2, skm.size());
        assertEquals("A", skm.get("step0"));
        assertEquals("B", skm.get("step1"));

        // toJson: verify JSON fields
        JsonNode json = result.toJson();
        assertTrue(json.has("step0"));
        assertTrue(json.has("step1"));
        assertEquals("A", json.get("step0").asText());
        assertEquals("B", json.get("step1").asText());
    }

    @Test
    void testSliceAndLabelsAndCallLogs() {
        // stub three steps
        fakeClient.whenContains("x", "X");
        fakeClient.whenContains("y", "Y");
        fakeClient.whenContains("z", "Z");

        Chain chain = ChainBuilder
                .start(defaults)
                .step("step0")
                .user("x")
                .parse(Parsers.string())
                .label(STEP0)
                .endStep()
                .step("step1")
                .user("y")
                .parse(Parsers.string())
                .label(STEP1)
                .endStep()
                .step("step2")
                .user("z")
                .parse(Parsers.string())
                .label(STEP2)
                .endStep()
                .build();

        ChainResult full = chain.run(fakeClient);

        // full labels
        Set<Label<?>> allLabels = full.labels();
        assertEquals(Set.of(STEP0, STEP1, STEP2), allLabels);

        // full callLogs
        assertEquals(3, full.callLogs().size());

        // slice to only step0 & step2
        ChainResult slice = full.slice(STEP0, STEP2);
        Set<Label<?>> sliceLabels = slice.labels();
        assertEquals(Set.of(STEP0, STEP2), sliceLabels);

        // sliced callLogs only for those labels (in order)
        List<CallLog> logs = slice.callLogs();
        List<Label<?>> logLabels = logs.stream()
                .map(CallLog::label)
                .toList();
        assertEquals(List.of(STEP0, STEP2), logLabels);
    }

    @Test
    void testErrorsAndGetError() {
        // stub "ok" → "OK", leave "fail" unmapped so FakeOpenAiClient throws
        fakeClient.whenContains("ok", "OK");

        Label<String> L0 = Label.of("step0", String.class);
        Label<String> L1 = Label.of("step1", String.class);

        Chain chain = ChainBuilder
                .start(defaults)
                .step("step0")
                .user("ok")
                .parse(Parsers.string())
                .label(L0)
                .endStep()
                .step("step1")
                .user("fail")
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);

        // step0 should succeed
        assertTrue(result.has(L0));
        assertEquals("OK", result.get(L0));
        assertFalse(result.hasError(L0));

        // step1 should have no value but an error
        assertFalse(result.has(L1));
        assertTrue(result.hasError(L1));
        ErrorInfo err = result.getError(L1);
        assertEquals("step1", err.stepName());
        assertTrue(err.cause() instanceof IllegalStateException);

        // errors() map only contains L1
        Map<Label<?>,ErrorInfo> errs = result.errors();
        assertEquals(1, errs.size());
        assertTrue(errs.containsKey(L1));
    }
}
