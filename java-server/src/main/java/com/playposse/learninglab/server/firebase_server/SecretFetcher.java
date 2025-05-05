package com.playposse.learninglab.server.firebase_server;

import com.google.cloud.secretmanager.v1.*;
import com.google.protobuf.ByteString;
import org.springframework.stereotype.Component;

@Component
public class SecretFetcher {

    public String getOpenAiApiKey() throws Exception {
        try (SecretManagerServiceClient client = SecretManagerServiceClient.create()) {
            // Use your GCP project ID here or get from env
            String projectId = "social-learning-32741";

            SecretVersionName name = SecretVersionName.of(projectId, "OPENAI_API_KEY", "latest");
            AccessSecretVersionResponse response = client.accessSecretVersion(name);
            ByteString payload = response.getPayload().getData();
            return payload.toStringUtf8();
        }
    }
}
