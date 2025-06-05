import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/learning_objective.dart';

class LearningObjectiveFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'learningObjectives';

  static Future<List<LearningObjective>> getObjectivesForCourse(String courseId) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
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
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
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
        await _firestore.collection(_collectionPath).doc(id).update(data);
        final snapshot = await _firestore.collection(_collectionPath).doc(id).get();
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
      await _firestore.collection(_collectionPath).doc(objectiveId).update({
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
      await _firestore.collection(_collectionPath).doc(objectiveId).update({
        'teachableItemIds': FieldValue.arrayRemove([teachableItemRef]),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing teachable item: $e');
    }
  }
}