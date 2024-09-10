import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressVideo {
  String id;
  DocumentReference userId;
  String userUid;
  DocumentReference lessonId;
  String youtubeUrl;
  String? youtubeVideoId;
  Timestamp? timestamp;

  ProgressVideo(this.id, this.userId, this.userUid, this.lessonId,
      this.youtubeUrl, this.youtubeVideoId, this.timestamp);

  ProgressVideo.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        userId = e.data()['userId'] as DocumentReference,
        userUid = e.data()['userUid'] as String,
        lessonId = e.data()['lessonId'] as DocumentReference,
        youtubeUrl = e.data()['youtubeUrl'] as String,
        youtubeVideoId = e.data()['youtubeVideoId'] as String?,
        timestamp = e.data()['timestamp'] as Timestamp?;

  ProgressVideo.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> data)
      : id = data.id,
        userId = data['userId'] as DocumentReference,
        userUid = data['userUid'] as String,
        lessonId = data['lessonId'] as DocumentReference,
        youtubeUrl = data['youtubeUrl'] as String,
        youtubeVideoId = data['youtubeVideoId'] as String?,
        timestamp = data['timestamp'] as Timestamp?;
}
