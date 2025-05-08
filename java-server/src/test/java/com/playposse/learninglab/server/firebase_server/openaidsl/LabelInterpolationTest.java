// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/LabelInterpolationTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.Test;

class LabelInterpolationTest {

    private final ChatConfig defaults = new DefaultsBuilder().build();

    @Test
    void testLabelInterpolation() {
        // 1) Set up fake client: "initial" → "abc", "research: abc" → "ok"
        FakeOpenAiClient fake = new FakeOpenAiClient();
        fake.whenContains("initial", "abc");
        fake.whenContains("research: abc", "ok");

        // 2) Define two labels
        Label<String> A = Label.of("A", String.class);
        Label<String> B = Label.of("B", String.class);

        // 3) Build a two-step chain:
        //    Step A: prompt "initial" → label A
        //    Step B: prompt "research: ${A}" → label B
        Chain chain = ChainBuilder
                .start(defaults)

                .step("stepA")
                .user("initial")
                .parse(Parsers.string())
                .label(A)
                .endStep()

                .step("stepB")
                .user("research: ${A}")
                .parse(Parsers.string())
                .label(B)
                .endStep()

                .build();

        // 4) Run
        ChainResult result = chain.run(fake);

        // 5) Verify the values under each label
        assertEquals("abc", result.get(A), "Label A should hold the first reply");
        assertEquals("ok",  result.get(B), "Label B should hold the second reply");

        // 6) Verify the actual user prompts sent to the API
        List<String> prompts = result.callLogs().stream()
                .map(log -> log.prompt().stream()
                        .filter(m -> m.role() == Role.USER)
                        .reduce((first, second) -> second)
                        .map(ChatMsg::content)
                        .orElse(""))
                .toList();

        assertEquals(
                List.of("initial", "research: abc"),
                prompts,
                "Placeholders should be interpolated before the call"
        );
    }
}
