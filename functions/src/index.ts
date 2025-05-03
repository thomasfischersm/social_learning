// import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
// import * as admin from "firebase-admin";
// import { logger } from 'firebase-functions';
// import * as functions from 'firebase-functions';
// import { Configuration, OpenAIApi } from 'openai';

// admin.initializeApp();
// const db = admin.firestore();



export { updateMostAdvancedStudent } from './updateMostAdvancedStudent';
export { updateUserLastLessonTimestamp } from './updateUserLastLessonTimestamp';
export { generateCoursePlan } from './generateCoursePlan';