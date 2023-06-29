import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  String? id;
  DocumentReference courseId;
  DocumentReference? levelId;
  int sortOrder;
  String title;
  String? synopsis;
  String instructions;
  String? cover;
  String? recapVideo;
  String? lessonVideo;
  String? practiceVideo;
  @Deprecated('Use Level class instead')
  bool isLevel;
  String creatorId;

  Lesson(
      this.id,
      this.courseId,
      this.levelId,
      this.sortOrder,
      this.title,
      this.synopsis,
      this.instructions,
      this.cover,
      this.recapVideo,
      this.lessonVideo,
      this.practiceVideo,
      this.isLevel,
      this.creatorId);

  Lesson.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        levelId = e.data()['levelId'] as DocumentReference?,
        sortOrder = e.data()['sortOrder'] as int,
        title = e.data()['title'] as String,
        synopsis = e.data()['synopsis'] as String?,
        instructions = e.data()['instructions'] as String,
        cover = e.data()['cover'] as String?,
        recapVideo = e.data()['recapVideo'] as String?,
        lessonVideo = e.data()['lessonVideo'] as String?,
        practiceVideo = e.data()['practiceVideo'] as String?,
        isLevel = e.data()['isLevel'] as bool,
        creatorId = e.data()['creatorId'] as String;

  Lesson.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()?['courseId'] as DocumentReference,
        levelId = e.data()?['levelId'] as DocumentReference?,
        sortOrder = e.data()?['sortOrder'] as int,
        title = e.data()?['title'] as String,
        synopsis = e.data()?['synopsis'] as String?,
        instructions = e.data()?['instructions'] as String,
        cover = e.data()?['cover'] as String?,
        recapVideo = e.data()?['recapVideo'] as String?,
        lessonVideo = e.data()?['lessonVideo'] as String?,
        practiceVideo = e.data()?['practiceVideo'] as String?,
        isLevel = e.data()?['isLevel'] as bool,
        creatorId = e.data()?['creatorId'] as String;

  Lesson.fromJson(Map<String, dynamic> json, String fullLevelId)
      : id = json['id'],
        courseId = FirebaseFirestore.instance.doc(json['courseId']),
        levelId =
            FirebaseFirestore.instance.doc(json['levelId'] ?? fullLevelId),
        sortOrder = -1,
        title = json['title'],
        synopsis = json['synopsis'],
        instructions = json['instructions'],
        cover = json['cover'],
        recapVideo = json['recapVideo'],
        lessonVideo = json['lessonVideo'],
        practiceVideo = json['practiceVideo'],
        isLevel = false,
        creatorId = '';
}
