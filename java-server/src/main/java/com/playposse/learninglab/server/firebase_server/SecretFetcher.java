package com.playposse.learninglab.server.firebase_server;

import com.google.cloud.secretmanager.v1.AccessSecretVersionResponse;
import com.google.cloud.secretmanager.v1.SecretManagerServiceClient;
import com.google.cloud.secretmanager.v1.SecretVersionName;
import com.google.protobuf.ByteString;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Reads the OpenAI API key from Google Cloud Secret Manager the first
 * time it is requested, then serves the cached value for all subsequent
 * calls.  No client or channel is kept open after the first fetch.
 */
@Component
public class SecretFetcher {

    /** Defaults to the current GCP project; override via env or Spring property. */
    private final String projectId;

    /** Cached after first successful read. */
    private volatile String cachedKey;

    public SecretFetcher(
            @Value("${gcp.project-id:social-learning-32741}") String projectId) {
        this.projectId = projectId;
    }

    /** Returns the OpenAI API key, loading it once from Secret Manager. */
    public String getOpenAiApiKey() {
        // Fast path – already cached
        String key = cachedKey;
        if (key != null) return key;

        // Slow path – fetch, synchronised to prevent duplicate RPCs
        synchronized (this) {
            if (cachedKey == null) {
                cachedKey = fetchKeyFromSecretManager();
            }
            return cachedKey;
        }
    }

    /* ------------------------------------------------------------------ */
    /* Internal: one‑shot fetch and client close                           */
    /* ------------------------------------------------------------------ */

    private String fetchKeyFromSecretManager() {
        SecretVersionName name =
                SecretVersionName.of(projectId, "OPENAI_API_KEY", "latest");

        try (SecretManagerServiceClient sm = SecretManagerServiceClient.create()) {
            AccessSecretVersionResponse resp = sm.accessSecretVersion(name);
            ByteString data = resp.getPayload().getData();
            return data.toStringUtf8();
        } catch (Exception e) {
            throw new IllegalStateException(
                    "Unable to read secret OPENAI_API_KEY in project " + projectId, e);
        }
    }
}
