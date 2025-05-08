// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ChainHelperTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

/**
 * Exercises one‐step and multi‐step serial Chains using a reusable TestHelper.
 */
class SingleStepTest {

    private final ChatConfig defaults = new DefaultsBuilder().build();
    private final TestHelper helper   = new TestHelper(defaults);

    @Test
    void testSingleStep() {
        helper.addMapping("abc", "def");
        ChainResult result = helper.runSteps(List.of("abc"));

        // check the single label "step0" → "def"
        helper.verifyClientCalled(1);
        helper.assertResults(result, List.of("def"));

        // ensure the prompt sent was exactly "abc"
        List<String> prompts = helper.capturedPrompts();
        assertEquals(List.of("abc"), prompts);
    }

    @Test
    void testThreeSerialSteps() {
        // prepare mappings
        helper.addMapping("a", "A!");
        helper.addMapping("b", "B!");
        helper.addMapping("c", "C!");

        ChainResult result = helper.runSteps(List.of("a", "b", "c"));

        // 3 calls, labels step0→"A!", step1→"B!", step2→"C!"
        helper.verifyClientCalled(3);
        helper.assertResults(result, List.of("A!", "B!", "C!"));

        // capture and assert the exact prompts in order
        List<String> prompts = helper.capturedPrompts();
        assertEquals(List.of("a","b","c"), prompts);
    }

    /**
     * Helper to build 1‒N step chains, stub the client, run them, and verify.
     */
    private static class TestHelper {

        private final ChatConfig           defaults;
        private final OpenAiClient         client;
        private final Map<String,String>   mapping = new HashMap<>();
        private final ArgumentCaptor<List<ChatMsg>> captor =
                ArgumentCaptor.forClass((Class) List.class);

        TestHelper(ChatConfig defaults) {
            this.defaults = defaults;
            this.client   = mock(OpenAiClient.class);

            // stub chatCompletion to look up the last USER prompt in our mapping
            try {
                when(client.chatCompletion(anyList(), any()))
                        .thenAnswer(invocation -> {
                            @SuppressWarnings("unchecked")
                            List<ChatMsg> msgs =
                                    (List<ChatMsg>) invocation.getArgument(0);
                            // find the last USER message
                            String prompt = msgs.stream()
                                    .filter(m -> m.role() == Role.USER)
                                    .reduce((first, second) -> second)
                                    .map(ChatMsg::content)
                                    .orElse("");
                            String out = mapping.get(prompt);
                            if (out == null) {
                                throw new IllegalStateException(
                                        "No mapping for prompt: " + prompt);
                            }
                            return new ChatCompletionResult(out, null);
                        });
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }

        /** Declare that input → expectedOutput. */
        void addMapping(String input, String expectedOutput) {
            mapping.put(input, expectedOutput);
        }

        /**
         * Builds a chain of N steps, each named "step0"…"stepN-1", each with
         * exactly one user prompt from `inputs`, parsed as a raw String,
         * labeled `Label.of("step{i}", String.class)`, and runs it.
         */
        ChainResult runSteps(List<String> inputs) {
            ChainBuilder cb = ChainBuilder.start(defaults);
            for (int i = 0; i < inputs.size(); i++) {
                String name = "step" + i;
                Label<String> lbl = Label.of(name, String.class);
                cb = cb.step(name)
                        .user(inputs.get(i))
                        .parse(Parsers.string())
                        .label(lbl)
                        .endStep();
            }
            Chain chain = cb.build();
            return chain.run(client);
        }

        /** Verify chatCompletion was called exactly `times` times. */
        void verifyClientCalled(int times) {
            try {
                verify(client, times(times))
                        .chatCompletion(captor.capture(), any());
            } catch (Exception e) {
                throw new AssertionError("Error verifying chatCompletion calls", e);
            }
        }

        /** Extract exactly the USER prompt from each call, in order. */
        List<String> capturedPrompts() {
            List<String> out = new ArrayList<>();
            for (List<ChatMsg> msgs : captor.getAllValues()) {
                String prompt = msgs.stream()
                        .filter(m -> m.role() == Role.USER)
                        .reduce((f, s) -> s)
                        .map(ChatMsg::content)
                        .orElse("");
                out.add(prompt);
            }
            return out;
        }

        /** Assert that each step{i} label returns the expectedOutputs[i]. */
        void assertResults(ChainResult result, List<String> expectedOutputs) {
            for (int i = 0; i < expectedOutputs.size(); i++) {
                Label<String> lbl = Label.of("step" + i, String.class);
                assertTrue(result.has(lbl), "Missing label: " + lbl.name());
                assertEquals(
                        expectedOutputs.get(i),
                        result.get(lbl),
                        "Value for " + lbl.name());
            }
        }
    }
}
