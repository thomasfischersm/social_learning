import 'package:cloud_firestore/cloud_firestore.dart';

class SkillAssessment {
  final String? id;
  final DocumentReference courseId;
  final String studentUid;
  final String instructorUid;
  final String? notes;
  final List<SkillAssessmentDimension> dimensions;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  SkillAssessment({
    this.id,
    required this.courseId,
    required this.studentUid,
    required this.instructorUid,
    this.notes,
    required this.dimensions,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory SkillAssessment.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SkillAssessment(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      studentUid: data['studentUid'] as String,
      instructorUid: data['instructorUid'] as String,
      notes: data['notes'] as String?,
      dimensions: (data['dimensions'] as List<dynamic>? ?? [])
          .map((e) =>
              SkillAssessmentDimension.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'studentUid': studentUid,
        'instructorUid': instructorUid,
        'notes': notes,
        'dimensions': dimensions.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
        'modifiedAt': modifiedAt,
      };
}

class SkillAssessmentDimension {
  final String id;
  final String name;
  final int degree;
  final int maxDegrees;

  SkillAssessmentDimension({
    required this.id,
    required this.name,
    required this.degree,
    required this.maxDegrees,
  });

  factory SkillAssessmentDimension.fromMap(Map<String, dynamic> data) =>
      SkillAssessmentDimension(
        id: data['id'] as String,
        name: data['name'] as String,
        degree: data['degree'] as int,
        maxDegrees: data['maxDegrees'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'degree': degree,
        'maxDegrees': maxDegrees,
      };
}

