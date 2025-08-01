import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/teachable_item_tag.dart';

class TeachableItemTagFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItemTags';
  static const String _itemsCollectionPath = 'teachableItems';

  static Future<TeachableItemTag?> addTag({
    required String courseId,
    required String name,
    required String color,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);

      final docRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'name': name,
        'color': color,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      final snapshot = await docRef.get();
      return TeachableItemTag.fromSnapshot(snapshot as DocumentSnapshot<Map<String, dynamic>>);
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
      await docRef(_collectionPath, tagId).update({
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
      final tagRef = docRef(_collectionPath, tagId);
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

  static Future<List<TeachableItemTag>> getTagsForCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);

      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .orderBy('name') // Sort alphabetically by tag name
          .get();

      return querySnapshot.docs
          .map((doc) => TeachableItemTag.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching tags for course $courseId: $e');
      return [];
    }
  }

}
