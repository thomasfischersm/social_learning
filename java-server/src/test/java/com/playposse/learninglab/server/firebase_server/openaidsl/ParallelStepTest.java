// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ParallelStepTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.type.TypeReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ParallelStepTest {

    private ChatConfig defaults;
    private FakeOpenAiClient fake;

    // The join‐into label for the parallel map
    private static final Label<Map<String,Object>> PAR =
            Label.of("parallel", new TypeReference<Map<String,Object>>() {});

    @BeforeEach
    void setUp() {
        defaults = new DefaultsBuilder().build();
        fake     = new FakeOpenAiClient();
    }

    @Test
    void testExplicitJoin() {
        // Arrange: stub responses
        fake.whenContains("p1", "R1");
        fake.whenContains("p2", "R2");

        // Branch steps each label into PAR
        SimpleStep step1 = StepBuilder
                .start("b1", defaults)
                .user("p1")
                .parse(Parsers.string())
                .label(PAR)
                .build();

        SimpleStep step2 = StepBuilder
                .start("b2", defaults)
                .user("p2")
                .parse(Parsers.string())
                .label(PAR)
                .build();

        // Build and run the parallel-only chain
        Chain chain = ChainBuilder
                .start(defaults)
                .parallel()
                .branch("one", step1)
                .branch("two", step2)
                .joinInto(PAR)
                .endParallel()
                .build();

        ChainResult result = chain.run(fake);

        // Assert: the result map under PAR has both branch keys
        assertTrue(result.has(PAR), "Result should contain the parallel map");
        @SuppressWarnings("unchecked")
        Map<String,Object> map = (Map<String,Object>) result.get(PAR);
        assertEquals(2, map.size());
        assertEquals("R1", map.get("one"));
        assertEquals("R2", map.get("two"));

        // And exactly two calls were made
        List<CallLog> logs = result.callLogs();
        assertEquals(2, logs.size());
        // Prompts should match p1, p2 in any order
        List<String> prompts = logs.stream()
                .map(log -> log.prompt().stream()
                        .filter(m -> m.role() == Role.USER)
                        .reduce((a,b)->b)
                        .map(ChatMsg::content)
                        .orElse(""))
                .toList();
        assertTrue(prompts.contains("p1"));
        assertTrue(prompts.contains("p2"));
    }
}
