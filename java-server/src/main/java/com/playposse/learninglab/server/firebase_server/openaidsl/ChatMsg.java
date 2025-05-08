package com.playposse.learninglab.server.firebase_server.openaidsl;

/**
 * A single chat message with a defined role (SYSTEM, USER, or ASSISTANT).
 *
 * @param role    the origin role of the message
 * @param content the textual content
 */
public record ChatMsg(Role role, String content) {}


