package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

class ChainTest {

    private FakeOpenAiClient fakeClient;
    private ChatConfig defaults;

    // Labels for the test
    private static final Label<String>  OUTLINE = Label.of("outline", String.class);
    private static final Label<List<String>> ITEMS = Label.of("items", new com.fasterxml.jackson.core.type.TypeReference<>() {});
    private static final Label<String>  DETAIL  = Label.of("detail", String.class);
    private static final Label<Map<String,Object>> PARALLEL = Label.of("parallel", new com.fasterxml.jackson.core.type.TypeReference<>() {});

    @BeforeEach
    void setUp() {
        fakeClient = new FakeOpenAiClient();
        fakeClient.whenContains("outline", "A\nB\nC");
        fakeClient.whenContains("detail", "detail-of-");

        fakeClient.whenContains("dummy1", "ONE");
        fakeClient.whenContains("dummy2", "TWO");

        defaults = new DefaultsBuilder().build();
    }
    @Test
    void testSerialAndForEachAndParallel() {
        // Build a chain: outline → split lines → forEach(detail) → parallel (just echo)
        Chain chain = ChainBuilder
                .start(defaults)

                // 1) Outline step
                .step("makeOutline")
                .user("outline this")
                .parse(Parsers.stringList())
                .label(ITEMS)
                .endStep()

                // 2) ForEach over ITEMS
                .<String>forEach(ITEMS)
                .alias("item")
                .maxElements(5)
                .addStep(
                        StepBuilder.start("makeDetail", defaults)
                                .user("detail " + "${item}")
                                .parse(Parsers.string())
                                .label(DETAIL)
                                .build()
                )
                .joinInto(Label.of("details", new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {}))
                .endForEach()

                // 3) Parallel block: return two branches that just echo a constant
                .parallel()
                .branch("one", StepBuilder.start("branch1", defaults)
                        .user("dummy1").parse(Parsers.string()).label(PARALLEL).build())
                .branch("two", StepBuilder.start("branch2", defaults)
                        .user("dummy2").parse(Parsers.string()).label(PARALLEL).build())
                .endParallel()

                .build();

        ChainResult result = chain.run(fakeClient);

        // Serial: OUTLINE produced a list
        assertTrue(result.has(ITEMS));
        List<String> items = result.get(ITEMS);
        assertEquals(List.of("A","B","C"), items);

        // ForEach: details list of "detail-of-A", etc.
        @SuppressWarnings("unchecked")
        List<String> details = (List<String>) result.get(Label.of("details", new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {}));
        assertEquals(List.of("detail-of-A","detail-of-B","detail-of-C"), details);

        // Parallel: a Map<String,Object> with keys "one" and "two"
        @SuppressWarnings("unchecked")
        Map<String,Object> parallelMap = (Map<String,Object>) result.get(PARALLEL);
        assertTrue(parallelMap.containsKey("one"));
        assertTrue(parallelMap.containsKey("two"));

        // Call logs length = serial call (1) + forEach calls (3) + 2 parallel = 6
        assertEquals(6, result.callLogs().size());
        // No errors
        assertTrue(result.errors().isEmpty());
    }

    @Test
    void testErrorPropagates() {
        // Stub outline to throw
        OpenAiClient bad = (msgs, cfg) -> { throw new RuntimeException("boom"); };

        Chain chain = ChainBuilder
                .start(defaults)
                .step("boom")
                .user("outline this")
                .parse(Parsers.string())
                .label(OUTLINE)
                .endStep()
                .build();

        ChainResult r = chain.run(bad);

        // Value is null (or absent) and error is recorded
        assertFalse(r.has(OUTLINE));
        assertTrue(r.hasError(OUTLINE));
        ErrorInfo info = r.getError(OUTLINE);
        assertEquals("boom", info.stepName());
        assertEquals("boom", info.cause().getMessage());
    }
}
