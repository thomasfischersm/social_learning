package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.List;

/**
 * Immutable set of parameters for one chat-completion call.
 */
public record ChatConfig(
        String model,
        int maxTokens,
        double temperature,
        double topP,
        double presencePenalty,
        double frequencyPenalty,
        List<FunctionSchema> functions      // optional: for function-calling
) {
    /**
     * Start a fresh builder with no overrides.
     */
    public static Builder builder() {
        return new Builder();
    }

    /**
     * Begin a builder pre-populated from this config.
     */
    public Builder toBuilder() {
        return new Builder(this);
    }

    /**
     * Fluent builder for ChatConfig.
     */
    public static class Builder {
        private String model = "gpt-4o";
        private int maxTokens = 2_048;
        private double temperature = 1.0;
        private double topP = 1.0;
        private double presencePenalty = 0.0;
        private double frequencyPenalty = 0.0;
        private List<FunctionSchema> functions = List.of();

        public Builder() {
        }

        private Builder(ChatConfig cfg) {
            this.model = cfg.model();
            this.maxTokens = cfg.maxTokens();
            this.temperature = cfg.temperature();
            this.topP = cfg.topP();
            this.presencePenalty = cfg.presencePenalty();
            this.frequencyPenalty = cfg.frequencyPenalty();
            this.functions = cfg.functions();
        }

        public Builder model(String m) {
            this.model = m;
            return this;
        }

        public Builder maxTokens(int t) {
            this.maxTokens = t;
            return this;
        }

        public Builder temperature(double v) {
            this.temperature = v;
            return this;
        }

        public Builder topP(double v) {
            this.topP = v;
            return this;
        }

        public Builder presencePenalty(double v) {
            this.presencePenalty = v;
            return this;
        }

        public Builder frequencyPenalty(double v) {
            this.frequencyPenalty = v;
            return this;
        }

        public Builder functions(List<FunctionSchema> fs) {
            this.functions = List.copyOf(fs);
            return this;
        }

        /**
         * Build the immutable ChatConfig instance.
         */
        public ChatConfig build() {
            return new ChatConfig(
                    model,
                    maxTokens,
                    temperature,
                    topP,
                    presencePenalty,
                    frequencyPenalty,
                    functions
            );
        }
    }
}