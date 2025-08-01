import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';

class TeachableItemFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'teachableItems';

  static Future<TeachableItem?> addItem({
    required String courseId,
    required String categoryId,
    required String name,
    String? notes,
    int? durationInMinutes,
    TeachableItemInclusionStatus inclusionStatus =
        TeachableItemInclusionStatus.excluded,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final categoryRef =
          _firestore.collection('teachableItemCategories').doc(categoryId);

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
        'durationInMinutes': durationInMinutes,
        'inclusionStatus': inclusionStatus.toInt(),
        'lessonRefs': [],
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
  static Future<List<TeachableItem>> bulkCreateItems(List<TeachableItem> items) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection(_collectionPath);
    final docRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final item in items) {
      final docRef = collection.doc();
      docRefs.add(docRef);
      batch.set(docRef, {
        'courseId': item.courseId,
        'categoryId': item.categoryId,
        'name': item.name,
        'notes': item.notes,
        'sortOrder': item.sortOrder,
        'tagIds': item.tagIds ?? [],
        'durationInMinutes': item.durationInMinutes,
        'requiredPrerequisiteIds': item.requiredPrerequisiteIds ?? [],
        'recommendedPrerequisiteIds': item.recommendedPrerequisiteIds ?? [],
        'lessonRefs': item.lessonRefs ?? [],
        'inclusionStatus': item.inclusionStatus.toInt(),
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    final snapshots = await Future.wait(docRefs.map((d) => d.get()));
    return snapshots.where((s) => s.exists).map((s) => TeachableItem.fromSnapshot(s)).toList();
  }


  static Future<void> updateItem({
    required String itemId,
    required String name,
    String? notes,
    int? durationInMinutes,
    TeachableItemInclusionStatus? inclusionStatus,
    List<DocumentReference>? tagIds,
    List<DocumentReference>? lessonRefs,
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
      if (durationInMinutes != null) {
        dataToUpdate['durationInMinutes'] = durationInMinutes;
      }
      if (inclusionStatus != null) {
        dataToUpdate['inclusionStatus'] = inclusionStatus.toInt();
      }
      if (tagIds != null) {
        dataToUpdate['tagIds'] = tagIds;
      }
      if (lessonRefs != null) {
        dataToUpdate['lessonRefs'] = lessonRefs;
      }
      await _firestore
          .collection(_collectionPath)
          .doc(itemId)
          .update(dataToUpdate);
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
        durationInMinutes: movedItem.durationInMinutes,
        inclusionStatus: movedItem.inclusionStatus,
        tagIds: movedItem.tagIds,
        sortOrder: newIndex,
        requiredPrerequisiteIds: movedItem.requiredPrerequisiteIds,
        recommendedPrerequisiteIds: movedItem.recommendedPrerequisiteIds,
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
          final needsUpdate = item.sortOrder != i || item.id == movedItem.id;

          if (needsUpdate) {
            batch.update(docRef, {
              'sortOrder': i,
              'categoryId':
                  item.id == movedItem.id ? newCategoryRef : item.categoryId,
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
      final courseRef =
          FirebaseFirestore.instance.collection('courses').doc(courseId);

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

  static Future<TeachableItem?> getItemById(String itemId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionPath)
          .doc(itemId)
          .get();
      if (snapshot.exists) {
        return TeachableItem.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print('Error fetching item $itemId: $e');
      return null;
    }
  }

  static Future<TeachableItem?> addDependency({
    required TeachableItem target,
    required TeachableItem dependency,
    required bool required,
  }) async {
    try {
      final field =
          required ? 'requiredPrerequisiteIds' : 'recommendedPrerequisiteIds';
      final docRefItem = docRef(_collectionPath, target.id!);
      final prereqRef = docRef(_collectionPath, dependency.id!);

      await docRefItem.update({
        field: FieldValue.arrayUnion([prereqRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      final updatedSnapshot = await docRefItem.get();
      return updatedSnapshot.exists
          ? TeachableItem.fromSnapshot(updatedSnapshot)
          : null;
    } catch (e) {
      print('Error adding dependency to item ${target.id}: $e');
      return null;
    }
  }

  static Future<TeachableItem?> removeDependency({
    required TeachableItem target,
    required TeachableItem dependency,
  }) async {
    try {
      final docRefItem = docRef(_collectionPath, target.id!);
      final prereqRef = docRef(_collectionPath, dependency.id!);

      await docRefItem.update({
        'requiredPrerequisiteIds': FieldValue.arrayRemove([prereqRef]),
        'recommendedPrerequisiteIds': FieldValue.arrayRemove([prereqRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      final updatedSnapshot = await docRefItem.get();
      return updatedSnapshot.exists
          ? TeachableItem.fromSnapshot(updatedSnapshot)
          : null;
    } catch (e) {
      print('Error removing dependency from item ${target.id}: $e');
      return null;
    }
  }

  static Future<TeachableItem?> toggleDependency({
    required TeachableItem target,
    required TeachableItem dependency,
  }) async {
    try {
      final docRefItem = docRef(_collectionPath, target.id!);
      final prereqRef = docRef(_collectionPath, dependency.id!);

      final snapshot = await docRefItem.get();
      if (!snapshot.exists) return null;
      final current = TeachableItem.fromSnapshot(snapshot);

      final requiredList = current.requiredPrerequisiteIds ?? [];
      final recommendedList = current.recommendedPrerequisiteIds ?? [];

      final isRequired = requiredList.any((ref) => ref.id == dependency.id);
      final fromField =
          isRequired ? 'requiredPrerequisiteIds' : 'recommendedPrerequisiteIds';
      final toField =
          isRequired ? 'recommendedPrerequisiteIds' : 'requiredPrerequisiteIds';

      await docRefItem.update({
        fromField: FieldValue.arrayRemove([prereqRef]),
        toField: FieldValue.arrayUnion([prereqRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      final updatedSnapshot = await docRefItem.get();
      return updatedSnapshot.exists
          ? TeachableItem.fromSnapshot(updatedSnapshot)
          : null;
    } catch (e) {
      print('Error toggling dependency for item ${target.id}: $e');
      return null;
    }
  }

  static void updateInclusionStatuses(
      Set<TeachableItem> needToSelect, Set<TeachableItem> needToDeselect) {
    if (needToSelect.isEmpty && needToDeselect.isEmpty) {
      print('No items to update inclusion statuses for.');
      return;
    }

    final batch = _firestore.batch();

    for (final item in needToSelect) {
      final docRef = _firestore.collection(_collectionPath).doc(item.id);
      batch.update(docRef, {
        'inclusionStatus': item.inclusionStatus.toInt(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    }

    for (final item in needToDeselect) {
      final docRef = _firestore.collection(_collectionPath).doc(item.id);
      batch.update(docRef, {
        'inclusionStatus': TeachableItemInclusionStatus.excluded.toInt(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.commit().catchError((e) {
      print('Error updating inclusion statuses: $e');
    });
  }

  static updateInclusionStatus(TeachableItem item) async {
    final docRef = _firestore.collection(_collectionPath).doc(item.id);
    await docRef.update({
      'inclusionStatus': item.inclusionStatus.toInt(),
      'modifiedAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      print('Error updating inclusion status for item ${item.id}: $e');
    });
  }

  static Future<void> updateDurationOverride(
      TeachableItem item, int? newDurationOverride) async {
    final docRef = _firestore.collection(_collectionPath).doc(item.id);
    await docRef.update({
      'durationInMinutes': newDurationOverride,
      'modifiedAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      print('Error updating duration override for item ${item.id}: $e');
    });
  }

  /// Attach a lesson to the item's `lessonRefs` array and return the updated item.
  static Future<TeachableItem?> addLessonToTeachableItem({
    required String itemId,
    required String lessonId,
  }) async {
    final itemRef = docRef(_collectionPath, itemId);
    final lessonRef = docRef('lessons', lessonId);

    await itemRef.update({
      'lessonRefs': FieldValue.arrayUnion([lessonRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await itemRef.get();
    if (!snapshot.exists) return null;
    return TeachableItem.fromSnapshot(snapshot);
  }

  /// Atomically replace one lessonRef with another and return the updated item.
  static Future<TeachableItem?> replaceLessonOnItem({
    required String itemId,
    required String oldLessonId,
    required String newLessonId,
  }) async {
    final itemRef = docRef(_collectionPath, itemId);
    final oldRef = docRef('lessons', oldLessonId);
    final newRef = docRef('lessons', newLessonId);

    final batch = _firestore.batch();
    batch.update(itemRef, {
      'lessonRefs': FieldValue.arrayRemove([oldRef]),
    });
    batch.update(itemRef, {
      'lessonRefs': FieldValue.arrayUnion([newRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    final snapshot = await itemRef.get();
    if (!snapshot.exists) return null;
    return TeachableItem.fromSnapshot(snapshot);
  }

  /// Remove a lessonRef from the item and return the updated TeachableItem.
  static Future<TeachableItem?> removeLessonFromTeachableItem({
    required String itemId,
    required String lessonId,
  }) async {
    final itemRef = docRef(_collectionPath, itemId);
    final lessonRef = docRef('lessons', lessonId);

    // Remove the lesson from the array
    await itemRef.update({
      'lessonRefs': FieldValue.arrayRemove([lessonRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });

    // Fetch & return the fresh snapshot
    final snapshot = await itemRef.get();
    if (!snapshot.exists) return null;
    return TeachableItem.fromSnapshot(snapshot);
  }
}
