import { onCall } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import OpenAI from 'openai';
import { db } from './firebase';
import { defineSecret } from 'firebase-functions/params';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

export const generateCoursePlan = onCall({ secrets: [openaiApiKey], timeoutSeconds: 540 }, async (request) => {
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

  let openaiResponses = [];

  // STEP 1: Bottom-up inventory of teachable items
  const step1 = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: 'You are a curriculum designer identifying all teachable elements for a course.' },
      {
        role: 'user',
        content: `Course direction: ${direction}

List specific skills, concepts, drills, poses, or principles that might be taught. For each, mention prerequisites and a rough estimate of difficulty or readiness needed.`
      }
    ],
    temperature: 0.7,
  });
  const inventoryText = step1.choices[0].message?.content ?? '';
  openaiResponses.push(inventoryText);

  // STEP 2: Top-down goal design
  const step2 = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: 'You are helping define goals and experience for a course.' },
      { role: 'user', content: direction },
      { role: 'assistant', content: inventoryText },
      {
        role: 'user',
        content: `Define inspiring yet realistic outcomes for this course based on the listed teachable content. Consider time limits (about 15 minutes per lesson. Each student learns a lesson and then teaches it. Thus a student can finish learning/teaching two lessons per hour.). Define the kind of student experience and emotional arc we want. Then suggest which goals to aim for.`
      },
    ],
    temperature: 0.7,
  });
  const goalsText = step2.choices[0].message?.content ?? '';
  openaiResponses.push(goalsText);

  // STEP 3: Structure levels and lessons based on goals and content
  const step3 = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: 'You are designing a level-based curriculum for peer-teaching.' },
      { role: 'user', content: direction },
      { role: 'assistant', content: inventoryText },
      { role: 'assistant', content: goalsText },
      {
        role: 'user',
        content: `Organize the course into 2–4 levels. Each level should have 3–6 peer-teachable lessons. Each lesson must include:
- title
- synopsis
- instructions (as one string including bullets, summary, and common issues)
- 2–4 graduationRequirements

Return this in formatted text (not JSON yet).`
      },
    ],
    temperature: 0.6,
  });
  const curriculumText = step3.choices[0].message?.content ?? '';
  openaiResponses.push(curriculumText);

  // STEP 4: Convert to strict JSON
  const step4 = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: 'You are converting structured curriculum content into strict JSON.' },
      { role: 'user', content: direction },
      { role: 'assistant', content: inventoryText },
      { role: 'assistant', content: goalsText },
      { role: 'assistant', content: curriculumText },
      {
        role: 'user',
        content: `Now convert the curriculum to JSON.

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
  ]`
      },
    ],
    temperature: 0.5,
  });

  const content = step4.choices[0].message?.content;
  if (!content) throw new Error('No content returned from OpenAI');

  let parsed: any;
  try {
    parsed = JSON.parse(content);
  } catch (err) {
    logger.error('Failed to parse GPT response', err);
    throw new Error('Invalid JSON returned by GPT');
  }

  await coursePlanRef.update({
    generatedJson: JSON.stringify(parsed),
    openaiResponses: openaiResponses.join('\n\n---\n\n')
  });

  return { success: true };
});
