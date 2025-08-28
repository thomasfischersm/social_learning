package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.JsonNode;
import com.playposse.learninglab.server.firebase_server.openaidsl.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service that calls OpenAI to generate skill dimensions and degrees
 * for a course's skill rubric. It does not read or write Firestore
 * and simply returns the generated structure.
 */
@Service
public class SkillRubricService {

    private final OpenAiClient openAiClient;
    private final ChatConfig defaults;

    @Autowired
    public SkillRubricService(SecretFetcher secretFetcher) {
        String apiKey;
        try {
            apiKey = secretFetcher.getOpenAiApiKey();
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch OpenAI API key", e);
        }

        this.openAiClient = new OpenAiClientImpl(apiKey);
        this.defaults = new DefaultsBuilder()
                .temperature(0.7)
                .maxTokens(3000)
                .build();
    }

    /**
     * Generates skill dimensions, descriptions and degrees by
     * chaining OpenAI calls. The description of a dimension is fed
     * into the follow-up request for the degrees so that each branch
     * can proceed independently.
     */
    public SkillRubricResponse generateRubric(GenerateSkillRubricRequest request) throws Exception {
        String info = buildInfo(request);

        // labels
        Label<List<String>> DIMENSIONS = Label.of("dimensions", new com.fasterxml.jackson.core.type.TypeReference<>() {});
        Label<Object> DETAIL = Label.of("detail", Object.class); // reused for description and degree JSON
        Label<List<JsonNode>> DETAILS = Label.of("details", new com.fasterxml.jackson.core.type.TypeReference<>() {});

        String systemMessage =
                "You are an expert educator designing skill rubrics. A skill dimension is a major competency " +
                        "area for the course. Each dimension has five skill degrees from novice to expert, each with " +
                        "criteria and exercises.";

        ChainResult result = ChainBuilder
                .start(defaults)

                // Step 1: brainstorm dimensions
                .step("dimensions")
                .system(systemMessage)
                .user(info + "\n\nList the key skill dimensions for this course. Return one per line.")
                .parse(Parsers.stringList())
                .label(DIMENSIONS)
                .endStep()

                // Step 2 & 3: for each dimension, first get a description, then degrees
                .forEach(DIMENSIONS)
                .alias("dimension")
                .addStep(
                        StepBuilder.start("dimensionDescription", defaults)
                                .system(systemMessage)
                                .user(info + "\n\nDimension: ${dimension}\nDescribe this skill dimension in 2-3 sentences.")
                                .parse(Parsers.string())
                                .label(DETAIL) // temporarily holds description
                                .build()
                )
                .addStep(
                        StepBuilder.start("skillDegrees", defaults)
                                .system(systemMessage)
                                .user(info + "\n\nDimension: ${dimension}\nDescription: ${detail}\nProvide 5 skill degrees from novice to expert. " +
                                        "For each degree, specify the criteria a student must demonstrate and three exercise lessons to develop " +
                                        "from the current degree to the next degree. Return JSON object with fields 'description' (copy of the description) " +
                                        "and 'degrees' array with objects having 'degree', 'criteria', and 'exercises'.")
                                .parse(Parsers.json())
                                .label(DETAIL) // overwrites description with combined JSON
                                .build()
                )
                .joinInto(DETAILS)
                .endForEach()

                .build()
                .run(openAiClient);

        List<String> dims = result.get(DIMENSIONS);
        List<JsonNode> detailNodes = result.get(DETAILS);

        return SkillRubricResponse.fromDsl(dims, detailNodes);
    }

    private String buildInfo(GenerateSkillRubricRequest d) {
        return "Course title: " + safe(d.title) + "\n" +
                "Course description: " + safe(d.description) + "\n" +
                "Topic and focus: " + safe(d.topicAndFocus) + "\n" +
                "Schedule and duration: " + safe(d.scheduleAndDuration) + "\n" +
                "Target audience: " + safe(d.targetAudience) + "\n" +
                "Group size and format: " + safe(d.groupSizeAndFormat) + "\n" +
                "Location: " + safe(d.location) + "\n" +
                "How students join: " + safe(d.howStudentsJoin) + "\n" +
                "Tone and approach: " + safe(d.toneAndApproach) + "\n" +
                "Anything unusual: " + safe(d.anythingUnusual);
    }

    private static String safe(String s) {
        return s == null ? "" : s;
    }
}
