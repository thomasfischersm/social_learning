import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  String? id;
  DocumentReference courseId;
  String title;
  String description;
  int sortOrder;
  String creatorId;

  Level(this.id, this.courseId, this.title, this.description, this.sortOrder,
      this.creatorId);

  Level.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        title = e.data()['title'] as String,
        description = e.data()['description'] as String,
        sortOrder = e.data()['sortOrder'] as int,
        creatorId = e.data()['creatorId'] as String;

  Level.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()!['courseId'] as DocumentReference,
        title = e.data()?['title'] as String,
        description = e.data()?['description'] as String,
        sortOrder = e.data()?['sortOrder'] as int,
        creatorId = e.data()?['creatorId'] as String;

  Level.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        courseId = FirebaseFirestore.instance.doc(json['courseId']),
        title = json['title'] as String,
        description = json['description'] as String,
        sortOrder = -1,
        creatorId = '';
}
