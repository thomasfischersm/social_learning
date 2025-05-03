import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from 'firebase-functions';
import { admin, db } from './firebase';

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