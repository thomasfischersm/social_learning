import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  String id;
  DocumentReference courseId;
  int sortOrder;
  String title;
  String instructions;
  bool isLevel;
  String creatorId;

  Lesson(this.id, this.courseId, this.sortOrder, this.title, this.instructions,
      this.isLevel, this.creatorId);

  Lesson.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        sortOrder = e.data()['sortOrder'] as int,
        title = e.data()['title'] as String,
        instructions = e.data()['instructions'] as String,
        isLevel = e.data()['isLevel'] as bool,
        creatorId = e.data()['creatorId'] as String ;
}
