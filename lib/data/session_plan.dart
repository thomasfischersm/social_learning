import 'package:cloud_firestore/cloud_firestore.dart';

class SessionPlan {
  final String? id;
  final DocumentReference courseId;
  final String name;
  final Timestamp created;
  final Timestamp modified;

  SessionPlan({
    this.id,
    required this.courseId,
    required this.name,
    required this.created,
    required this.modified,
  });

  factory SessionPlan.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SessionPlan(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      name: data['name'] as String,
      created: data['created'] as Timestamp,
      modified: data['modified'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      'created': created,
      'modified': modified,
    };
  }
}
