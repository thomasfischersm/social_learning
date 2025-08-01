package com.playposse.learninglab.server.firebase_server;

import com.playposse.learninglab.server.firebase_server.openaidsl.*;
import com.openai.models.ChatModel;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;


import com.fasterxml.jackson.core.type.TypeReference;
import java.util.List;
import java.util.Map;

/**
 * Service that calls OpenAI to generate a starter list of teachable items
 * for a course. It does not read or write Firestore and simply returns the
 * generated structure.
 */
@Service
public class TeachableItemService {

    private final OpenAiClient openAiClient;
    private final ChatConfig defaults;

    @Autowired
    public TeachableItemService(SecretFetcher secretFetcher) {
        String apiKey;
        try {
            apiKey = secretFetcher.getOpenAiApiKey();
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch OpenAI API key", e);
        }

        this.openAiClient = new OpenAiClientImpl(apiKey);;
        this.defaults = new DefaultsBuilder()
                .temperature(0.7)
                .maxTokens(3000)
                .build();
    }

    /**
     * Generates teachable items grouped by category. The OpenAI interaction is
     * split into two stages: First it brainstorms suitable categories, then it
     * fans out a prompt for each category to list the concrete teachable items.
     */
    public Map<?, ?> generateItems(GenerateTeachableItemsRequest request) throws Exception {
        String info = buildInfo(request);

        // labels
        Label<List<String>> CATEGORIES = Label.of("categories", new TypeReference<List<String>>() {});
        Label<List<String>> ITEM_LIST = Label.of("itemList", new TypeReference<List<String>>() {});
        Label<List<List<String>>> ITEMS = Label.of("items", new TypeReference<List<List<String>>>() {});

        String systemMessage =
                "You are an expert course designer. A 'teachable item' is the smallest " +
                "atomic unit that can be taught. " +
                "Example categories for acroyoga are poses, washing machines, warm-ups, " +
                "technique drills, technique principles, and spotting. " +
                "Example categories for chess are piece movement, openings, tactics, " +
                "endgames, and strategy. " +
                "Individual items should be very short, 2-5 words each.";

        ChainResult result = ChainBuilder
                .start(defaults)

                // Step 1: brainstorm categories
                .step("categories")
                .system(systemMessage)
                .user(info + "\n\nList the key categories of teachable items. Return one category per line.")
                .parse(Parsers.stringList())
                .label(CATEGORIES)
                .endStep()

                // Step 2: items for each category
                .forEach(CATEGORIES)
                    .alias("category")
                    .addStep(
                            StepBuilder.start("items", defaults)
                                    .system(systemMessage)
                                    .user(info + "\n\nCategory: ${category}\nList teachable items for this category, one per line.")
                                    .parse(Parsers.stringList())
                                    .label(ITEM_LIST)
                                    .build()
                    )
                    .joinInto(ITEMS)
                .endForEach()

                .build()
                .run(openAiClient);

        // Combine the categories and items into the desired structure
        List<String> cats = result.get(CATEGORIES);
        List<List<String>> items = result.get(ITEMS);

        java.util.List<Map<String, Object>> categories = new java.util.ArrayList<>();
        for (int i = 0; i < Math.min(cats.size(), items.size()); i++) {
            categories.add(Map.of(
                    "category", cats.get(i),
                    "items", items.get(i)
            ));
        }

        return Map.of("categories", categories);
    }

    private String buildInfo(GenerateTeachableItemsRequest d) {
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
