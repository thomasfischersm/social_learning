import 'package:cloud_firestore/cloud_firestore.dart';

class LessonComment {
  String? id;
  DocumentReference lessonId;
  DocumentReference? courseId;
  String text;
  DocumentReference creatorId;
  String creatorUid;
  DateTime? createdAt;

  LessonComment(this.id, this.lessonId, this.courseId, this.text, this.creatorId,
      this.creatorUid, this.createdAt);

  LessonComment.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        lessonId = e.data()['lessonId'] as DocumentReference,
        courseId = e.data()['courseId'] as DocumentReference?,
        text = e.data()['text'] as String,
        creatorId = e.data()['creatorId'] as DocumentReference,
        creatorUid = e.data()['creatorUid'] as String,
        createdAt = (e.data()['createdAt'] as Timestamp?)?.toDate();
}
