import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  String? id;
  DocumentReference courseId;
  String title;
  String description;
  int sortOrder;
  String creatorId;

  Level(this.id, this.courseId, this.title, this.description, this.sortOrder, this.creatorId);

  Level.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        title = e.data()['title'] as String,
        description = e.data()['description'] as String,
        sortOrder = e.data()['sortOrder'] as int,
        creatorId = e.data()['creatorId'] as String;
}
