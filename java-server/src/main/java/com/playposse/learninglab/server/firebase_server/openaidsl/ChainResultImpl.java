package com.playposse.learninglab.server.firebase_server.openaidsl;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.*;

/**
 * Implementation of ChainResult that carries:
 *  - all labeled values,
 *  - per-label errors,
 *  - a full chronological callLog.
 */
public final class ChainResultImpl implements ChainResult {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final Map<Label<?>, Object> vars;
    private final Map<Label<?>, ErrorInfo> errors;
    private final List<CallLog> callLogs;

    /**
     * Constructor used internally by Chain. Builds error map from the call logs.
     */
    public ChainResultImpl(
            Map<Label<?>, Object> vars,
            List<CallLog> callLogs
    ) {
        this.vars     = Map.copyOf(vars);
        this.callLogs = List.copyOf(callLogs);

        // Build an errors map from any callLog entries that carry an ErrorInfo
        Map<Label<?>, ErrorInfo> errMap = new LinkedHashMap<>();
        for (CallLog logEntry : callLogs) {
            ErrorInfo e = logEntry.error();
            if (e != null) {
                errMap.put(logEntry.label(), e);
            }
        }
        this.errors = Collections.unmodifiableMap(errMap);
    }

    @Override @SuppressWarnings("unchecked")
    public <T> T get(Label<T> label) {
        if (!vars.containsKey(label)) {
            throw new IllegalStateException("No value for label: " + label.name());
        }
        return (T) vars.get(label);
    }

    @Override @SuppressWarnings("unchecked")
    public <T> Optional<T> maybe(Label<T> label) {
        return Optional.ofNullable((T) vars.get(label));
    }

    @Override
    public boolean has(Label<?> label) {
        return vars.containsKey(label);
    }

    @Override
    public String getString(String name) {
        Object v = asStringKeyMap().get(name);
        return (v instanceof String) ? (String) v : null;
    }

    @Override @SuppressWarnings("unchecked")
    public List<?> getList(String name) {
        Object v = asStringKeyMap().get(name);
        return (v instanceof List) ? (List<Object>) v : null;
    }

    @Override
    public JsonNode getJson(String name) {
        Object v = asStringKeyMap().get(name);
        return MAPPER.valueToTree(v);
    }

    @Override
    public boolean hasError(Label<?> label) {
        return errors.containsKey(label);
    }

    @Override
    public ErrorInfo getError(Label<?> label) {
        if (!errors.containsKey(label)) {
            throw new IllegalStateException("No error recorded for label: " + label.name());
        }
        return errors.get(label);
    }

    @Override
    public Map<Label<?>, ErrorInfo> errors() {
        return errors;
    }

    @Override
    public Map<Label<?>, Object> asMap() {
        return vars;
    }

    @Override
    public Map<String, Object> asStringKeyMap() {
        Map<String, Object> map = new LinkedHashMap<>();
        for (var entry : vars.entrySet()) {
            map.put(entry.getKey().name(), entry.getValue());
        }
        return Collections.unmodifiableMap(map);
    }

    @Override
    public JsonNode toJson() {
        return MAPPER.valueToTree(asStringKeyMap());
    }

    @Override
    public ChainResult slice(Label<?>... labels) {
        // filter vars
        Map<Label<?>, Object> subVars = new LinkedHashMap<>();
        for (Label<?> lbl : labels) {
            if (vars.containsKey(lbl)) {
                subVars.put(lbl, vars.get(lbl));
            }
        }
        // filter errors
        List<CallLog> subLogs = new ArrayList<>();
        for (CallLog log : callLogs) {
            if (subVars.containsKey(log.label())) {
                subLogs.add(log);
            }
        }
        return new ChainResultImpl(subVars, subLogs);
    }

    @Override
    public Set<Label<?>> labels() {
        return Collections.unmodifiableSet(vars.keySet());
    }

    @Override
    public List<CallLog> callLogs() {
        return callLogs;
    }
}