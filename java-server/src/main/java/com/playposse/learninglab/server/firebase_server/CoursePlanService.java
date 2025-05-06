package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CoursePlanService {

    private final Firestore db;
    private final OpenAiService openAiService;

    public CoursePlanService(Firestore db, OpenAiService openAiService) {
        this.db = db;
        this.openAiService = openAiService;
    }

    public void generateCoursePlan(CoursePlanController.GenerateCoursePlanRequest request) throws Exception {
        try {
            String uid = request.uid;
            String coursePlanId = request.coursePlanId;

            DocumentReference coursePlanRef = db.document("coursePlans/" + coursePlanId);
            DocumentSnapshot coursePlanSnap = coursePlanRef.get().get();
            if (!coursePlanSnap.exists()) throw new RuntimeException("CoursePlan not found");

            Map<String, Object> coursePlan = coursePlanSnap.getData();
            DocumentReference courseRef = (DocumentReference) coursePlan.get("courseId");
            if (courseRef == null) throw new RuntimeException("Missing course reference");

            DocumentSnapshot courseSnap = courseRef.get().get();
            if (!courseSnap.exists()) throw new RuntimeException("Course not found");

            Map<String, Object> courseData = courseSnap.getData();
            if (!uid.equals(courseData.get("creatorId"))) {
                throw new RuntimeException("You are not the course creator");
            }

            String direction = (String) coursePlan.get("planJson");
            if (direction == null || direction.isBlank()) throw new RuntimeException("Missing or invalid planJson");

            List<String> openaiResponses = new ArrayList<>();

            // Step 1
            String inventoryText = openAiService.chat(List.of(
                    system("You are a curriculum designer identifying all teachable elements for a course."),
                    user("Course direction: " + direction + "\n\nList specific skills, concepts, drills, poses, or principles that might be taught. For each, mention prerequisites and a rough estimate of difficulty or readiness needed.")
            ), 0.7);
            openaiResponses.add(inventoryText);

            // Step 2
            String goalsText = openAiService.chat(List.of(
                    system("You are helping define goals and experience for a course."),
                    user(direction),
                    assistant(inventoryText),
                    user("Define inspiring yet realistic outcomes for this course based on the listed teachable content. Consider time limits (about 15 minutes per lesson. Each student learns a lesson and then teaches it. Thus a student can finish learning/teaching two lessons per hour.). Define the kind of student experience and emotional arc we want. Then suggest which goals to aim for.\n")
            ), 0.7);
            openaiResponses.add(goalsText);

            // Step 3
            String curriculumText = openAiService.chat(List.of(
                    system("You are designing a level-based curriculum for peer-teaching."),
                    user(direction),
                    assistant(inventoryText),
                    assistant(goalsText),
                    user("""
                            Organize the course into 2–4 levels. Each level should have 3–6 peer-teachable lessons. Each lesson must include:
                            - title
                            - synopsis
                            - instructions (as one string including bullets, summary, and common issues)
                            - 2–4 graduationRequirements
                            
                            Return this in formatted text (not JSON yet).
                            """)
            ), 0.6);
            openaiResponses.add(curriculumText);

            // Step 4
            String jsonText = openAiService.chat(List.of(
                    system("You are converting structured curriculum content into strict JSON."),
                    user(direction),
                    assistant(inventoryText),
                    assistant(goalsText),
                    assistant(curriculumText),
                    user("""
                            Now convert the curriculum to JSON.
                            
                            Each lesson must contain:
                            - title
                            - synopsis
                            - instructions (as a **single string**, including bullets, summary, and common issues)
                            - graduationRequirements (a list of 2–4 items)
                            
                            Return ONLY the following JSON structure:
                            {
                              "levels": [
                                {
                                  "title": "Level Title",
                                  "description": "Level Description",
                                  "lessons": [
                                    {
                                      "title": "Lesson Title",
                                      "synopsis": "Short summary of the lesson",
                                      "instructions": "All text as one string: bullets + explanation + common issues",
                                      "graduationRequirements": ["Requirement 1", "Requirement 2"]
                                    }
                                  ]
                                }
                              ]
                            }
                            """)
            ), 0.5);

            Map<?, ?> parsedJson;
            try {
                parsedJson = new ObjectMapper().readValue(jsonText, Map.class);
            } catch (Exception e) {
                System.err.println("Invalid JSON returned by GPT:");
                System.err.println(jsonText);
                e.printStackTrace();
                throw new RuntimeException("Invalid JSON returned by GPT", e);
            }

            // Write back to Firestore
            Map<String, Object> updates = new HashMap<>();
            updates.put("generatedJson", new ObjectMapper().writeValueAsString(parsedJson));
            updates.put("openaiResponses", String.join("\n\n---\n\n", openaiResponses));
            coursePlanRef.update(updates);
        } catch (Exception e) {
            System.err.println("Error in generateCoursePlan:");
            e.printStackTrace();
            throw e;
        }
    }

    private static Map<String, String> system(String text) {
        return Map.of("role", "system", "content", text);
    }

    private static Map<String, String> user(String text) {
        return Map.of("role", "user", "content", text);
    }

    private static Map<String, String> assistant(String text) {
        return Map.of("role", "assistant", "content", text);
    }
}
