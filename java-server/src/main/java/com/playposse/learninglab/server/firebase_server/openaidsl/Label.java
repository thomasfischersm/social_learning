package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.lang.reflect.Type;
import com.fasterxml.jackson.core.type.TypeReference;

/**
 * Strongly‑typed key for identifying and retrieving values in a ChainResult.
 *
 * @param <T> the type of the value associated with this label
 */
public final class Label<T> {
    private final String name;
    private final Type type;

    private Label(String name, Type type) {
        this.name = name;
        this.type = type;
    }

    /**
     * Returns the unique name of this label.
     */
    public String name() {
        return name;
    }

    /**
     * Returns the Java type token of this label's value.
     */
    public Type type() {
        return type;
    }

    /**
     * Creates a label for a simple (non‑generic) class type.
     */
    public static <T> Label<T> of(String name, Class<T> clazz) {
        return new Label<>(name, clazz);
    }

    /**
     * Creates a label for a generic type (e.g., List<String>) using Jackson's TypeReference.
     */
    public static <T> Label<T> of(String name, TypeReference<T> typeRef) {
        return new Label<>(name, typeRef.getType());
    }

    @Override
    public String toString() {
        return "Label[name=" + name + ", type=" + type.getTypeName() + "]";
    }
}