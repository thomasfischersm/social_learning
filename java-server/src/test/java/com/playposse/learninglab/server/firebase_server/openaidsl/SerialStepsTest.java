// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/SerialStepsTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class SerialStepsTest {

    private ChatConfig defaults;
    private FakeOpenAiClient fakeClient;

    @BeforeEach
    void setup() {
        defaults   = new DefaultsBuilder().build();
        fakeClient = new FakeOpenAiClient();
    }

    @Test
    void testSingleStep() {
        // Stub: when prompt "abc" is sent, reply "def"
        fakeClient.whenContains("abc", "def");

        Label<String> OUT = Label.of("step0", String.class);

        Chain chain = ChainBuilder
                .start(defaults)
                .step("step0")
                .user("abc")
                .parse(Parsers.string())
                .label(OUT)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);

        // Verify the result under the label
        assertTrue(result.has(OUT), "ChainResult should contain step0");
        assertEquals("def", result.get(OUT));

        // Verify exactly one call and the prompt was "abc"
        List<String> prompts = result.callLogs().stream()
                .map(log -> lastUserContent(log.prompt()))
                .toList();
        assertEquals(List.of("abc"), prompts);
    }

    @Test
    void testThreeSerialSteps() {
        // Stub: "a"→"A", "b"→"B", "c"→"C"
        fakeClient.whenContains("a", "A");
        fakeClient.whenContains("b", "B");
        fakeClient.whenContains("c", "C");

        ChainBuilder builder = ChainBuilder.start(defaults);

        Label<String> L0 = Label.of("step0", String.class);
        builder = builder
                .step("step0")
                .user("a")
                .parse(Parsers.string())
                .label(L0)
                .endStep();

        Label<String> L1 = Label.of("step1", String.class);
        builder = builder
                .step("step1")
                .user("b")
                .parse(Parsers.string())
                .label(L1)
                .endStep();

        Label<String> L2 = Label.of("step2", String.class);
        builder = builder
                .step("step2")
                .user("c")
                .parse(Parsers.string())
                .label(L2)
                .endStep();

        Chain chain = builder.build();
        ChainResult result = chain.run(fakeClient);

        // Verify each label maps correctly
        assertEquals("A", result.get(L0));
        assertEquals("B", result.get(L1));
        assertEquals("C", result.get(L2));

        // Verify prompts in order
        List<String> prompts = result.callLogs().stream()
                .map(log -> lastUserContent(log.prompt()))
                .toList();
        assertEquals(List.of("a", "b", "c"), prompts);
    }

    /** Helper to extract the last USER message content from a prompt. */
    private static String lastUserContent(List<ChatMsg> msgs) {
        return msgs.stream()
                .filter(m -> m.role() == Role.USER)
                .reduce((first, second) -> second)
                .map(ChatMsg::content)
                .orElse("");
    }
}
