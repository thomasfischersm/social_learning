package com.playposse.learninglab.server.firebase_server;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;

/**
 * Response object containing the full hierarchical skill rubric
 * with dimensions, degrees, and lessons.
 */
public class SkillRubricResponse {
    public final List<SkillDimension> dimensions;

    public SkillRubricResponse(List<SkillDimension> dimensions) {
        this.dimensions = dimensions;
    }

    /**
     * Builds a hierarchical SkillRubricResponse from the DSL output lists.
     */
    public static SkillRubricResponse fromDsl(List<String> dims, List<JsonNode> detailNodes) {
        ObjectMapper mapper = new ObjectMapper();
        List<SkillDimension> dimensionList = new ArrayList<>();

        for (int i = 0; i < dims.size(); i++) {
            String name = dims.get(i);
            JsonNode node = i < detailNodes.size() ? detailNodes.get(i) : null;
            String description = node != null ? node.path("description").asText() : "";

            List<SkillDegree> degreeList = new ArrayList<>();
            if (node != null) {
                for (JsonNode degreeNode : node.path("degrees")) {
                    String degreeName = degreeNode.path("degree").asText();
                    String criteria = degreeNode.path("criteria").asText();
                    List<String> lessons = mapper.convertValue(
                            degreeNode.path("exercises"),
                            new TypeReference<List<String>>() {}
                    );
                    degreeList.add(new SkillDegree(degreeName, criteria, lessons));
                }
            }

            dimensionList.add(new SkillDimension(name, description, degreeList));
        }

        return new SkillRubricResponse(dimensionList);
    }

    public record SkillDimension(String name, String description, List<SkillDegree> degrees) {}
    public record SkillDegree(String name, String criteria, List<String> lessons) {}
}
