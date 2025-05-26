import 'package:cloud_firestore/cloud_firestore.dart';

class TeachableItemCategory {
  final String? id;
  final DocumentReference courseId;
  String name;
  final int sortOrder;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  TeachableItemCategory({
    this.id,
    required this.courseId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory TeachableItemCategory.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return TeachableItemCategory(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      name: data['name'] as String,
      sortOrder: data['sortOrder'] as int,
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
