import 'package:cloud_firestore/cloud_firestore.dart';

class TeachableItemTag {
  final String? id;
  final DocumentReference courseId;
  final String name;
  final String color;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  TeachableItemTag({
    this.id,
    required this.courseId,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory TeachableItemTag.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return TeachableItemTag(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      name: data['name'] as String,
      color: data['color'] as String,
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      'color': color,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
