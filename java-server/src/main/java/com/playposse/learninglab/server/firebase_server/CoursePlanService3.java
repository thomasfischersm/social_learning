package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.openai.models.ChatModel;
import com.playposse.learninglab.server.firebase_server.openaidsl.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CoursePlanService3 {

    private final Firestore      db;
    private final OpenAiService  openAiService;
    private final OpenAiClient   openAiClient;
    private final ChatConfig     defaults;

    // our four labels for the chain
    private static final Label<String>      INVENTORY   = Label.of("inventory", String.class);
    private static final Label<String>      GOALS       = Label.of("goals", String.class);
    private static final Label<String>      CURRICULUM  = Label.of("curriculum", String.class);
    private static final Label<String>      JSON_TEXT   = Label.of("jsonText",  String.class);

    @Autowired
    public CoursePlanService3(Firestore db, OpenAiService openAiService) {
        this.db            = db;
        this.openAiService = openAiService;
        // wrap the existing OpenAiService in our OpenAiClient interface
        this.openAiClient  = new OpenAiServiceAdapter(openAiService);
        // pick whatever global defaults you like; you can override per‐step below
        this.defaults      = new DefaultsBuilder().build();
    }

    public void generateCoursePlan(GenerateCoursePlanRequest request) throws Exception {
        String uid          = request.uid;
        String coursePlanId = request.coursePlanId;

        // fetch and validate Firestore
        DocumentReference coursePlanRef = db.document("coursePlans/" + coursePlanId);
        DocumentSnapshot coursePlanSnap = coursePlanRef.get().get();
        if (!coursePlanSnap.exists()) {
            throw new RuntimeException("CoursePlan not found");
        }
        Map<String, Object> coursePlan = coursePlanSnap.getData();
        String direction = (String) coursePlan.get("planJson");
        if (direction == null || direction.isBlank()) {
            throw new RuntimeException("Missing or invalid planJson");
        }

        // build and run the OpenAI‐DSL chain
        ChainResult result = ChainBuilder
                .start(defaults)

                // Step 1: inventory
                .step("inventory")
                .system("You are a curriculum designer identifying all teachable elements for a course.")
                .user("Course direction: " + direction +
                        "\n\nList specific skills, concepts, drills, poses, or principles that might be taught. " +
                        "For each, mention prerequisites and a rough estimate of difficulty or readiness needed.")
                .parse(Parsers.string())
                .label(INVENTORY)
                .endStep()

                // Step 2: goals
                .step("goals")
                .system("You are helping define goals and experience for a course.")
                .user(direction)
                .assistant("${inventory}")
                .user("Define inspiring yet realistic outcomes for this course based on the listed teachable content. " +
                        "Consider time limits (about 15 minutes per lesson. Each student learns a lesson and then teaches it. " +
                        "Thus a student can finish learning/teaching two lessons per hour.). " +
                        "Define the kind of student experience and emotional arc we want. Then suggest which goals to aim for.")
                .parse(Parsers.string())
                .label(GOALS)
                .endStep()

                // Step 3: curriculum design
                .step("curriculum")
                .system("You are designing a level-based curriculum for peer-teaching.")
                .user(direction)
                .assistant("${inventory}")
                .assistant("${goals}")
                .user("""
                      Organize the course into 2–4 levels. Each level should have 3–6 peer-teachable lessons. Each lesson must include:
                      - title
                      - synopsis
                      - instructions (as one string including bullets, summary, and common issues)
                      - 2–4 graduationRequirements

                      Return this in formatted text (not JSON yet).
                      """)
                .parse(Parsers.string())
                .label(CURRICULUM)
                .endStep()

                // Step 4: JSON conversion
                .step("toJson")
                .system("You are converting structured curriculum content into strict JSON.")
                .user(direction)
                .assistant("${inventory}")
                .assistant("${goals}")
                .assistant("${curriculum}")
                .user("""
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
                .parse(Parsers.string())
                .label(JSON_TEXT)
                .endStep()

                .build()
                .run(openAiClient);

        // pull out the four pieces
        String inventory   = result.get(INVENTORY);
        String goals       = result.get(GOALS);
        String curriculum  = result.get(CURRICULUM);
        String jsonText    = result.get(JSON_TEXT);

        // parse JSON into a Map and write back
        Map<?,?> parsedJson;
        try {
            parsedJson = new ObjectMapper().readValue(jsonText, Map.class);
        } catch (Exception e) {
            System.err.println("Invalid JSON returned by GPT:");
            System.err.println(jsonText);
            throw new RuntimeException("Invalid JSON returned by GPT", e);
        }

        Map<String,Object> updates = new HashMap<>();
        updates.put("generatedJson", new ObjectMapper().writeValueAsString(parsedJson));
        updates.put("openaiResponses", String.join(
                "\n\n---\n\n",
                inventory, goals, curriculum, jsonText
        ));
        updates.put("lastGenerated", FieldValue.serverTimestamp());

        coursePlanRef.update(updates);
    }

    /**
     * Adapter so we can pass your existing OpenAiService into our DSL.
     */
    private static class OpenAiServiceAdapter implements OpenAiClient {
        private final OpenAiService svc;
        OpenAiServiceAdapter(OpenAiService svc) {
            this.svc = svc;
        }
        @Override
        public ChatCompletionResult chatCompletion(
                List<ChatMsg> messages,
                ChatConfig    config
        ) throws Exception {
            // convert our DSL ChatMsg → the Map<String,String> your service expects
            List<Map<String,String>> sdkMsgs = messages.stream()
                    .map(m -> Map.of("role", m.role().name().toLowerCase(),
                            "content", m.content()))
                    .toList();
            // delegate; ignore usage (null)
            String text = svc.chat(sdkMsgs, ChatModel.CHATGPT_4O_LATEST, config.temperature(), 5000);
            return new ChatCompletionResult(text, null, 0);
        }
    }
}
