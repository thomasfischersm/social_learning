package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.openai.models.ChatModel;

import java.util.ArrayList;
import java.util.List;

/**
 * Builder for a single chat‐completion step in a Chain.
 */
public class StepBuilder {

    private final String stepName;
    private final ChatConfig baseConfig;

    private final List<MessageTemplate> templates = new ArrayList<>();
    private Parser<?> parser;
    private Label<?> label;

    // Lazy‐inited per‐step overrides
    private ChatConfig.Builder overrideCfg;

    // History flags
    private boolean includeHistory = false;
    private int   historyPairs   = Integer.MAX_VALUE;

    StepBuilder(String stepName, ChatConfig baseConfig) {
        this.stepName = stepName;
        this.baseConfig = baseConfig;
    }

    /** Add a system message. */
    public StepBuilder system(String msg) {
        templates.add(new MessageTemplate(Role.SYSTEM, msg));
        return this;
    }

    /** Add a user message. */
    public StepBuilder user(String msg) {
        templates.add(new MessageTemplate(Role.USER, msg));
        return this;
    }

    /** Add an assistant message. */
    public StepBuilder assistant(String msg) {
        templates.add(new MessageTemplate(Role.ASSISTANT, msg));
        return this;
    }

    /** Inject the full chat history (all pairs). */
    public StepBuilder history() {
        this.includeHistory = true;
        this.historyPairs   = Integer.MAX_VALUE;
        return this;
    }

    /** Inject only the last N user+assistant pairs. */
    public StepBuilder history(int pairs) {
        this.includeHistory = true;
        this.historyPairs   = pairs;
        return this;
    }

    /** How to parse the raw assistant reply. */
    public StepBuilder parse(Parser<?> parser) {
        this.parser = parser;
        return this;
    }

    /** Label this step’s output under a typed key. */
    public <T> StepBuilder label(Label<T> label) {
        this.label = label;
        return this;
    }

    /** Override the model for this step. */
    public StepBuilder model(ChatModel model) {
        ensureOverrideCfg().model(model);
        return this;
    }

    /** Override max-tokens for this step. */
    public StepBuilder maxTokens(int max) {
        ensureOverrideCfg().maxTokens(max);
        return this;
    }

    /** Override temperature for this step. */
    public StepBuilder temperature(double t) {
        ensureOverrideCfg().temperature(t);
        return this;
    }

    /** Adjust the nucleus sampling parameter for this step. */
    public StepBuilder topP(double topP) {
        ensureOverrideCfg().topP(topP);
        return this;
    }

    /** Encourage or discourage new tokens that appear often. */
    public StepBuilder frequencyPenalty(double freqPenalty) {
        ensureOverrideCfg().frequencyPenalty(freqPenalty);
        return this;
    }

    /** Encourage or discourage new tokens that haven’t appeared yet. */
    public StepBuilder presencePenalty(double presPenalty) {
        ensureOverrideCfg().presencePenalty(presPenalty);
        return this;
    }
    // … add topP(), presencePenalty(), frequencyPenalty() the same way …

    /*—————— internal ——————*/

    private ChatConfig.Builder ensureOverrideCfg() {
        if (overrideCfg == null) {
            overrideCfg = baseConfig.toBuilder();
        }
        return overrideCfg;
    }

    /** Build the immutable SimpleStep instance. */
    public SimpleStep build() {
        ChatConfig cfg = overrideCfg != null
                ? overrideCfg.build()
                : baseConfig;

        return new SimpleStep(
                stepName,
                List.copyOf(templates),
                parser,
                label,
                cfg,
                includeHistory,
                historyPairs
        );
    }

    public static StepBuilder start(String stepName, ChatConfig defaults) {
        return new StepBuilder(stepName, defaults);
    }
}