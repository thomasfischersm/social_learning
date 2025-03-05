import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/online_session_review.dart';

class OnlineSessionReviewFunctions {
  static CollectionReference<Map<String, dynamic>> get _reviewCollection =>
      FirebaseFirestore.instance.collection('onlineSessionReviews');

  static Future<void> createPendingReviewsForSession(
      OnlineSession session) async {
    // Build DocumentReferences for the session and lesson.
    DocumentReference sessionRef =
        FirebaseFirestore.instance.collection('onlineSessions').doc(session.id);
    DocumentReference? lessonRef = session.lessonId;
    if (lessonRef == null) {
      print(
          'Didn\'t create reviews for session ${session.id} because it has no lesson.');
      return;
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Create the mentor's pending review.
    DocumentReference mentorReviewRef = _reviewCollection.doc();
    OnlineSessionReview mentorReview = _buildPendingReview(
      sessionRef: sessionRef,
      lessonRef: lessonRef,
      courseRef: session.courseId,
      mentorUid: session.mentorUid!,
      learnerUid: session.learnerUid!,
      reviewerUid: session.mentorUid!,
      isMentor: true,
    );
    print('Creating mentor review: ${mentorReview.toJson()}');
    batch.set(mentorReviewRef, mentorReview.toJson());

    // Create the learner's pending review.
    DocumentReference learnerReviewRef = _reviewCollection.doc();
    OnlineSessionReview learnerReview = _buildPendingReview(
      sessionRef: sessionRef,
      lessonRef: lessonRef,
      courseRef: session.courseId,
      mentorUid: session.mentorUid!,
      learnerUid: session.learnerUid!,
      reviewerUid: session.learnerUid!,
      isMentor: false,
    );
    print('Creating learner review: ${learnerReview.toJson()}');
    batch.set(learnerReviewRef, learnerReview.toJson());

    // Commit the batch.
    await batch.commit().onError(
        (error, stacktrace) => print('Error creating pending reviews: $error'));
  }

  static OnlineSessionReview _buildPendingReview({
    required DocumentReference sessionRef,
    required DocumentReference lessonRef,
    required DocumentReference courseRef,
    required String mentorUid,
    required String learnerUid,
    required String reviewerUid,
    required bool isMentor,
  }) {
    return OnlineSessionReview(
      sessionId: sessionRef,
      lessonId: lessonRef,
      courseId: courseRef,
      mentorUid: mentorUid,
      learnerUid: learnerUid,
      reviewerUid: reviewerUid,
      isMentor: isMentor,
      partnerRating: 0,
      lessonRating: 0,
      publicReview: null,
      improvementFeedback: null,
      keepDoingFeedback: null,
      blockUser: false,
      reportUser: false,
      reportDetails: null,
      isPending: true,
      created: null, // Will be set to a server timestamp on creation.
    );
  }

  /// Deletes the review with the given [reviewId].
  static Future<void> deleteReview(String reviewId) async {
    await _reviewCollection.doc(reviewId).delete();
  }

  /// Fills out a pending review with the information provided by the user.
  /// This updates the review document, setting the ratings, feedback, and marking it as not pending.
  static Future<void> fillOutReview({
    required String reviewId,
    required int partnerRating,
    required int lessonRating,
    String? publicReview,
    String? improvementFeedback,
    String? keepDoingFeedback,
    bool blockUser = false,
    bool reportUser = false,
    String? reportDetails,
  }) async {
    await _reviewCollection.doc(reviewId).update({
      'partnerRating': partnerRating,
      'lessonRating': lessonRating,
      'publicReview': publicReview,
      'improvementFeedback': improvementFeedback,
      'keepDoingFeedback': keepDoingFeedback,
      'blockUser': blockUser,
      'reportUser': reportUser,
      'reportDetails': reportDetails,
      'isPending': false,
    });
  }
}
