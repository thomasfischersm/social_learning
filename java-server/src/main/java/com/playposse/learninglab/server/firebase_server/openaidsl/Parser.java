package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Strategy for parsing a raw assistant response into a typed value.
 *
 * @param <T> The type returned by this parser.
 */
public interface Parser<T> {
    /**
     * Parses the raw assistant response (String) into a value of type T.
     *
     * @param input Raw completion text from the AI.
     * @return Parsed value of type T.
     * @throws Exception if parsing fails.
     */
    T parse(String input) throws Exception;
}

