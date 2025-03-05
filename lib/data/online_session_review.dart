import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineSessionReview {
  String? id;
  DocumentReference sessionId;
  DocumentReference lessonId;
  DocumentReference courseId;
  String mentorUid;
  String learnerUid;
  String reviewerUid;
  bool isMentor; // true if the reviewer is a mentor, false if a learner
  int partnerRating; // rating for the partner (1-5)
  int lessonRating; // rating for the lesson (1-5)
  String? publicReview; // public comment
  String? improvementFeedback; // "What is the most impactful thing that the other user could improve?"
  String? keepDoingFeedback; // "What is one thing that the other user did well and should keep doing?"
  bool blockUser; // flag to block the user (for future implementation)
  bool reportUser; // flag to report the user
  String? reportDetails; // optional details about the report
  bool isPending; // true if the review is pending
  Timestamp? created;

  OnlineSessionReview({
    this.id,
    required this.sessionId,
    required this.lessonId,
    required this.courseId,
    required this.mentorUid,
    required this.learnerUid,
    required this.reviewerUid,
    required this.isMentor,
    required this.partnerRating,
    required this.lessonRating,
    this.publicReview,
    this.improvementFeedback,
    this.keepDoingFeedback,
    required this.blockUser,
    required this.reportUser,
    this.reportDetails,
    required this.isPending,
    this.created,
  });

  factory OnlineSessionReview.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('No data in snapshot for OnlineReview');
    }
    return OnlineSessionReview(
      id: snapshot.id,
      sessionId: data['sessionId'] as DocumentReference,
      lessonId: data['lessonId'] as DocumentReference,
      courseId: data['courseId'] as DocumentReference,
      mentorUid: data['mentorUid'] as String,
      learnerUid: data['learnerUid'] as String,
      reviewerUid: data['reviewerUid'] as String,
      isMentor: data['isMentor'] as bool,
      partnerRating: data['partnerRating'] as int,
      lessonRating: data['lessonRating'] as int,
      publicReview: data['publicReview'] as String?,
      improvementFeedback: data['improvementFeedback'] as String?,
      keepDoingFeedback: data['keepDoingFeedback'] as String?,
      blockUser: data['blockUser'] as bool,
      reportUser: data['reportUser'] as bool,
      reportDetails: data['reportDetails'] as String?,
      isPending: data['isPending'] as bool,
      created: data['created'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'lessonId': lessonId,
      'courseId': courseId,
      'mentorUid': mentorUid,
      'learnerUid': learnerUid,
      'reviewerUid': reviewerUid,
      'isMentor': isMentor,
      'partnerRating': partnerRating,
      'lessonRating': lessonRating,
      'publicReview': publicReview,
      'improvementFeedback': improvementFeedback,
      'keepDoingFeedback': keepDoingFeedback,
      'blockUser': blockUser,
      'reportUser': reportUser,
      'reportDetails': reportDetails,
      'isPending': isPending,
      'created': created ?? FieldValue.serverTimestamp(),
    };
  }
}
