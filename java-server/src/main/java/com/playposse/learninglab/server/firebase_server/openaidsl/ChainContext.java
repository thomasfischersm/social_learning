package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Immutable context passed from step to step in a Chain.
 * Contains labeled variables, branch-local message history, and config.
 */
public final class ChainContext {
    private final Map<Label<?>, Object> vars;
    private final List<ChatMsg> history;
    private final ChatConfig config;

    private ChainContext(
            Map<Label<?>, Object> vars,
            List<ChatMsg> history,
            ChatConfig config) {
        this.vars = vars;
        this.history = history;
        this.config = config;
    }

    /**
     * Creates the root context with initial config; empty vars and history.
     */
    public static ChainContext root(ChatConfig initialConfig) {
        return new ChainContext(
                new HashMap<>(),
                new ArrayList<>(),
                initialConfig
        );
    }

    /**
     * Retrieves a typed value by its label.
     * Throws if missing or wrong type.
     */
    @SuppressWarnings("unchecked")
    public <T> T get(Label<T> label) {
        Object raw = vars.get(label);
        if (raw == null) {
            throw new IllegalStateException("Missing value for label: " + label.name());
        }
        return (T) raw;
    }

    /**
     * Returns true if a non-error value exists for the label.
     */
    public boolean has(Label<?> label) {
        return vars.containsKey(label);
    }

    /**
     * Returns the current chat config for new steps.
     */
    public ChatConfig config() {
        return config;
    }

    /**
     * Returns an immutable copy of the message history.
     */
    public List<ChatMsg> history() {
        return List.copyOf(history);
    }

    /**
     * Returns an immutable copy of all labeled variables.
     */
    public Map<Label<?>, Object> vars() {
        return Map.copyOf(vars);
    }

    /* Internal mutation helpers (return new context) */

    ChainContext plus(Label<?> label, Object value) {
        var copy = new HashMap<>(vars);
        copy.put(label, value);
        return new ChainContext(copy, history, config);
    }

    ChainContext appendHistory(ChatMsg msg) {
        var copyHistory = new ArrayList<>(history);
        copyHistory.add(msg);
        return new ChainContext(vars, copyHistory, config);
    }

    ChainContext withConfig(ChatConfig newConfig) {
        return new ChainContext(vars, history, newConfig);
    }

    /**
     * Creates a forked copy for branching: clones vars and history.
     */
    ChainContext fork() {
        return new ChainContext(
                new HashMap<>(vars),
                new ArrayList<>(history),
                config
        );
    }
}
