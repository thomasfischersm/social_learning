package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.time.Instant;

/**
 * Immutable payload capturing an error during a step execution.
 *
 * @param stepName   human-readable name of the step that failed
 * @param callId     OpenAI X-Request-Id or similar identifier
 * @param cause      the exception thrown
 * @param timestamp  when the error occurred
 */
public record ErrorInfo(
        String stepName,
        String callId,
        Throwable cause,
        Instant timestamp
) {}
