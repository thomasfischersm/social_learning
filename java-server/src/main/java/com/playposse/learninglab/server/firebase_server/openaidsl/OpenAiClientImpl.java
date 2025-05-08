package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.ChatModel;
import com.openai.models.chat.completions.ChatCompletion;
import com.openai.models.chat.completions.ChatCompletionCreateParams;

import java.util.List;

/**
 * Adapter from our ChatMsg/ChatConfig DSL into the official OpenAI Java SDK.
 */
public class OpenAiClientImpl implements OpenAiClient {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private final OpenAIClient sdk;

    public OpenAiClientImpl(String apiKey) {
        // Build a thread-safe client from your key :contentReference[oaicite:0]{index=0}
        this.sdk = OpenAIOkHttpClient.builder()
                .apiKey(apiKey)
                .build();
    }

    @Override
    public ChatCompletionResult chatCompletion(
            List<ChatMsg> messages,
            ChatConfig    config
    ) throws Exception {
        // 1) Start the builder with model & sampling params :contentReference[oaicite:1]{index=1}
        var builder = ChatCompletionCreateParams.builder()
                .model(ChatModel.of(config.model().toUpperCase().replace('-', '_')))
                .maxTokens(config.maxTokens())
                .temperature(config.temperature())
                .topP(config.topP())
                .presencePenalty(config.presencePenalty())
                .frequencyPenalty(config.frequencyPenalty());

        // 2) Inject our SYSTEM/USER messages into the SDK builder
        for (ChatMsg msg : messages) {
            switch (msg.role()) {
                case SYSTEM:
                    builder.addSystemMessage(msg.content());
                    break;
                case USER:
                    builder.addUserMessage(msg.content());
                    break;
                case ASSISTANT:
                    // NOTE: v1.6.0 does not yet expose addAssistantMessage(...)
                    // If you need to replay assistant messages in history, you'll
                    // have to use the generic messages(List<...>) call with the
                    // ChatCompletionMessageParam union types.
                    break;
            }
        }

        // 3) Build & send
        ChatCompletionCreateParams params = builder.build();
        ChatCompletion response = sdk
                .chat()
                .completions()
                .create(params);

        // 4) Extract the single reply (content() returns Optional<String>)
        String text = response
                .choices()
                .get(0)
                .message()
                .content()
                .orElse("");

        // 5) (Optional) parse usage once you locate the right type; leave null for now
        JsonNode usageJson = null;

        return new ChatCompletionResult(text, usageJson);
    }
}