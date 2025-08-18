import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from 'firebase-functions';
import { admin, db } from './firebase';

/**
 * Trigger: When a skill assessment document is created.
 * Updates the user's courseSkillAssessments field with the latest assessment per course.
 */
export const updateUserSkillAssessment = onDocumentCreated(
  'skillAssessments/{assessmentId}',
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.error('No snapshot data in event; exiting.');
      return;
    }

    const assessment = snap.data();
    if (!assessment) {
      logger.error('Empty data on new skill assessment', event.params.assessmentId);
      return;
    }

    const { courseId, studentUid, dimensions } = assessment as {
      courseId?: admin.firestore.DocumentReference;
      studentUid?: string;
      dimensions?: any[];
    };

    if (!courseId || !studentUid || !Array.isArray(dimensions)) {
      logger.error('Missing required fields in skill assessment', assessment);
      return;
    }

    // Lookup the user's document by auth UID
    const userQ = await db
      .collection('users')
      .where('uid', '==', studentUid)
      .limit(1)
      .get();

    if (userQ.empty) {
      logger.error(`No user document found with uid=${studentUid}`);
      return;
    }

    const userDoc = userQ.docs[0];
    const data = userDoc.data() || {};

    const existing = Array.isArray(data.courseSkillAssessments)
      ? data.courseSkillAssessments
      : [];

    const newEntry = {
      courseId: courseId,
      dimensions: dimensions.map((d: any) => ({
        id: d.id,
        name: d.name,
        degree: d.degree,
        maxDegrees: d.maxDegrees,
      })),
    };

    const idx = existing.findIndex((c: any) =>
      (c.courseId as admin.firestore.DocumentReference).id === courseId.id
    );

    if (idx >= 0) {
      existing[idx] = newEntry;
    } else {
      existing.push(newEntry);
    }

    await userDoc.ref.update({ courseSkillAssessments: existing });
    logger.log(
      `Updated courseSkillAssessments for user ${userDoc.id} on course ${courseId.id}`
    );
  }
);
