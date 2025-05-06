package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.Map;

@Service
public class OpenAiService {

    private static final Logger log = LoggerFactory.getLogger(OpenAiService.class);

    private final SecretFetcher secretFetcher;
    private final OkHttpClient client;
    private final ObjectMapper mapper = new ObjectMapper();

    public OpenAiService(SecretFetcher secretFetcher) {
        this.secretFetcher = secretFetcher;
        this.client = new OkHttpClient.Builder()
                .connectTimeout(Duration.ofSeconds(30))
                .readTimeout(Duration.ofMinutes(5))
                .writeTimeout(Duration.ofMinutes(2))
                .build();
    }

    public String askChatGPT(String prompt) throws Exception {
        String apiKey = secretFetcher.getOpenAiApiKey();

        String jsonBody = String.format("""
                {
                  "model": "gpt-4.1",
                  "messages": [
                    {"role": "user", "content": "%s"}
                  ]
                }
                """, prompt);

        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json"));

        Request request = new Request.Builder()
                .url("https://api.openai.com/v1/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "(empty)";
            log.debug("OpenAI request payload (askChatGPT): {}", jsonBody);
            log.debug("OpenAI raw response (askChatGPT): {}", responseBody);

            if (!response.isSuccessful()) {
                log.error("OpenAI error (askChatGPT): HTTP {} - {}", response.code(), responseBody);
                throw new IOException("Unexpected code " + response.code());
            }

            JsonNode root = mapper.readTree(responseBody);
            String content = root.path("choices").get(0).path("message").path("content").asText();
            log.debug("OpenAI parsed content (askChatGPT): {}", content);
            return content;
        }
    }

    public String chat(List<Map<String, String>> messages, double temperature) {
        try {
            String apiKey = secretFetcher.getOpenAiApiKey();

            String jsonBody = mapper.writeValueAsString(Map.of(
                    "model", "gpt-4",
                    "messages", messages,
                    "temperature", temperature
            ));

            RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json"));

            Request request = new Request.Builder()
                    .url("https://api.openai.com/v1/chat/completions")
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .post(body)
                    .build();

            log.debug("OpenAI request payload (chat): {}", jsonBody);

            try (Response response = client.newCall(request).execute()) {
                String responseBody = response.body() != null ? response.body().string() : "(empty)";
                log.debug("OpenAI raw response (chat): {}", responseBody);

                if (!response.isSuccessful()) {
                    log.error("OpenAI error (chat): HTTP {} - {}", response.code(), responseBody);
                    throw new IOException("OpenAI call failed with code " + response.code());
                }

                JsonNode root = mapper.readTree(responseBody);
                String content = root.path("choices").get(0).path("message").path("content").asText();
                log.debug("OpenAI parsed content (chat): {}", content);
                return content;
            }

        } catch (Exception e) {
            log.error("Exception during OpenAI call (chat): {}", e.getMessage(), e);
            throw new RuntimeException("OpenAI call failed", e);
        }
    }
}
