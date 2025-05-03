import { onCall } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import OpenAI from 'openai';
import { db } from './firebase';
import { defineSecret } from 'firebase-functions/params';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

export const generateCoursePlan = onCall({ secrets: [openaiApiKey] }, async (request) => {
  const openai = new OpenAI({
    apiKey: openaiApiKey.value(),
  });
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new Error('Unauthenticated user');
  }

  const uid = auth.uid;
  const coursePlanId = data.coursePlanId;

  if (!coursePlanId || typeof coursePlanId !== 'string') {
    throw new Error('Invalid or missing coursePlanId');
  }

  const coursePlanRef = db.doc(`/coursePlans/${coursePlanId}`);
  const coursePlanSnap = await coursePlanRef.get();

  if (!coursePlanSnap.exists) {
    throw new Error('CoursePlan not found');
  }

  const coursePlan = coursePlanSnap.data();
  const courseRef = coursePlan?.courseId;

  if (!courseRef || typeof courseRef.path !== 'string') {
    throw new Error('Missing course reference');
  }

  const courseSnap = await courseRef.get();
  if (!courseSnap.exists) {
    throw new Error('Course not found');
  }

  const courseData = courseSnap.data();
  if (courseData.creatorId !== uid) {
    throw new Error('You are not the course creator');
  }

  const planJson = coursePlan?.planJson;
  const direction = planJson;

  if (!direction || typeof direction !== 'string') {
    throw new Error('Missing or invalid planJson.direction');
  }

const messages = [
  {
    role: 'system',
    content: `
You are an expert instructional designer.

You will design a course in which students teach each lesson to a peer who has not yet learned it. Each lesson is a self-contained unit lasting about 15 minutes and should teach one specific skill or concept. The peer-teacher has just mastered the lesson and has no teaching experience.

Each lesson must include the following fields:

- "title": A concise lesson name
- "synopsis": A short summary of the lesson’s focus
- "instructions": A **single string**, written for the peer-teacher, that includes:
  - A bulleted list (~6 items) of step-by-step teaching instructions
  - A short explanation of the concept or skill (as mentor reference)
  - A short list of 2–4 common learner mistakes or misconceptions

All of this content must be returned **inside a single string** in the "instructions" field. Do not split this into multiple items or arrays.

- "graduationRequirements": A short list of 2–4 things the learner must demonstrate before progressing

The course must be organized into "levels", each with a title and short description, grouping related lessons together.

Do not include any explanatory text. Return only strict JSON with this structure.

`.trim(),
  },
    {
      role: 'user',
      content: `Course direction: ${direction}

Return only JSON with the following structure:
{
  "levels": [
    {
      "title": "Level Title",
      "description": "Level Description",
      "lessons": [
        {
          "title": "Lesson Title",
          "synopsis": "Short summary of the lesson",
          "instructions": "Instructions on how to teach and learn the skill",
          "graduationRequirements": [
            "Requirement 1",
            "Requirement 2"
          ]
        }
      ]
    }
  ]
}`,
    },
  ] as OpenAI.ChatCompletionMessageParam[];

  const chatResponse = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [...messages],
    temperature: 0.7,
  });

  const content = chatResponse.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('No content returned from OpenAI');
  }

  let parsed: any;
  try {
    parsed = JSON.parse(content);
  } catch (err) {
    logger.error('Failed to parse GPT response', err);
    throw new Error('Invalid JSON returned by GPT');
  }

//   await coursePlanRef.update({ generatedJson: parsed });
  await coursePlanRef.update({ generatedJson: JSON.stringify(parsed) });
  return { success: true };
});
