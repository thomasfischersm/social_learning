import 'package:cloud_firestore/cloud_firestore.dart';

class SkillRubric {
  final String? id;
  final DocumentReference courseId;
  List<SkillDimension> dimensions;
  final Timestamp createdAt;
  Timestamp modifiedAt;

  SkillRubric({
    this.id,
    required this.courseId,
    required this.dimensions,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory SkillRubric.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SkillRubric(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      dimensions: (data['dimensions'] as List<dynamic>? ?? [])
          .map((e) => SkillDimension.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'dimensions': dimensions.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
        'modifiedAt': modifiedAt,
      };
}

class SkillDimension {
  final String id;
  String name;
  String? description;
  List<SkillDegree> degrees;

  SkillDimension({
    required this.id,
    required this.name,
    this.description,
    required this.degrees,
  });

  factory SkillDimension.fromMap(Map<String, dynamic> data) => SkillDimension(
        id: data['id'] as String,
        name: data['name'] as String,
        description: data['description'] as String?,
        degrees: (data['degrees'] as List<dynamic>? ?? [])
            .map((e) => SkillDegree.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'degrees': degrees.map((e) => e.toMap()).toList(),
      };
}

class SkillDegree {
  final String id;
  int degree;
  String name;
  String? description;
  List<DocumentReference> lessonRefs;

  SkillDegree({
    required this.id,
    required this.degree,
    required this.name,
    this.description,
    required this.lessonRefs,
  });

  factory SkillDegree.fromMap(Map<String, dynamic> data) => SkillDegree(
        id: data['id'] as String,
        degree: data['degree'] as int,
        name: data['name'] as String,
        description: data['description'] as String?,
        lessonRefs: (data['lessonRefs'] as List<dynamic>? ?? [])
            .map((ref) => ref as DocumentReference)
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'degree': degree,
        'name': name,
        'description': description,
        'lessonRefs': lessonRefs,
      };
}

