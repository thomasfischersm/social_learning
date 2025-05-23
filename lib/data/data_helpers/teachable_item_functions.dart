import 'package:cloud_firestore/cloud_firestore.dart';

class TeachableItemFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItems';

  static Future<DocumentReference?> addItem({
    required String courseId,
    required String categoryId,
    required String name,
    String? notes,
    // sortOrder will be determined by counting existing items in the category
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final categoryRef =
          _firestore.collection('teachableItemCategories').doc(categoryId);

      // Determine sortOrder
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('categoryId', isEqualTo: categoryRef)
          .get();
      
      final currentHighestSortOrder = querySnapshot.docs.fold<int>(-1, (max, doc) {
        final data = doc.data();
        return data['sortOrder'] > max ? data['sortOrder'] : max;
      });
      final newSortOrder = currentHighestSortOrder + 1;

      final docRef = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'categoryId': categoryRef,
        'name': name,
        'notes': notes,
        'sortOrder': newSortOrder,
        'tagIds': [], // Initialize with an empty list
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
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

  static Future<void> batchUpdateItemSortOrder(
      List<Map<String, dynamic>> itemsToUpdate) async {
    if (itemsToUpdate.isEmpty) {
      return;
    }
    try {
      WriteBatch batch = _firestore.batch();
      for (var itemData in itemsToUpdate) {
        final docRef = _firestore.collection(_collectionPath).doc(itemData['id']);
        Map<String, dynamic> updatePayload = {
          'sortOrder': itemData['sortOrder'],
          'modifiedAt': FieldValue.serverTimestamp(),
        };
        if (itemData.containsKey('categoryId')) {
           updatePayload['categoryId'] = _firestore.collection('teachableItemCategories').doc(itemData['categoryId']);
        }
        batch.update(docRef, updatePayload);
      }
      await batch.commit();
    } catch (e) {
      print('Error in batchUpdateItemSortOrder: $e');
    }
  }
}
