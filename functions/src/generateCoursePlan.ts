import { onCall } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import OpenAI from 'openai';
import { db } from './firebase';
import { defineSecret } from 'firebase-functions/params';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

export const generateCoursePlan = onCall({ secrets: [openaiApiKey] }, async (request) => {
  const openai = new OpenAI({ apiKey: openaiApiKey.value() });
  const data = request.data;
  const auth = request.auth;

  if (!auth) throw new Error('Unauthenticated user');

  const uid = auth.uid;
  const coursePlanId = data.coursePlanId;
  if (!coursePlanId || typeof coursePlanId !== 'string') throw new Error('Invalid or missing coursePlanId');

  const coursePlanRef = db.doc(`/coursePlans/${coursePlanId}`);
  const coursePlanSnap = await coursePlanRef.get();
  if (!coursePlanSnap.exists) throw new Error('CoursePlan not found');

  const coursePlan = coursePlanSnap.data();
  const courseRef = coursePlan?.courseId;
  if (!courseRef || typeof courseRef.path !== 'string') throw new Error('Missing course reference');

  const courseSnap = await courseRef.get();
  if (!courseSnap.exists) throw new Error('Course not found');

  const courseData = courseSnap.data();
  if (courseData.creatorId !== uid) throw new Error('You are not the course creator');

  const direction = coursePlan?.planJson;
  if (!direction || typeof direction !== 'string') throw new Error('Missing or invalid planJson.direction');

  // STEP 1: Ask GPT to design the course concept
  const step1 = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: 'You are an expert instructional designer helping develop a peer-led course curriculum.',
      },
      {
        role: 'user',
        content: `
Course direction: ${direction}

The course will be taught through 15-minute peer-led mini-lessons. Each student teaches the next once they master a lesson. What are the key topics, goals, and dimensions that should shape this course? Organize your answer as a short plan of what to prioritize when designing levels and lessons.
        `.trim(),
      },
    ],
    temperature: 0.7,
  });

  const courseDesign = step1.choices[0].message?.content ?? '';

  // STEP 2: Ask GPT to propose levels and lessons based on the plan
  const step2 = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: 'You are continuing the curriculum design process.' },
      { role: 'user', content: direction },
      { role: 'assistant', content: courseDesign },
      {
        role: 'user',
        content: `
Based on your design plan, now propose a curriculum outline.

Break the course into 2–4 levels, each with a short description. For each level, create 3–6 peer-teachable mini-lessons. Each lesson should:
- Be specific and teach one concept or skill
- Include a title and short synopsis
- Include a paragraph of teaching instructions
- End with graduation requirements

Return this in plain text, not JSON yet.
        `.trim(),
      },
    ],
    temperature: 0.7,
  });

  const curriculumText = step2.choices[0].message?.content ?? '';

  // STEP 3: Ask GPT to convert it to strict JSON
  const step3 = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: 'You are converting curriculum content into strict JSON.' },
      { role: 'user', content: direction },
      { role: 'assistant', content: courseDesign },
      { role: 'user', content: 'Here is the proposed curriculum outline:' },
      { role: 'assistant', content: curriculumText },
      {
        role: 'user',
        content: `
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
        `.trim(),
      },
    ],
    temperature: 0.5,
  });

  const content = step3.choices[0].message?.content;
  if (!content) throw new Error('No content returned from OpenAI');

  let parsed: any;
  try {
    parsed = JSON.parse(content);
  } catch (err) {
    logger.error('Failed to parse GPT response', err);
    throw new Error('Invalid JSON returned by GPT');
  }

  await coursePlanRef.update({ generatedJson: JSON.stringify(parsed) });
  return { success: true };
});
