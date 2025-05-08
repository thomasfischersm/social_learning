package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Collection of common Parser implementations.
 */
public final class Parsers {
    private Parsers() {
        // static utility
    }

    /**
     * Parser that returns the raw string unchanged.
     */
    public static Parser<String> string() {
        return input -> input;
    }

    /**
     * Parser that splits the input on newlines into a List<String>.
     * Filters out blank lines and trims whitespace.
     */
    public static Parser<List<String>> stringList() {
        return input -> Arrays.stream(input.split("\\r?\\n"))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    public static Parser<JsonNode> json() {
        return input -> new ObjectMapper().readTree(input);
    }
}
