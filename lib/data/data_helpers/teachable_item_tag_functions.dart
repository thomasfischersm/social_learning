import 'package:cloud_firestore/cloud_firestore.dart';

class TeachableItemTagFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItemTags';
  static const String _itemsCollectionPath = 'teachableItems';

  static Future<DocumentReference?> addTag({
    required String courseId,
    required String name,
    required String color,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final docRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'name': name,
        'color': color,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
    } catch (e) {
      print('Error adding tag: $e');
      return null;
    }
  }

  static Future<void> updateTag({
    required String tagId,
    required String name,
    required String color,
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(tagId).update({
        'name': name,
        'color': color,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating tag $tagId: $e');
    }
  }

  static Future<void> deleteTag({
    required String tagId,
  }) async {
    try {
      final tagRef = _firestore.collection(_collectionPath).doc(tagId);
      WriteBatch batch = _firestore.batch();

      // 1. Find all TeachableItems that reference this tag
      final itemsQuerySnapshot = await _firestore
          .collection(_itemsCollectionPath)
          .where('tagIds', arrayContains: tagRef)
          .get();

      // 2. For each item, remove the tagRef from its tagIds array
      for (var doc in itemsQuerySnapshot.docs) {
        batch.update(doc.reference, {
          'tagIds': FieldValue.arrayRemove([tagRef]),
          'modifiedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Delete the tag itself
      batch.delete(tagRef);

      await batch.commit();
    } catch (e) {
      print('Error deleting tag $tagId: $e');
    }
  }
}
