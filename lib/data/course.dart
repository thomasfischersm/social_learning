import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  String? id;
  String title;
  String description;
  String creatorId;
  bool isPrivate;
  String? invitationCode;

  Course(this.id, this.title, this.creatorId, this.description, this.isPrivate,
      this.invitationCode);

  Course.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        title = e.data()['title'] as String,
        creatorId = e.data()['creatorId'] as String,
        description = e.data()['description'] as String,
        isPrivate = e.data()['isPrivate'] as bool? ?? false,
        invitationCode = e.data()['invitationCode'] as String?;

  Course.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        title = doc.data()?['title'] as String,
        creatorId = doc.data()?['creatorId'] as String,
        description = doc.data()?['description'] as String,
        isPrivate = doc.data()?['isPrivate'] as bool? ?? false,
        invitationCode = doc.data()?['invitationCode'] as String?;
}
