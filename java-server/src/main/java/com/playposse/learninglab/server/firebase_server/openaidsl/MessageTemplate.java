package com.playposse.learninglab.server.firebase_server.openaidsl;

/**
 * A chat‐message template consisting of a role (SYSTEM, USER, or ASSISTANT)
 * and the raw content (possibly containing ${placeholders}).
 */
public record MessageTemplate(Role role, String content) {
    public MessageTemplate {
        if (role == null) {
            throw new IllegalArgumentException("role must not be null");
        }
        if (content == null) {
            throw new IllegalArgumentException("content must not be null");
        }
    }
}
