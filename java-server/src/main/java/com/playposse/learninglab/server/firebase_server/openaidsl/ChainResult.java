package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Immutable view of everything a Chain produced.
 */
public interface ChainResult {

    /* 1. Type-safe accessors */
    <T> T get(Label<T> label);
    <T> Optional<T> maybe(Label<T> label);
    boolean has(Label<?> label);

    /* 2. Stringly accessors */
    String            getString(String name);
    List<?>          getList(String name);
    JsonNode         getJson(String name);

    /* 3. Error inspection */
    boolean hasError(Label<?> label);
    ErrorInfo getError(Label<?> label);
    Map<Label<?>, ErrorInfo> errors();

    /* 4. Bulk / convenience */
    Map<Label<?>, Object> asMap();
    Map<String, Object>   asStringKeyMap();
    JsonNode              toJson();
    ChainResult           slice(Label<?>... labels);
    Set<Label<?>>         labels();
    List<CallLog> callLogs();

    /** Observer for streaming callbacks (optional). */
    interface Observer {
        void onLabel(Label<?> label, Object value);
        void onError(Label<?> label, ErrorInfo error);
    }
}
