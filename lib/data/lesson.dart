import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  String? id;
  DocumentReference courseId;
  DocumentReference? levelId;
  int sortOrder;
  String title;
  String? synopsis;
  String instructions;
  @Deprecated('Use Level class instead')
  bool isLevel;
  String creatorId;

  Lesson(this.id, this.courseId, this.levelId, this.sortOrder, this.title,
      this.synopsis, this.instructions, this.isLevel, this.creatorId);

  Lesson.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        levelId = e.data()['levelId'] as DocumentReference?,
        sortOrder = e.data()['sortOrder'] as int,
        title = e.data()['title'] as String,
        synopsis = e.data()['synopsis'] as String?,
        instructions = e.data()['instructions'] as String,
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
        isLevel = e.data()?['isLevel'] as bool,
        creatorId = e.data()?['creatorId'] as String;

  Lesson.fromJson(Map<String, dynamic> json, String fullLevelId)
      : id = json['id'],
        courseId = FirebaseFirestore.instance.doc(json['courseId']),
        levelId = FirebaseFirestore.instance.doc(json['levelId'] ?? fullLevelId),
        sortOrder = -1,
        title = json['title'],
        synopsis = json['synopsis'],
        instructions = json['instructions'],
        isLevel = false,
        creatorId = '';
}
