import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  String? id;
  String title;
  String description;
  int sortOrder;
  String creatorId;

  Level(this.id, this.title, this.description, this.sortOrder, this.creatorId);

  Level.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        title = e.data()['title'] as String,
        description = e.data()['description'] as String,
        sortOrder = e.data()['sortOrder'] as int,
        creatorId = e.data()['creatorId'] as String;
}
