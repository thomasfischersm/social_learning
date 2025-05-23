import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart'; // For deleting items within a category

class TeachableItemCategoryFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItemCategories';
  static const String _itemsCollectionPath = 'teachableItems';

  static Future<DocumentReference?> addCategory({
    required String courseId,
    required String name,
    // sortOrder will be determined by counting existing categories for the course
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);

      // Determine sortOrder
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();
      final currentHighestSortOrder = querySnapshot.docs.fold<int>(-1, (max, doc) {
        final data = doc.data();
        return data['sortOrder'] > max ? data['sortOrder'] : max;
      });
      final newSortOrder = currentHighestSortOrder + 1;

      final docRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'name': name,
        'sortOrder': newSortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
    } catch (e) {
      print('Error adding category: $e');
      return null;
    }
  }

  static Future<void> updateCategory({
    required String categoryId,
    required String name,
    // Description is not part of the model, so not included here.
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(categoryId).update({
        'name': name,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating category $categoryId: $e');
      // Consider re-throwing or returning a boolean for success/failure
    }
  }

  static Future<void> deleteCategory({
    required String categoryId,
  }) async {
    try {
      final categoryRef = _firestore.collection(_collectionPath).doc(categoryId);
      final categorySnapshot = await categoryRef.get();
      if (!categorySnapshot.exists) {
        print('Category $categoryId not found for deletion.');
        return;
      }
      final categoryData = categorySnapshot.data();
      final courseRef = categoryData?['courseId'] as DocumentReference?;
      final deletedSortOrder = categoryData?['sortOrder'] as int?;


      WriteBatch batch = _firestore.batch();

      // 1. Delete all TeachableItems within this category
      final itemsQuerySnapshot = await _firestore
          .collection(_itemsCollectionPath)
          .where('categoryId', isEqualTo: categoryRef)
          .get();

      for (var doc in itemsQuerySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete the category itself
      batch.delete(categoryRef);

      // 3. Re-sort subsequent categories for the same course
      if (courseRef != null && deletedSortOrder != null) {
        final subsequentCategoriesSnapshot = await _firestore
            .collection(_collectionPath)
            .where('courseId', isEqualTo: courseRef)
            .where('sortOrder', isGreaterThan: deletedSortOrder)
            .get();

        for (var doc in subsequentCategoriesSnapshot.docs) {
          batch.update(doc.reference, {'sortOrder': FieldValue.increment(-1)});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting category $categoryId: $e');
      // Consider re-throwing or returning a boolean for success/failure
    }
  }
}
