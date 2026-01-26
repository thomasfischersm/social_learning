import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/session_type.dart';

class SessionFunctions {
  static Future<DocumentReference<Map<String, dynamic>>> createSession({
    required String courseId,
    required String sessionName,
    required String organizerUid,
    required String organizerName,
    SessionType sessionType = SessionType.automaticManual,
    int participantCount = 1,
    bool includeHostInPairing = true,
  }) async {
    return FirestoreService.instance.collection('sessions').add({
      'courseId': docRef('courses', courseId),
      'name': sessionName,
      'organizerUid': organizerUid,
      'organizerName': organizerName,
      'participantCount': participantCount,
      'startTime': FieldValue.serverTimestamp(),
      'isActive': true,
      'sessionType': sessionType.toInt(),
      'includeHostInPairing': includeHostInPairing,
    });
  }
}
