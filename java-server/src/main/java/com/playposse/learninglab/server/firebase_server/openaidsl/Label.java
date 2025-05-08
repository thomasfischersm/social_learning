package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.lang.reflect.Type;
import java.util.Objects;
import com.fasterxml.jackson.core.type.TypeReference;

/**
 * Strongly-typed key for identifying and retrieving values in a ChainResult.
 *
 * @param <T> the type of the value associated with this label
 */
public final class Label<T> {
    private final String name;
    private final Type   type;

    private Label(String name, Type type) {
        this.name = name;
        this.type = type;
    }

    public String name() {
        return name;
    }

    public Type type() {
        return type;
    }

    public static <T> Label<T> of(String name, Class<T> clazz) {
        return new Label<>(name, clazz);
    }

    public static <T> Label<T> of(String name, TypeReference<T> typeRef) {
        return new Label<>(name, typeRef.getType());
    }

    @Override
    public String toString() {
        return "Label[name=" + name + ", type=" + type.getTypeName() + "]";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Label<?> that)) return false;
        return name.equals(that.name) && type.equals(that.type);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, type);
    }
}
