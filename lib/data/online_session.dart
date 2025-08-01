import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';

enum OnlineSessionStatus {
  waiting, // 0
  active, // 1
  completed, // 2
  cancelled, // 3
}

extension OnlineSessionStatusExtension on OnlineSessionStatus {
  int get code {
    switch (this) {
      case OnlineSessionStatus.waiting:
        return 0;
      case OnlineSessionStatus.active:
        return 1;
      case OnlineSessionStatus.completed:
        return 2;
      case OnlineSessionStatus.cancelled:
        return 3;
    }
  }
}

OnlineSessionStatus onlineSessionStatusFromInt(int code) {
  switch (code) {
    case 0:
      return OnlineSessionStatus.waiting;
    case 1:
      return OnlineSessionStatus.active;
    case 2:
      return OnlineSessionStatus.completed;
    case 3:
      return OnlineSessionStatus.cancelled;
    default:
      throw Exception('Unknown OnlineSessionStatus code: $code');
  }
}

class OnlineSession {
  String? id;
  DocumentReference courseId;
  String? learnerUid;
  String? mentorUid;
  String? videoCallUrl;
  bool isMentorInitiated; // true if the session was initiated by a mentor
  OnlineSessionStatus status; // typed status using integers
  Timestamp? created;
  Timestamp? lastActive;
  Timestamp? pairedAt;
  DocumentReference? lessonId; // optional reference to the lesson/topic
  // TODO: Add learned lessons so that we don't have to load them during the
  // pairing process.

  OnlineSession({
    this.id,
    required this.courseId,
    required this.learnerUid,
    this.mentorUid,
    this.videoCallUrl,
    required this.isMentorInitiated,
    required this.status,
    this.created,
    this.lastActive,
    this.pairedAt,
    this.lessonId,
  });

  OnlineSession.fromQuerySnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        courseId = snapshot.data()['courseId'] as DocumentReference,
        learnerUid = snapshot.data()['learnerUid'] as String?,
        mentorUid = snapshot.data()['mentorUid'] as String?,
        videoCallUrl = snapshot.data()['videoCallUrl'] as String?,
        isMentorInitiated = snapshot.data()['isMentorInitiated'] as bool,
        status = onlineSessionStatusFromInt(snapshot.data()['status'] as int),
        created = snapshot.data()['created'] as Timestamp?,
        lastActive = snapshot.data()['lastActive'] as Timestamp?,
        pairedAt = snapshot.data()['pairedAt'] as Timestamp?,
        lessonId = snapshot.data()['lessonId'] as DocumentReference?;

  OnlineSession.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        courseId = snapshot.data()!['courseId'] as DocumentReference,
        learnerUid = snapshot.data()?['learnerUid'] as String?,
        mentorUid = snapshot.data()?['mentorUid'] as String?,
        videoCallUrl = snapshot.data()?['videoCallUrl'] as String?,
        isMentorInitiated = snapshot.data()?['isMentorInitiated'] as bool,
        status = onlineSessionStatusFromInt(snapshot.data()?['status'] as int),
        created = snapshot.data()?['created'] as Timestamp?,
        lastActive = snapshot.data()?['lastActive'] as Timestamp?,
        pairedAt = snapshot.data()?['pairedAt'] as Timestamp?,
        lessonId = snapshot.data()?['lessonId'] as DocumentReference?;

  OnlineSession.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        courseId = docRef('courses', json['courseId'] as String),
        learnerUid = json['learnerUid'] as String?,
        mentorUid = json['mentorUid'] as String?,
        videoCallUrl = json['videoCallUrl'] as String?,
        isMentorInitiated = json['isMentorInitiated'] as bool,
        status = onlineSessionStatusFromInt(json['status'] as int),
        created =
            json['created'] is Timestamp ? json['created'] as Timestamp : null,
        lastActive = json['lastActive'] is Timestamp
            ? json['lastActive'] as Timestamp
            : null,
        pairedAt = json['pairedAt'] is Timestamp
            ? json['pairedAt'] as Timestamp
            : null,
        lessonId = json['lessonId'] as DocumentReference?;
}
