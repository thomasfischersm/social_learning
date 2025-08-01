import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/learning_objective.dart';

class LearningObjectiveFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'learningObjectives';

  static Future<List<LearningObjective>> getObjectivesForCourse(
      String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();
      return snapshot.docs
          .map((doc) => LearningObjective.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading objectives: $e');
      return [];
    }
  }

  static Future<LearningObjective?> saveObjective({
    String? id,
    required String courseId,
    required int sortOrder,
    required String name,
    String? description,
    List<DocumentReference>? teachableItemIds,
  }) async {
    print(
        'LearningObjectiveFunctions: Saving objective: $id, courseId: $courseId, sortOrder: $sortOrder, name: $name, description: $description, teachableItemIds: $teachableItemIds');
    try {
      final courseRef = docRef('courses', courseId);
      final data = {
        'courseId': courseRef,
        'sortOrder': sortOrder,
        'name': name,
        'description': description,
        'teachableItemIds': teachableItemIds ?? [],
        'modifiedAt': FieldValue.serverTimestamp(),
      };
      if (id == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection(_collectionPath).add(data);
        final snapshot = await docRef.get();
        return LearningObjective.fromSnapshot(snapshot);
      } else {
        await docRef(_collectionPath, id).update(data);
        final snapshot = await docRef(_collectionPath, id).get();
        return LearningObjective.fromSnapshot(snapshot);
      }
    } catch (e) {
      print('Error saving objective: $e');
      return null;
    }
  }

  static Future<void> addTeachableItem({
    required String objectiveId,
    required DocumentReference teachableItemRef,
  }) async {
    try {
      await docRef(_collectionPath, objectiveId).update({
        'teachableItemIds': FieldValue.arrayUnion([teachableItemRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding teachable item: $e');
    }
  }

  static Future<void> removeTeachableItem({
    required String objectiveId,
    required DocumentReference teachableItemRef,
  }) async {
    try {
      await docRef(_collectionPath, objectiveId).update({
        'teachableItemIds': FieldValue.arrayRemove([teachableItemRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing teachable item: $e');
    }
  }

  static deleteObjective(LearningObjective objective) async {
    try {
      await docRef(_collectionPath, objective.id).delete();
    } catch (e) {
      print('Error deleting objective ${objective.id}: $e');
    }
  }

  static Future<LearningObjective> updateObjective(
      {required String id, required String name, String? description}) async {
    name = name.trim();
    description = description?.trim();

    var docRef = docRef(_collectionPath, id);
    await docRef.update({
        'name': name,
        'description': description,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    return LearningObjective.fromSnapshot(await docRef.get());
  }

  static Future<LearningObjective> addObjective(
      {required String courseId,
      required String name,
      required int sortOrder}) async {
    print(
        'Adding objective: courseId: $courseId, name: $name, sortOrder: $sortOrder');
    name = name.trim();
    final courseRef = docRef('courses', courseId);
    var docRef = await _firestore.collection(_collectionPath).add({
      'courseId': courseRef,
      'sortOrder': sortOrder,
      'name': name,
      'description': null,
      'teachableItemIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
    return LearningObjective.fromSnapshot(await docRef.get());
  }

  /// Adds a teachable item reference to the objective, then returns the updated objective.
  static Future<LearningObjective?> addItemToObjective({
    required String objectiveId,
    required String teachableItemId,
  }) async {
    final objRef = docRef(_collectionPath, objectiveId);
    final itemRef = docRef('teachableItems', teachableItemId);

    await objRef.update({
      'teachableItemRefs': FieldValue.arrayUnion([itemRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await objRef.get();
    if (!snapshot.exists) return null;
    return LearningObjective.fromSnapshot(snapshot);
  }

  /// Replaces one teachable item ref with another on the objective, then returns the updated objective.
  static Future<LearningObjective?> replaceItemInObjective({
    required String objectiveId,
    required String oldTeachableItemId,
    required String newTeachableItemId,
  }) async {
    final objRef = docRef(_collectionPath, objectiveId);
    final oldRef = docRef('teachableItems', oldTeachableItemId);
    final newRef = docRef('teachableItems', newTeachableItemId);

    final batch = _firestore.batch();
    batch.update(objRef, {
      'teachableItemRefs': FieldValue.arrayRemove([oldRef]),
    });
    batch.update(objRef, {
      'teachableItemRefs': FieldValue.arrayUnion([newRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    final snapshot = await objRef.get();
    if (!snapshot.exists) return null;
    return LearningObjective.fromSnapshot(snapshot);
  }

  static Future<LearningObjective?> removeItemFromObjective({
    required String objectiveId,
    required String teachableItemId,
  }) async {
    final objRef = docRef('learningObjectives', objectiveId);
    final itemRef = docRef('teachableItems', teachableItemId);

    await objRef.update({
      'teachableItemRefs': FieldValue.arrayRemove([itemRef]),
      'modifiedAt': FieldValue.serverTimestamp(),
    });

    final snap = await objRef.get();
    return snap.exists ? LearningObjective.fromSnapshot(snap) : null;
  }
}
