import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressVideo {
  String id;
  DocumentReference userId;
  String userUid;
  DocumentReference courseId;
  DocumentReference lessonId;
  String youtubeUrl;
  String? youtubeVideoId;
  bool isProfilePrivate;
  Timestamp? timestamp;

  ProgressVideo(
      this.id,
      this.userId,
      this.userUid,
      this.courseId,
      this.lessonId,
      this.youtubeUrl,
      this.youtubeVideoId,
      this.isProfilePrivate,
      this.timestamp);

  ProgressVideo.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        userId = e.data()['userId'] as DocumentReference,
        userUid = e.data()['userUid'] as String,
        courseId = e.data()['courseId'] as DocumentReference,
        lessonId = e.data()['lessonId'] as DocumentReference,
        youtubeUrl = e.data()['youtubeUrl'] as String,
        youtubeVideoId = e.data()['youtubeVideoId'] as String?,
        isProfilePrivate = e.data()['isProfilePrivate'] as bool? ?? false,
        timestamp = e.data()['timestamp'] as Timestamp?;

  ProgressVideo.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> data)
      : id = data.id,
        userId = data['userId'] as DocumentReference,
        userUid = data['userUid'] as String,
        lessonId = data['lessonId'] as DocumentReference,
        courseId = data['courseId'] as DocumentReference,
        youtubeUrl = data['youtubeUrl'] as String,
        youtubeVideoId = data['youtubeVideoId'] as String?,
        isProfilePrivate =
            (data.data()?.containsKey('isProfilePrivate') ?? false)
                ? data['isProfilePrivate'] as bool
                : false,
        timestamp = data['timestamp'] as Timestamp?;
}
