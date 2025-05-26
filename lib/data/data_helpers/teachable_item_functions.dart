import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/teachable_item.dart';

class TeachableItemFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItems';

  static Future<TeachableItem?> addItem({
    required String courseId,
    required String categoryId,
    required String name,
    String? notes,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final categoryRef = _firestore.collection('teachableItemCategories').doc(categoryId);

      // Determine next sortOrder
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('categoryId', isEqualTo: categoryRef)
          .orderBy('sortOrder', descending: true)
          .limit(1)
          .get();

      final currentHighestSortOrder = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first.data()['sortOrder'] as int
          : -1;

      final newSortOrder = currentHighestSortOrder + 1;

      // Create document
      final docRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'categoryId': categoryRef,
        'name': name,
        'notes': notes,
        'sortOrder': newSortOrder,
        'tagIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      // Fetch and parse snapshot
      final snapshot = await docRef.get();
      if (!snapshot.exists) return null;

      return TeachableItem.fromSnapshot(snapshot);
    } catch (e) {
      print('Error adding item: $e');
      return null;
    }
  }

  static Future<void> updateItem({
    required String itemId,
    required String name,
    String? notes,
    List<DocumentReference>? tagIds,
    // categoryId and sortOrder are handled by batchUpdateItemSortOrder
  }) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'name': name,
        'modifiedAt': FieldValue.serverTimestamp(),
      };
      if (notes != null) {
        dataToUpdate['notes'] = notes;
      }
      if (tagIds != null) {
        dataToUpdate['tagIds'] = tagIds;
      }
      await _firestore.collection(_collectionPath).doc(itemId).update(dataToUpdate);
    } catch (e) {
      print('Error updating item $itemId: $e');
    }
  }

  static Future<void> deleteItem({required String itemId}) async {
    try {
      final itemRef = _firestore.collection(_collectionPath).doc(itemId);
      final itemSnapshot = await itemRef.get();
      if (!itemSnapshot.exists) {
        print('Item $itemId not found for deletion.');
        return;
      }
      final itemData = itemSnapshot.data();
      final categoryRef = itemData?['categoryId'] as DocumentReference?;
      final deletedSortOrder = itemData?['sortOrder'] as int?;

      WriteBatch batch = _firestore.batch();
      batch.delete(itemRef);

      // Re-sort subsequent items in the same category
      if (categoryRef != null && deletedSortOrder != null) {
        final subsequentItemsSnapshot = await _firestore
            .collection(_collectionPath)
            .where('categoryId', isEqualTo: categoryRef)
            .where('sortOrder', isGreaterThan: deletedSortOrder)
            .get();

        for (var doc in subsequentItemsSnapshot.docs) {
          batch.update(doc.reference, {'sortOrder': FieldValue.increment(-1)});
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting item $itemId: $e');
    }
  }

  static Future<void> assignTagToItem({
    required String itemId,
    required DocumentReference tagRef,
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(itemId).update({
        'tagIds': FieldValue.arrayUnion([tagRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning tag to item $itemId: $e');
    }
  }

  static Future<void> removeItemTagFromItem({
    required String itemId,
    required DocumentReference tagRef,
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(itemId).update({
        'tagIds': FieldValue.arrayRemove([tagRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing tag from item $itemId: $e');
    }
  }

  static Future<void> updateItemSortOrder({
    required List<TeachableItem> allItemsAcrossCategories,
    required TeachableItem movedItem,
    required DocumentReference newCategoryRef,
    required int newIndex,
  }) async {
    try {
      final sourceCategoryRef = movedItem.categoryId;
      final isSameCategory = sourceCategoryRef.path == newCategoryRef.path;

      // Clone lists grouped by category
      final sourceList = allItemsAcrossCategories
          .where((item) => item.categoryId.path == sourceCategoryRef.path)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final destinationList = isSameCategory
          ? sourceList
          : allItemsAcrossCategories
          .where((item) => item.categoryId.path == newCategoryRef.path)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Move the item
      final movedCopy = TeachableItem(
        id: movedItem.id,
        courseId: movedItem.courseId,
        categoryId: newCategoryRef,
        name: movedItem.name,
        notes: movedItem.notes,
        tagIds: movedItem.tagIds,
        sortOrder: newIndex, // placeholder; will be updated in loop
        createdAt: movedItem.createdAt,
        modifiedAt: movedItem.modifiedAt,
      );

      if (isSameCategory) {
        final currentIndex =
        sourceList.indexWhere((item) => item.id == movedItem.id);
        if (currentIndex == -1 || currentIndex == newIndex) return;

        final updatedList = [...sourceList];
        final moved = updatedList.removeAt(currentIndex);
        updatedList.insert(newIndex, moved);

        WriteBatch batch = _firestore.batch();

        for (int i = 0; i < updatedList.length; i++) {
          final item = updatedList[i];
          if (item.sortOrder != i) {
            batch.update(
              _firestore.collection(_collectionPath).doc(item.id),
              {
                'sortOrder': i,
                'modifiedAt': FieldValue.serverTimestamp(),
              },
            );
          }
        }

        await batch.commit();
      } else {
        // Cross-category move
        final updatedSource = [...sourceList]
          ..removeWhere((item) => item.id == movedItem.id);

        final updatedDestination = [...destinationList]
          ..insert(newIndex, movedCopy);

        WriteBatch batch = _firestore.batch();

        // Reindex source category
        for (int i = 0; i < updatedSource.length; i++) {
          final item = updatedSource[i];
          if (item.sortOrder != i) {
            batch.update(
              _firestore.collection(_collectionPath).doc(item.id),
              {
                'sortOrder': i,
                'modifiedAt': FieldValue.serverTimestamp(),
              },
            );
          }
        }

        // Reindex destination category (including the moved item)
        for (int i = 0; i < updatedDestination.length; i++) {
          final item = updatedDestination[i];
          final docRef = _firestore.collection(_collectionPath).doc(item.id);
          final needsUpdate =
              item.sortOrder != i || item.id == movedItem.id;

          if (needsUpdate) {
            batch.update(docRef, {
              'sortOrder': i,
              'categoryId': item.id == movedItem.id ? newCategoryRef : item.categoryId,
              'modifiedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error reordering items: $e');
    }
  }

  static Future<List<TeachableItem>> getItemsForCourse(String courseId) async {
    try {
      final courseRef = FirebaseFirestore.instance.collection('courses').doc(courseId);

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();

      return snapshot.docs
          .map((doc) => TeachableItem.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading items: $e');
      return [];
    }
  }
}
