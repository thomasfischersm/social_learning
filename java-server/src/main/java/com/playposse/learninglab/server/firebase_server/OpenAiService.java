package com.playposse.learninglab.server.firebase_server;

import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.ChatModel;
import com.openai.models.chat.completions.ChatCompletion;
import com.openai.models.chat.completions.ChatCompletionCreateParams;
import com.openai.models.chat.completions.ChatCompletionUserMessageParam;
import com.openai.models.chat.completions.ChatCompletionSystemMessageParam;
import com.openai.models.chat.completions.ChatCompletionAssistantMessageParam;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class OpenAiService {

    private final OpenAIClient client;

    public OpenAiService(SecretFetcher secretFetcher) {
        String apiKey;
        try {
            apiKey = secretFetcher.getOpenAiApiKey();
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch OpenAI API key", e);
        }
        this.client = OpenAIOkHttpClient.builder()
                .apiKey(apiKey)
                .build();
    }

    /**
     * Single‐prompt helper.
     */
    public String askChatGPT(String prompt) {
        ChatCompletionCreateParams params = ChatCompletionCreateParams.builder()
                .addUserMessage(prompt)   // convenience for one user message :contentReference[oaicite:0]{index=0}
                .model(ChatModel.GPT_4_1)
                .build();

        ChatCompletion result = client.chat()
                .completions()
                .create(params);

        return result.choices()
                .get(0)
                .message()
                .content()
                .orElseThrow(() -> new RuntimeException("OpenAI returned empty content"));
    }

    /**
     * Multi‐role chat: accepts List<Map<role,content>>.
     */
    public String chat(List<Map<String, String>> messagesInput, double temperature) {
        ChatCompletionCreateParams.Builder b = ChatCompletionCreateParams.builder()
                .model(ChatModel.GPT_4)
                .temperature(temperature);

        for (Map<String, String> msg : messagesInput) {
            String role    = msg.get("role");
            String content = msg.get("content");
            switch (role) {
                case "system":
                    b.addMessage(             // generic addMessage(...) for any role :contentReference[oaicite:1]{index=1}
                            ChatCompletionSystemMessageParam.builder()
                                    .content(content)
                                    .build()
                    );
                    break;
                case "assistant":
                    b.addMessage(
                            ChatCompletionAssistantMessageParam.builder()
                                    .content(content)
                                    .build()
                    );
                    break;
                default: // "user"
                    b.addMessage(
                            ChatCompletionUserMessageParam.builder()
                                    .content(content)
                                    .build()
                    );
            }
        }

        ChatCompletion result = client.chat()
                .completions()
                .create(b.build());

        return result.choices()
                .get(0)
                .message()
                .content()
                .orElseThrow(() -> new RuntimeException("OpenAI returned empty content"));
    }
}
