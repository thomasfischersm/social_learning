import 'package:cloud_firestore/cloud_firestore.dart';

class TeachableItem {
  final String? id;
  final DocumentReference courseId;
  final DocumentReference categoryId;
  String? name;
  String? notes;
  final int sortOrder;
  final List<DocumentReference>? tagIds;
  final Timestamp createdAt;
  final Timestamp modifiedAt;

  TeachableItem({
    this.id,
    required this.courseId,
    required this.categoryId,
    required this.name,
    this.notes,
    required this.sortOrder,
    this.tagIds,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory TeachableItem.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return TeachableItem(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      categoryId: data['categoryId'] as DocumentReference,
      name: data['name'] as String,
      notes: data['notes'] as String?,
      sortOrder: data['sortOrder'] as int,
      tagIds: (data['tagIds'] as List<dynamic>?)
          ?.map((tagId) => tagId as DocumentReference)
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'categoryId': categoryId,
      'name': name,
      'notes': notes,
      'sortOrder': sortOrder,
      'tagIds': tagIds,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
