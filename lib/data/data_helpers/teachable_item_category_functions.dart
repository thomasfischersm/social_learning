import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item_category.dart'; // For deleting items within a category
import 'package:social_learning/data/firestore_service.dart';

class TeachableItemCategoryFunctions {
  // Getter for Firestore so tests can override the instance.
  static FirebaseFirestore get _firestore => FirestoreService.instance;
  static const String _collectionPath = 'teachableItemCategories';
  static const String _itemsCollectionPath = 'teachableItems';

  static Future<TeachableItemCategory?> addCategory({
    required String courseId,
    required String name,
  }) async {
    try {
      print('Adding category: $name to course: $courseId');
      final courseRef = docRef('courses', courseId);

      // Get highest sortOrder for the course
      QuerySnapshot<Map<String, dynamic>>? querySnapshot;

      try {
        print('Querying for highest sortOrder for course: $courseId');
        querySnapshot = await _firestore
            .collection(_collectionPath)
            .where('courseId', isEqualTo: courseRef)
            .orderBy('sortOrder', descending: true)
            .limit(1)
            .get();
        print('Query successful, found ${querySnapshot.docs.length} categories.');
      } catch (e, stack) {
        print('Firestore query failed: $e');
        print('Stack trace:\n$stack');
        return null; // or handle it another way
      }

      final currentHighestSortOrder = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first.data()['sortOrder'] as int
          : -1;

      final newSortOrder = currentHighestSortOrder + 1;

      // Create new document
      print('Adding new category: $name with sortOrder: $newSortOrder');
      final categoryDocRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'name': name,
        'sortOrder': newSortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      print('Category added with ID: ${categoryDocRef.id}');

      final snapshot = await categoryDocRef.get();
      if (!snapshot.exists) return null;

      return TeachableItemCategory.fromSnapshot(snapshot);
    } catch (e) {
      print('Error adding category: $e');
      return null;
    }
  }
  static Future<List<TeachableItemCategory>> bulkCreateCategories({
    required String courseId,
    required List<String> names,
  }) async {
    final courseRef = docRef('courses', courseId);
    final batch = _firestore.batch();
    final collection = _firestore.collection(_collectionPath);
    final docRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (int i = 0; i < names.length; i++) {
      final docRef = collection.doc();
      docRefs.add(docRef);
      batch.set(docRef, {
        'courseId': courseRef,
        'name': names[i],
        'sortOrder': i,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    final snapshots = await Future.wait(docRefs.map((d) => d.get()));
    return snapshots.where((s) => s.exists).map((s) => TeachableItemCategory.fromSnapshot(s)).toList();
  }



  static Future<void> updateCategory({
    required String categoryId,
    required String name,
    // Description is not part of the model, so not included here.
  }) async {
    try {
      await docRef(_collectionPath, categoryId).update({
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
      final categoryRef = docRef(_collectionPath, categoryId);
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

  static Future<void> updateCategorySortOrder({
    required TeachableItemCategory movedCategory,
    required int newIndex,
    required List<TeachableItemCategory> allCategoriesForCourse,
  }) async {
    try {
      // Defensive copy and sort
      final sorted = [...allCategoriesForCourse]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final currentIndex = sorted.indexWhere((c) => c.id == movedCategory.id);
      if (currentIndex == -1 || currentIndex == newIndex) return;

      // Move in memory
      final moved = sorted.removeAt(currentIndex);
      sorted.insert(newIndex, moved);

      WriteBatch batch = _firestore.batch();

      for (int i = 0; i < sorted.length; i++) {
        final category = sorted[i];
        if (category.sortOrder != i) {
          final ref = docRef(_collectionPath, category.id!);
          batch.update(ref, {
            'sortOrder': i,
            'modifiedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error reordering categories: $e');
    }
  }

  static Future<List<TeachableItemCategory>> getCategoriesForCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);

      final snapshot = await FirestoreService.instance
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => TeachableItemCategory.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

}
