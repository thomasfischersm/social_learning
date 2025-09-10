// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ForEachStepTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import com.fasterxml.jackson.core.type.TypeReference;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ForEachStepTest {

    private ChatConfig defaults;
    private FakeOpenAiClient fake;

    private static final Label<List<String>> ITEMS =
            Label.of("items", new TypeReference<List<String>>() {});
    private static final Label<String> DETAIL =
            Label.of("detail", String.class);
    private static final Label<List<String>> DETAILS =
            Label.of("details", new TypeReference<List<String>>() {});
    private static final Label<String> OTHER =
            Label.of("other", String.class);

    @BeforeEach
    void setUp() {
        defaults = new DefaultsBuilder().build();
        fake     = new FakeOpenAiClient();
        // stub detail branch replies to echo prefix + item
        fake.whenContains("detail", "detail-of-");
        fake.whenContains("other", "other-value");
    }

    @Test
    void testNormalFanOut() {
        // stub outline → "X\nY\nZ"
        fake.whenContains("outline", "X\nY\nZ");

        Chain chain = ChainBuilder.start(defaults)
                // step 0: produce list of items
                .step("outline")
                .user("outline")
                .parse(Parsers.stringList())
                .label(ITEMS)
                .endStep()
                // unrelated label before the loop
                .step("other")
                .user("other")
                .parse(Parsers.string())
                .label(OTHER)
                .endStep()
                // forEach over ITEMS
                .forEach(ITEMS)
                .alias("item")
                .addStep(
                        StepBuilder
                                .start("detail", defaults)
                                .user("detail ${item}")
                                .parse(Parsers.string())
                                .label(DETAIL)
                                .build()
                )
                .joinInto(DETAILS)
                .endForEach()
                .build();

        ChainResult result = chain.run(fake);

        // verify results
        assertTrue(result.has(DETAILS));
        List<String> details = result.get(DETAILS);
        assertEquals(List.of("detail-of-X", "detail-of-Y", "detail-of-Z"), details);

        // callLogs: 1 outline + 1 other + 3 detail calls => 5
        assertEquals(5, result.callLogs().size());

        // no errors
        assertTrue(result.errors().isEmpty());
    }

    @Test
    void testFanOutCapped() {
        // stub outline → "A\nB\nC\nD"
        fake.whenContains("outline", "A\nB\nC\nD");

        Chain chain = ChainBuilder.start(defaults)
                .step("outline")
                .user("outline")
                .parse(Parsers.stringList())
                .label(ITEMS)
                .endStep()
                .step("other")
                .user("other")
                .parse(Parsers.string())
                .label(OTHER)
                .endStep()
                .forEach(ITEMS)
                .alias("item")
                .maxElements(2)
                .addStep(
                        StepBuilder
                                .start("detail", defaults)
                                .user("detail ${item}")
                                .parse(Parsers.string())
                                .label(DETAIL)
                                .build()
                )
                .joinInto(DETAILS)
                .endForEach()
                .build();

        ChainResult result = chain.run(fake);

        // only first two items processed
        assertTrue(result.has(DETAILS));
        List<String> details = result.get(DETAILS);
        assertEquals(List.of("detail-of-A", "detail-of-B"), details);

        // callLogs: 1 outline + 1 other + 1 truncation error + 2 detail calls = 5
        assertEquals(5, result.callLogs().size());

        // error recorded under DETAILS label
        assertTrue(result.hasError(DETAILS));
        ErrorInfo err = result.getError(DETAILS);
        assertTrue(err.cause() instanceof IllegalArgumentException);
        assertTrue(err.cause().getMessage().contains("Truncated"));
    }
}
