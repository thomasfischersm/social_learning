import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  var id;
  var title;
  var creatorId;

  Course(this.id, this.title, this.creatorId);

  Course.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e) {
    id = e.id;
    title = e.data()['title'] as String;
    creatorId = e.data()['creatorId'] as String;
  }
}
