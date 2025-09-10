import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/session_participant.dart';

class SessionParticipantFunctions {
  /// Fetches the active [SessionParticipant] document for the given [userId].
  static Future<SessionParticipant?> getActiveParticipant(String userId) async {
    var userRef = docRef('users', userId);
    var snapshot = await FirestoreService.instance
        .collection('sessionParticipants')
        .where('participantId', isEqualTo: userRef)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return SessionParticipant.fromSnapshot(snapshot.docs.first);
  }

  /// Marks the participant with the given [participantId] as inactive.
  static Future<void> deactivate(String participantId) {
    return FirestoreService.instance
        .collection('sessionParticipants')
        .doc(participantId)
        .update({'isActive': false});
  }
}
