import 'package:cloud_firestore/cloud_firestore.dart';

class SessionPlanBlock {
  final String? id;
  final DocumentReference courseId;
  final DocumentReference sessionPlanId;
  String? name;
  int sortOrder;
  final Timestamp created;
  final Timestamp modified;

  SessionPlanBlock({
    this.id,
    required this.courseId,
    required this.sessionPlanId,
    this.name,
    required this.sortOrder,
    required this.created,
    required this.modified,
  });

  factory SessionPlanBlock.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SessionPlanBlock(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      sessionPlanId: data['sessionPlanId'] as DocumentReference,
      name: data['name'] as String?,
      sortOrder: data['sortOrder'] as int,
      created: data['created'] as Timestamp,
      modified: data['modified'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'sessionPlanId': sessionPlanId,
      'name': name,
      'sortOrder': sortOrder,
      'created': created,
      'modified': modified,
    };
  }
}
