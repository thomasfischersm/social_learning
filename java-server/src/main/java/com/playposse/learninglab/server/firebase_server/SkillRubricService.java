package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.playposse.learninglab.server.firebase_server.openaidsl.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

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
                .temperature(1) // Deprecated by OpenAI.
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
        Label<List<String>> DEGREE_LABELS = Label.of("degreeLabels", new com.fasterxml.jackson.core.type.TypeReference<>() {});
        Label<List<String>> DIMENSIONS = Label.of("dimensions", new com.fasterxml.jackson.core.type.TypeReference<>() {});
        Label<String> DETAIL = Label.of("detail", String.class); // reused for interim strings
        Label<List<String>> DEGREE_DESCRIPTIONS = Label.of("degreeDescriptions", new com.fasterxml.jackson.core.type.TypeReference<>() {});
        Label<List<String>> DEGREE_EXERCISES = Label.of("degreeExercises", new com.fasterxml.jackson.core.type.TypeReference<>() {});

        String systemMessage =
                "You are an expert educator designing skill rubrics. A skill dimension is a major competency " +
                        "area for the course. Each dimension has five skill degrees from novice to expert, each with " +
                        "criteria and exercises.";

        ChainResult result = ChainBuilder
                .start(defaults)

                // Step 1: get global degree labels
                .step("degreeLabels")
                .system(systemMessage)
                .user(info + "\n\nList the five skill degree labels from novice to expert. Return one per line.")
                .parse(Parsers.stringList())
                .label(DEGREE_LABELS)
                .maxTokens(50)
                .endStep()

                // Step 2: brainstorm dimensions
                .step("dimensions")
                .system(systemMessage)
                .user(info + "\n\nList 5-7 key skill dimensions for this course. Return one per line.")
                .parse(Parsers.stringList())
                .label(DIMENSIONS)
                .endStep()

                // Step 3: for each dimension get degree criteria
                .forEach(DIMENSIONS)
                .alias("dimension")
                .addStep(
                        StepBuilder.start("degreeDescriptions", defaults)
                                .system(systemMessage)
                                .user(info + "\n\nDimension: ${dimension}\nDegree labels: ${degreeLabels}\nFor each degree, describe what a student must demonstrate at that degree for this dimension. Return one paragraph per degree, separated by a blank line, and follow the order of the degree labels.")
                                .parse(Parsers.string())
                                .label(DETAIL)
                                .maxTokens(800)
                                .build()
                )
                .joinInto(DEGREE_DESCRIPTIONS)
                .endForEach()

                // Step 4: for each dimension get exercises
                .forEach(DIMENSIONS)
                .alias("dimension")
                .addStep(
                        StepBuilder.start("degreeExercises", defaults)
                                .system(systemMessage)
                                .user(info + "\n\nDimension: ${dimension}\nDegree labels: ${degreeLabels}\nFor each degree, list three exercises a student can do to progress to the next degree. Provide one exercise per line and separate each group of exercises by a blank line. Follow the order of the degree labels.")
                                .parse(Parsers.string())
                                .label(DETAIL)
                                .maxTokens(800)
                                .build()
                )
                .joinInto(DEGREE_EXERCISES)
                .endForEach()

                .build()
                .run(openAiClient);

        List<String> dims = result.get(DIMENSIONS);
        List<String> degreeLabels = result.get(DEGREE_LABELS);
        List<String> degreeDescStrings = result.get(DEGREE_DESCRIPTIONS);
        List<String> degreeExerciseStrings = result.get(DEGREE_EXERCISES);

        ObjectMapper mapper = new ObjectMapper();
        List<JsonNode> detailNodes = new ArrayList<>();
        for (int i = 0; i < dims.size(); i++) {
            String descBlock = i < degreeDescStrings.size() ? degreeDescStrings.get(i) : "";
            List<String> criteriaList = Arrays.stream(descBlock.split("\n\n"))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());

            String exBlock = i < degreeExerciseStrings.size() ? degreeExerciseStrings.get(i) : "";
            List<List<String>> exerciseGroups = Arrays.stream(exBlock.split("\n\n"))
                    .map(group -> Arrays.stream(group.split("\n"))
                            .map(String::trim)
                            .filter(s -> !s.isEmpty())
                            .collect(Collectors.toList()))
                    .collect(Collectors.toList());

            ArrayNode degreesArr = mapper.createArrayNode();
            for (int j = 0; j < degreeLabels.size(); j++) {
                String degreeName = degreeLabels.get(j);
                String criteria = j < criteriaList.size() ? criteriaList.get(j) : "";
                List<String> exercises = j < exerciseGroups.size() ? exerciseGroups.get(j) : List.of();

                ObjectNode degreeNode = mapper.createObjectNode();
                degreeNode.put("degree", degreeName);
                degreeNode.put("criteria", criteria);
                ArrayNode exArr = mapper.createArrayNode();
                for (String ex : exercises) {
                    exArr.add(ex);
                }
                degreeNode.set("exercises", exArr);
                degreesArr.add(degreeNode);
            }

            ObjectNode dimNode = mapper.createObjectNode();
            dimNode.put("description", "");
            dimNode.set("degrees", degreesArr);
            detailNodes.add(dimNode);
        }

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
