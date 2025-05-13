package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.openai.models.ChatModel;

import java.util.Objects;

/**
 * Fluent builder for your chain’s global ChatConfig defaults.
 *
 * <p>By default, we pick model="o3" and maxTokens=5000 so you
 * get the headroom you sketched out earlier.</p>
 */
public final class DefaultsBuilder {
    private final ChatConfig.Builder cfg;

    public DefaultsBuilder() {
        // seed the two main defaults immediately:
        cfg = ChatConfig.builder()
                .model(ChatModel.CHATGPT_4O_LATEST)
                .maxTokens(5000);
        // The rest (temperature, topP, penalties, etc.) stay at ChatConfig.Builder's defaults
    }

    public DefaultsBuilder model(ChatModel m) {
        Objects.requireNonNull(m, "model");
        cfg.model(m);
        return this;
    }

    public DefaultsBuilder maxTokens(int t) {
        cfg.maxTokens(t);
        return this;
    }

    public DefaultsBuilder temperature(double v) {
        cfg.temperature(v);
        return this;
    }

    public DefaultsBuilder topP(double v) {
        cfg.topP(v);
        return this;
    }

    public DefaultsBuilder presencePenalty(double v) {
        cfg.presencePenalty(v);
        return this;
    }

    public DefaultsBuilder frequencyPenalty(double v) {
        cfg.frequencyPenalty(v);
        return this;
    }

    /** Build the immutable ChatConfig to pass into your Chain. */
    public ChatConfig build() {
        return cfg.build();
    }
}