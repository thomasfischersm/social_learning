import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { logger } from 'firebase-functions';

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger: when any User document is updated.
 * Only runs when courseProficiencies change, to update the "Most Advanced" student per course.
 * Skips if the updated user’s UID matches the course’s creatorId.
 */
export const updateMostAdvancedStudent = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;

    // Read before/after snapshots
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    if (!beforeData || !afterData) {
      return;
    }

    // The user's auth‐UID is static, set on creation
    const updatedUid = afterData.uid as string;

    // Pull out the arrays of proficiencies
    const beforeProfs = Array.isArray(beforeData.courseProficiencies)
      ? beforeData.courseProficiencies
      : [];
    const afterProfs = Array.isArray(afterData.courseProficiencies)
      ? afterData.courseProficiencies
      : [];

    // Only look at entries whose proficiency actually changed
    const changed = afterProfs.filter((cp: any) => {
      const prev = beforeProfs.find((b: any) =>
        (b.courseId as admin.firestore.DocumentReference).id ===
        (cp.courseId as admin.firestore.DocumentReference).id
      );
      return !prev || prev.proficiency !== cp.proficiency;
    });
    if (changed.length === 0) {
      return;
    }

    // For each changed course proficiency, update analytics—unless it's the instructor
    await Promise.all(
      changed.map(async (cp: any) => {
        const courseRef = cp.courseId as admin.firestore.DocumentReference;
        const prof = typeof cp.proficiency === "number" ? cp.proficiency : 0;

        // Fetch the course doc to get creatorId (which holds the instructor’s UID)
        const courseSnap = await courseRef.get();
        const courseData = courseSnap.data() || {};
        const instructorUid = courseData.creatorId as string;

        // Skip if this update is coming from the instructor themselves
        if (updatedUid === instructorUid) {
          return;
        }

        // Read or create the analytics doc for this course
        const analyticsRef = db.doc(`courseAnalytics/${courseRef.id}`);
        const statsSnap = await analyticsRef.get();
        const stats = statsSnap.exists ? statsSnap.data()! : {};
        const currentBest =
          typeof stats.topProficiency === "number"
            ? stats.topProficiency
            : 0;

        // If this student just hit 100% or beats the previous best, record them
        if (prof === 1 || prof > currentBest) {
          await analyticsRef.set(
            {
              topStudentId: userId,
              topProficiency: prof,
              topTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      })
    );
  }
);

/**
 * Trigger: When a document is written in the PracticeRecords collection.
 * Filter to process only create events.
 * Updates the lastLessonTimestamp field for the mentor and mentee in User documents.
 */
export const updateUserLastLessonTimestamp = onDocumentCreated(
  'practiceRecords/{recordId}',
  async (event) => {
    const recordId = event.params.recordId;
    logger.log('practiceRecords.onCreate fired for', recordId);

    // Guard against missing snapshot
    const snap = event.data;
    if (!snap) {
      logger.error('No snapshot data in event; exiting.');
      return;
    }

    // Now TS knows `snap` is defined
    const practiceData = snap.data();
    if (!practiceData) {
      logger.warn('Empty data on new practiceRecord', recordId);
      return;
    }

    const { mentorUid, menteeUid } = practiceData as {
      mentorUid?: string;
      menteeUid?: string;
    };
    if (!mentorUid || !menteeUid) {
      logger.error('Missing mentorUid or menteeUid', practiceData);
      return;
    }

    const ts = admin.firestore.FieldValue.serverTimestamp();

    // Helper to look up a user doc by its `uid` field and update it
    async function updateLastActivityField(authUid: string) {
      const userQ = await db
        .collection('users')
        .where('uid', '==', authUid)
        .limit(1)
        .get();

      if (userQ.empty) {
        logger.error(`No user document found with uid=${authUid}`);
        return;
      }

      const userDoc = userQ.docs[0];
      await userDoc.ref.update({ lastLessonTimestamp: ts });
      logger.log(`Updated lastLessonTimestamp on users/${userDoc.id}`);
    }

    try {
      await Promise.all([
        updateLastActivityField(mentorUid),
        updateLastActivityField(menteeUid),
      ]);
      logger.log(
        `Completed updating lastLessonTimestamp for mentor=${mentorUid}, mentee=${menteeUid}`
      );
    } catch (err) {
      logger.error('Error updating lastLessonTimestamp:', err);
      throw err;
    }
  }
);
