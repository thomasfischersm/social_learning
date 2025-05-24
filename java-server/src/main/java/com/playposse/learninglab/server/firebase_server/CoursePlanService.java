package com.playposse.learninglab.server.firebase_server;

import java.util.LinkedHashMap;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.playposse.learninglab.server.firebase_server.openaidsl.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class CoursePlanService {

    private final Firestore db;
    private final OpenAiClient openAiClient;
    private final ChatConfig defaults;

    // our four labels for the chain
    private static final Label<String> PRIME = Label.of("prime", String.class);
    private static final Label<String> INVENTORY_CATEGORIES = Label.of("inventoryCategories", String.class);
    private static final Label<String> INVENTORY_SOURCES = Label.of("inventorySources", String.class);
    private static final Label<String> INVENTORY_SOURCES_EVALUATION = Label.of("inventorySourcesEvaluation", String.class);
    private static final Label<String> INVENTORY = Label.of("inventory", String.class);
    private static final Label<String> STUDENT_FIRST_CLASS = Label.of("studentFirstClass", String.class);
    private static final Label<String> GOALS = Label.of("goals", String.class);
    private static final Label<String> DESIGN_CRITERIA = Label.of("designCriteria", String.class);
    private static final Label<String> SESSION_FORMAT = Label.of("sessionFormat", String.class);
    private static final Label<String> LEVEL_DESIGN = Label.of("levelDesign", String.class);
    private static final Label<String> CRITERIA_REVIEW = Label.of("criteriaReview", String.class);
    private static final Label<String> CURRICULUM = Label.of("curriculum", String.class);
    private static final Label<String> JSON_TEXT = Label.of("jsonText", String.class);

    @Autowired
    public CoursePlanService(Firestore db, SecretFetcher secretFetcher) {
        String apiKey;
        try {
            apiKey = secretFetcher.getOpenAiApiKey();
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch OpenAI API key", e);
        }

        this.db = db;
        // wrap the existing OpenAiService in our OpenAiClient interface
//        this.openAiClient = new OpenAiServiceAdapter(openAiService);
        this.openAiClient = new OpenAiClientImpl(apiKey);
        // pick whatever global defaults you like; you can override per‐step below
        this.defaults = new DefaultsBuilder().build();
    }

    public void generateCoursePlan(GenerateCoursePlanRequest request) throws Exception {
        String uid = request.uid;
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
        String systemMsg = "You are a curriculum designer creating output for use in a structured app. The user tells" +
                " the app what kind of curriculum to design, and the app breaks it down into a sequence of prompts " +
                "that it sends you.\n\nWhen you go about the task, you want to develop a deep understanding of each " +
                "area that you are asked to examine. Don't simply look at what your source data most commonly does. " +
                "Instead probe deeper. If you are asked to create a sequence of lessons, don't simply pick common " +
                "lessons done by your source material. Instead, consider what each lessons involves, ways each " +
                "lesson could be taugh, dependencies between lessons and so on. Ask yourself preparatory questions " +
                "before answering questions. For example, if you are asked to create a learning objective, don't " +
                "simply pick a common learning objective, but reflect on what goals students have for the course, " +
                "what is achievable within the course duration, how would it complement the other goals, and so on. " +
                "You also always want to ask yourself what is it that you are actually proposing. For example, if " +
                "you propose a class on communication, that's vague. Ask yourself what specific communication skill " +
                "you think would be good to teach.\n\n" +
                "In past runs, you tend to misunderstand the curriculum hierarchy. You would create courses with a " +
                "single level (which was essentially the class description) and each lesson would be a class session. " +
                "However, the model is different. In our approach when we refer to mini-lessons or short lessons " +
                "they refer to a unit of learning. Students can learn multiple lessons/mini-lessons during a class " +
                "room session. So the hierarchy is course -> many levels -> many lessons. A class room session is the " +
                "time and place where students meet to learn/teach each other mini-lessons. Example: In a chess course, " +
                "students may meet for six two-hour sessions in a six week course. Mini-lessons are concrete, teachable " +
                "atomic learning units. Examples could be a mini-lesson about how the bishop moves or the opening " +
                "the Queens Gambit. These mini-lessons may be grouped into levels for organization and to give students " +
                "intermediate goals. A level could be for all the mini-lessons on how the chess pieces move. Or a " +
                "first level could be organized as a 'crash course' with a sampler of key mini-lessons to play a first " +
                "game. Within in a class room session, students would teach each other as many mini-lessons/lessons " +
                "as they can.";

        ChainResult result = ChainBuilder
                .start(defaults)

                // Step 1: Prime
                .step(PRIME.name())
                .system(systemMsg)
                .user("You are going to create a curriculum over a sequence of steps. You are creating a " +
                        "curriculum for: \n\n---\n" + direction + "\n---\n\nLet's first prepare a deeper context for " +
                        "the course. For example, given the subject, you can make an educated guess about the types " +
                        "of students, their motivations, and background. You maybe given other elements like the " +
                        "length of the course or the location of the course, which may imply other educated guesses. " +
                        "For example, a coding bootcamp in NYC is likely to cater towards people who want to switch " +
                        "careers, who are highly motivated to pass the course and get employment. A crochet course " +
                        "in rural Oklahoma may cater more to people who primarily want to hang out and socialize " +
                        "with not too challenging content but lots of times.\n\n Getting clear on the students, " +
                        "nature of course, context, and so on based on the hints that you are given will help you " +
                        "create a better curriculum.")
                .parse(Parsers.string())
                .label(PRIME)
                .endStep()

                // Step 2: inventory categories
                .step(INVENTORY_CATEGORIES.name())
                .system(systemMsg)
                .history()
                .user("To start the process of curriculum creation, let's create an inventory of nameable, " +
                        "teachable items for the subject. Because your model likely doesn't have enough information " +
                        "encoded, we'll have to research online sources. Before you jump at looking at sources, " +
                        "let's first think of categories of sources that you might want to consider. For example, " +
                        "articles, syllabus, course descriptions, teacher training programs, manuals, " +
                        "databases/repositories, online videos (particularly their transcripts) might be good " +
                        "sources. What other types of online sources can you think of?")
                .parse(Parsers.string())
                .label(INVENTORY_CATEGORIES)
                .endStep()

                // Step 3: inventory sources
                .step(INVENTORY_SOURCES.name())
                .system(systemMsg)
                .history()
                .user("Now that you have categories of online sources, do an online search to identify good URLs" +
                        "that would give you nameable, teachable elements of the subject. Be sure to access online " +
                        "sources and not answer from your memory!")
                .parse(Parsers.string())
                .label(INVENTORY_SOURCES)
                .maxTokens(9000)
                .endStep()

                // Step 3.5: inventory
                .step(INVENTORY_SOURCES_EVALUATION.name())
                .system(systemMsg)
                .history()
                .user("Check the URLs and evaluate the sources for their quality to contain information for the " +
                        "curriculum generation. Some of the sites may simply be marketing material with no info. Other " +
                        "pages may contain valuable information about the subject. Some may be a single page. Others may " +
                        "be multiple pages, like a database, repository, or blog about the subject. Identify high-value " +
                        "sources (and their URL) and also how deeply you would want to crawl them.")
                .maxTokens(9000)
                .parse(Parsers.string())
                .label(INVENTORY_SOURCES_EVALUATION)
                .endStep()

                // Step 4: inventory
                .step(INVENTORY.name())
                .system(systemMsg)
                .history()
                .user("Now that you have URLs to good sources, browse the pages and extract a list of nameable, teachable " +
                        "elements of the subject. And combine the lists into one master list. Group the items into " +
                        "categories that make sense.")
                .maxTokens(9000)
                .parse(Parsers.string())
                .label(INVENTORY)
                .endStep()

                // Step 5: student first class
                .step(STUDENT_FIRST_CLASS.name())
                .system(systemMsg)
                .history()
                .user(direction)
                .user("Let's switch track a bit. Consider what the emotional state/needs and readiness of " +
                        "students are in the first class session? What are their expectations? E.g., do they have " +
                        "certain fears or expectations? What do they need to successfully onboard both based on " +
                        "their existing experience/skills and emotional/psychological starting point. How can the " +
                        "class best meet them where they are at?")
                .parse(Parsers.string())
                .label(STUDENT_FIRST_CLASS)
                .endStep()

                // Step 6: goals
                .step(GOALS.name())
                .system(systemMsg)
                .history()
                .user("Define inspiring yet realistic outcomes for this course based on the listed teachable content. " +
                        "Consider time limits of each session and the duration that each teachable unit would " +
                        "require. Plan for most of the lesson to be taught in a cascading peer teaching approach. " +
                        "The instructor will teach one student. Once that student has mastered the mini-lesson, " +
                        "they will teach the next student. This means that students will learn hands-on interactive. " +
                        "They can ask questions and get feedback. Also, the teaching is part of the learning " +
                        "experience because it deepens the understanding and tests for knowledge gaps. Because there " +
                        "is a learn and teach component, you'll have to anticipate the time needed for a " +
                        "mini-lesson is actually twice its duration.\n\n" +
                        "Define the kind of student experience and emotional arc we want. Then suggest which goals to aim for.")
                .parse(Parsers.string())
                .label(GOALS)
                .endStep()

                // Step 7: design criteria
                .step(DESIGN_CRITERIA.name())
                .system(systemMsg)
                .history()
                .user("I want you to think about what would make a good curriculum design. You often design " +
                        "courses in a very logical fashion as one would create a book: Start at the very beginning, " +
                        "and slowly explain each theoretical point. However, if students come for a workout class, " +
                        "they don't expect to sit for a lecture. They expect to be physical pretty much from the " +
                        "beginning with talks being short and during strategic points, like at the start of a " +
                        "session or during cooldown. Even non-physical subjects are often better learned by early " +
                        "hands-on immersion. Instead of sitting for three hours passively listening, having an " +
                        "interactive exercise to engage with the material is better even for subjects like " +
                        "marketing. You might also want to think about spaced repetition. Some things might need " +
                        "more repetition, which is better done over time for better learning. Try to think of " +
                        "criteria that would make for a good curriculum design and create yourself rules that you " +
                        "can later check. Make these specific to the given course description (\"" + direction + "\").")
                .parse(Parsers.string())
                .label(DESIGN_CRITERIA)
                .endStep()

                // Step 6: goals
                .step(GOALS.name())
                .system(systemMsg)
                .history()
                .user("Define inspiring yet realistic outcomes for this course based on the listed teachable content. " +
                        "Consider time limits of each session and the duration that each teachable unit would " +
                        "require. Plan for most of the lesson to be taught in a cascading peer teaching approach. " +
                        "The instructor will teach one student. Once that student has mastered the mini-lesson, " +
                        "they will teach the next student. This means that students will learn hands-on interactive. " +
                        "They can ask questions and get feedback. Also, the teaching is part of the learning " +
                        "experience because it deepens the understanding and tests for knowledge gaps. Because there " +
                        "is a learn and teach component, you'll have to anticipate the time needed for a " +
                        "mini-lesson is actually twice its duration.\n\n" +
                        "Define the kind of student experience and emotional arc we want. Then suggest which goals to aim for.")
                .parse(Parsers.string())
                .label(GOALS)
                .endStep()

                // Step 7: session format
                .step(SESSION_FORMAT.name())
                .system(systemMsg)
                .history()
                .user("Let's think about the design of the course. Start by thinking about how you would design" +
                        " a session in the course. You probably want to allocate most of the time to mini-lessons " +
                        "that students teach each other. However, you might also have elements like an opening " +
                        "circle, spaced repetition, or a showcase at the end of a session where some or all students " +
                        "can show what they learned or debrief. Remember, that you want to use these extra elements " +
                        "judiciously for maximum effect. A good, short showcase for the right subject can be very " +
                        "motivational. However, it's also taking away time from learning mini-lessons. If you spend " +
                        "the whole class on talking about feelings and showcasing, students won't learn much.\n\n" +
                        "Also think about what design makes sense for the mini-lessons. In some subjects, 15 minutes " +
                        "for a mini-lesson gives students enough time to handle a subject and get to success. " +
                        "Sometimes, mini-lessons might be shorter, e.g. a warm-up for a physical class may only " +
                        "take 3-5 minutes for both partners to get a turn. A mini-lesson for a chess club might " +
                        "require enough time to actually get through a chess opening. So consider what makes sense " +
                        "for the given subject.\n\n" +
                        "In past runs, you've had issues where your lessons included lots of things. Let me be " +
                        "clear: Each lesson should be an atomic unit. If it's a chess course, each lesson might be an " +
                        "opening or how a chess piece moves. If it's an acroyoga class, it's a single pose or warm-up. " +
                        "A lesson is not a whole bunch of things that you stuff together.\n\n" +
                        "If you are confused: A course refers to the entire program. A session a time when students " +
                        "and the teacher meet up. A mini-lesson (or short lesson) is a learning unit in the " +
                        "course that can be checked off and completed. A level is a logical grouping of " +
                        "mini-lessons.\n\n" +
                        "For example, a 6-week chess course would meet for six weeks. A session may be structured as " +
                        "a 10-minute welcome by the teacher to explain what to expect. Then, there might be " +
                        "40 minutes for students to teach each other mini-lessons. Some students will progress faster " +
                        "than others. The levels may be laid out so that fast students can finish one for each " +
                        "session. The first level may be have one mini-lesson for the rules of how each chess piece can " +
                        "move. The mentoring student may explain how it works and then do an exercise to apply it. " +
                        "The second level may have one mini-lesson for each for one common chess opening each. There " +
                        "may be a mini-lesson thrown in about how to stay clear-headed under pressure. Because just " +
                        "telling that to someone, this wouldn't be a lecture only but some creatively-designed " +
                        "practical exercise. The final ten minutes of class may be a demonstrating chess game between " +
                        "the instructor and a student where the instructor explains the game while it happens.\n\n" +
                        "Another example is acroyoga. Let's say a level starts with warm-ups, then introduces " +
                        "acroyoga poses, and finishes with a flow (washing machine) that connects the poses as a" +
                        "capstone. The warm-ups would be smartly chosen to not simply be warm-ups but teach " +
                        "acroyoga principles and prepare for the poses. For example, body tightness drills " +
                        "prepare students for the base to remove one foot from the flyer in bird pose and for the " +
                        "flyer to remain tight and not lose balance. Perhaps, a twelve-week course is laid out with " +
                        "the plan of teaching the washing machine four-step. Four-step consists of four poses. One " +
                        "of them is star. Star is a more advanced inversion than shoulderstand. Shoulderstand is a" +
                        "more advanced version than candlestick. Doing solo tripod headstand is a good preparation " +
                        "for an inversion like candlestick. You can see how the prerequisites and preparation for the " +
                        "final goal (four-step washing machine) fan out. So the whole course might be designed with " +
                        "that end goal in mind.\n\n" +
                        "To be really clear: Each mini-lesson is a single, unique teachable unit, usually something " +
                        "practical, interactive with a clear outcome/success. It's not a meandering all kinds of " +
                        "things. Levels are logical groupings to shape the mini-lessons into a greater whole and to " +
                        "provide students with a sense of progress and intermediate goals.")
                .parse(Parsers.string())
                .label(SESSION_FORMAT)
                .endStep()

                // Step 8: level design
                .step(LEVEL_DESIGN.name())
                .system(systemMsg)
                .history()
                .user("Let's design the levels. First, consider that a level should be a logically complete unit" +
                        " that builds up to a greater something. It should probably also correlate somewhat to the " +
                        "timing of the course, e.g. each week could be a different level. You'll also have to think " +
                        "about the content of the level that it fits within the given time. Identify what would make " +
                        "good levels for the course and then define a summary for it, learning outcomes, and named, " +
                        "teachable elements to include. Use the course learning outcomes and student readiness in " +
                        "this exercise.\n\n" +
                        "As a reminder, you've often created courses with a single level where each lesson was the " +
                        "the entire session for that day. That's dead wrong! You are supposed to create mini-lessons " +
                        "that are unique, atomic, teachable units. There are many of these to be learned in each " +
                        "class room session. And they are supposed to be grouped into levels to create organization " +
                        "and progress points for students.\n\n" +
                        "Again, a mini-lesson (aka lesson) is not the entire time together, but it's one of many units " +
                        "that are taught during a class.")
                .parse(Parsers.string())
                .label(LEVEL_DESIGN)
                .endStep()

                // Step 9: criteria review
                .step(CRITERIA_REVIEW.name())
                .system(systemMsg)
                .history()
                .user("Use the design criteria that you made for the course to review the course that you've " +
                        "created. Make adjustments as you identify issues.")
                .parse(Parsers.string())
                .label(CRITERIA_REVIEW)
                .endStep()

                // Step 10: curriculum design
                .step("curriculum")
                .system(systemMsg)
                .user(direction)
                .assistant("${inventory}")
                .assistant("${goals}")
                .user("""
                        Create a curriculum for the course. Each level has multiple lessons. Lessons may have
                        graduation requirements. Graduation requirements are clear measures if a student has mastered
                        the lesson and is ready to teach it to the next student. Based on the lesson, there may or
                        may not be graduation requirements based on if there are easily verifiable checks that are
                        meaningful.
                        
                        Each lesson must include:
                        - title
                        - synopsis
                        - instructions (as one string including bullets, summary, and common issues)
                        - graduationRequirements
                        
                        Return this in formatted text (not JSON yet).
                        """)
                .parse(Parsers.string())
                .label(CURRICULUM)
                .endStep()

                // Step 11: JSON conversion
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
                        - graduationRequirements (a list of items)
                        
                        Return ONLY the following JSON structure. Be sure to return nothing else but json, not even a
                        little string 'json' in front of it:
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

        // Join every non-null completion in that order:
        String allResponses = result.callLogs().stream()
                .map(CallLog::completion)
                .filter(Objects::nonNull)
                .collect(Collectors.joining("\n\n---\n\n"));

        Map<String, Long> durationsByStep = result.callLogs().stream()
                .collect(Collectors.toMap(
                        log -> log.label().name(),
                        CallLog::durationMillis,
                        (a, b) -> b,
                        LinkedHashMap::new
                ));
        String durationsJson = new ObjectMapper().writeValueAsString(durationsByStep);

        // parse JSON into a Map and write back
        String jsonText = result.get(JSON_TEXT);
        Map<?, ?> parsedJson;
        try {
            parsedJson = new ObjectMapper().readValue(jsonText, Map.class);
        } catch (Exception e) {
            System.err.println("Invalid JSON returned by GPT:");
            System.err.println(jsonText);
            throw new RuntimeException("Invalid JSON returned by GPT", e);
        }

        Map<String, Object> updates = new HashMap<>();
        updates.put("generatedJson", new ObjectMapper().writeValueAsString(parsedJson));
        updates.put("openaiResponses", allResponses);
        updates.put("lastGenerated", FieldValue.serverTimestamp());
        updates.put("openaiDurations", durationsJson);

        coursePlanRef.update(updates);
    }
}
