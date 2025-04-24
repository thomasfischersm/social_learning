import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

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
