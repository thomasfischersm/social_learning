import 'package:cloud_firestore/cloud_firestore.dart';

class LearningObjective {
  final String? id;
  final DocumentReference courseId;
  final String name;
  final String? description;
  final List<DocumentReference> teachableItemRefs;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  LearningObjective({
    this.id,
    required this.courseId,
    required this.name,
    this.description,
    required this.teachableItemRefs,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory LearningObjective.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return LearningObjective(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      name: data['name'] as String,
      description: data['description'] as String?,
      teachableItemRefs: (data['teachableItemRefs'] as List<dynamic>)
          .map((ref) => ref as DocumentReference)
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      'description': description,
      'teachableItemRefs': teachableItemRefs,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}