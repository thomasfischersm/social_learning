package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class OpenAiService {

    private final SecretFetcher secretFetcher;
    private final OkHttpClient client = new OkHttpClient();

    public OpenAiService(SecretFetcher secretFetcher) {
        this.secretFetcher = secretFetcher;
    }

    public String askChatGPT(String prompt) throws Exception {
        String apiKey = secretFetcher.getOpenAiApiKey();

        RequestBody body = RequestBody.create("""
                {
                  "model": "gpt-3.5-turbo",
                  "messages": [
                    {"role": "user", "content": "%s"}
                  ]
                }
                """.formatted(prompt), MediaType.parse("application/json"));

        Request request = new Request.Builder()
                .url("https://api.openai.com/v1/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

            // Parse JSON to extract message
            String json = response.body().string();
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(json);
            return root
                    .path("choices")
                    .get(0)
                    .path("message")
                    .path("content")
                    .asText();
        }
    }
}

