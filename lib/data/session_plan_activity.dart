import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_play_activity_type.dart';

class SessionPlanActivity {
  final String? id;
  final DocumentReference courseId;
  final DocumentReference sessionPlanId;
  DocumentReference sessionPlanBlockId;
  SessionPlanActivityType activityType;
  final DocumentReference? lessonId;
  String? name;
  String? notes;
  final int? overrideDuration;
  int sortOrder;
  final Timestamp created;
  final Timestamp modified;

  SessionPlanActivity({
    this.id,
    required this.courseId,
    required this.sessionPlanId,
    required this.sessionPlanBlockId,
    required this.activityType,
    this.lessonId,
    this.name,
    this.notes,
    this.overrideDuration,
    required this.sortOrder,
    required this.created,
    required this.modified,
  });

  factory SessionPlanActivity.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SessionPlanActivity(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      sessionPlanId: data['sessionPlanId'] as DocumentReference,
      sessionPlanBlockId: data['sessionPlanBlockId'] as DocumentReference,
      activityType: SessionPlanActivityTypeX.fromValue(
        data['activityType'] as int? ?? 0,
      ),
      lessonId: data['lessonId'] as DocumentReference?,
      name: data['name'] as String?,
      notes: data['notes'] as String?,
      overrideDuration: data['overrideDuration'] as int?,
      sortOrder: data['sortOrder'] as int,
      created: data['created'] as Timestamp,
      modified: data['modified'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'sessionPlanId': sessionPlanId,
      'sessionPlanBlockId': sessionPlanBlockId,
      'activityType': activityType.value,
      'lessonId': lessonId,
      'name': name,
      'notes': notes,
      'overrideDuration': overrideDuration,
      'sortOrder': sortOrder,
      'created': created,
      'modified': modified,
    };
  }
}
