// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/ConfigOverridesTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class ConfigOverridesTest {

    private ChatConfig    defaults;
    private OpenAiClient  client;

    @BeforeEach
    void setup() throws Exception {
        // Build explicit defaults so we know what to expect
        defaults = new DefaultsBuilder()
                .model("base-model")
                .maxTokens(123)
                .build();

        // Mock the OpenAiClient to return a placeholder result
        client = mock(OpenAiClient.class);
        when(client.chatCompletion(anyList(), any()))
                .thenReturn(new ChatCompletionResult("unused", null));
    }

    @Test
    void testModelAndMaxTokensOverride() throws Exception {
        // Labels for each step
        Label<String> L0 = Label.of("step0", String.class);
        Label<String> L1 = Label.of("step1", String.class);

        // Build a two-step chain:
        //  • step0 uses defaults
        //  • step1 overrides model and maxTokens
        Chain chain = ChainBuilder.start(defaults)
                .step("step0")
                .user("p0")
                .parse(Parsers.string())
                .label(L0)
                .endStep()
                .step("step1")
                .user("p1")
                .model("override-model")
                .maxTokens(456)
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                .build();

        // Run it
        ChainResult result = chain.run(client);

        // Capture the ChatConfig for each call
        @SuppressWarnings("unchecked")
        ArgumentCaptor<ChatConfig> cfgCaptor =
                ArgumentCaptor.forClass(ChatConfig.class);

        // Expect exactly two invocations
        verify(client, times(2))
                .chatCompletion(anyList(), cfgCaptor.capture());

        List<ChatConfig> cfgs = cfgCaptor.getAllValues();

        // First call: defaults
        ChatConfig cfg0 = cfgs.get(0);
        assertEquals("base-model", cfg0.model(),      "Step0 should use default model");
        assertEquals(123,            cfg0.maxTokens(), "Step0 should use default maxTokens");

        // Second call: overridden values
        ChatConfig cfg1 = cfgs.get(1);
        assertEquals("override-model", cfg1.model(),      "Step1 should use overridden model");
        assertEquals(456,               cfg1.maxTokens(), "Step1 should use overridden maxTokens");

        // Confirm all other parameters remain the same as defaults
        assertEquals(defaults.temperature(),     cfg1.temperature(),     "temperature unchanged");
        assertEquals(defaults.topP(),           cfg1.topP(),           "topP unchanged");
        assertEquals(defaults.presencePenalty(), cfg1.presencePenalty(), "presencePenalty unchanged");
        assertEquals(defaults.frequencyPenalty(),cfg1.frequencyPenalty(),"frequencyPenalty unchanged");
    }
}
