package com.playposse.learninglab.server.firebase_server;

/**
 * Request payload for generating a skill rubric for a course.
 * Contains information from the Course and CourseProfile.
 */
public class GenerateSkillRubricRequest {
    public String uid; // set by controller after verifying token
    public String title;
    public String description;
    public String topicAndFocus;
    public String scheduleAndDuration;
    public String targetAudience;
    public String groupSizeAndFormat;
    public String location;
    public String howStudentsJoin;
    public String toneAndApproach;
    public String anythingUnusual;
}
