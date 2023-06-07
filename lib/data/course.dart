import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  String? id;
  String title;
  String description;
  String creatorId;

  Course(this.id, this.title, this.creatorId, this.description);

  Course.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        title = e.data()['title'] as String,
        creatorId = e.data()['creatorId'] as String,
        description = e.data()['description'] as String;
}
