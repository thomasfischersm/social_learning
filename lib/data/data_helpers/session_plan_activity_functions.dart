import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';

import '../session_play_activity_type.dart';

class SessionPlanActivityFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'sessionPlanActivities';

  /// Create a new activity
  static Future<SessionPlanActivity?> create({
    required String courseId,
    required String sessionPlanId,
    required String sessionPlanBlockId,
    required SessionPlanActivityType activityType,
    String? lessonId,
    String? name,
    String? notes,
    int? overrideDuration,
    required int sortOrder,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final sessionPlanRef = docRef('sessionPlans', sessionPlanId);
      final blockRef = docRef('sessionPlanBlocks', sessionPlanBlockId);
      final lessonRef = lessonId != null ? docRef('lessons', lessonId) : null;

      final docRefActivity = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'sessionPlanId': sessionPlanRef,
        'sessionPlanBlockId': blockRef,
        'activityType': activityType.value,
        'lessonId': lessonRef,
        'name': name,
        'notes': notes,
        'overrideDuration': overrideDuration,
        'sortOrder': sortOrder,
        'created': FieldValue.serverTimestamp(),
        'modified': FieldValue.serverTimestamp(),
      });

      final snapshot = await docRefActivity.get();
      return snapshot.exists
          ? SessionPlanActivity.fromSnapshot(snapshot)
          : null;
    } catch (e) {
      print('Error creating session plan activity: $e');
      return null;
    }
  }

  /// Update fields of an activity and return the updated object
  static Future<SessionPlanActivity?> update({
    required String activityId,
    SessionPlanActivityType? activityType,
    String? name,
    String? notes,
    String? lessonId,
    int? overrideDuration,
    int? sortOrder,
  }) async {
    try {
      final doc = docRef(_collectionPath, activityId);

      final updates = <String, dynamic>{
        'modified': FieldValue.serverTimestamp(),
      };
      if (activityType != null) updates['activityType'] = activityType.value;
      if (name != null) updates['name'] = name;
      if (notes != null) updates['notes'] = notes;
      if (lessonId != null) {
        updates['lessonId'] = docRef('lessons', lessonId);
      }
      if (overrideDuration != null) {
        updates['overrideDuration'] = overrideDuration;
      }
      if (sortOrder != null) {
        updates['sortOrder'] = sortOrder;
      }

      await doc.update(updates);
      final updatedSnapshot = await doc.get();
      return updatedSnapshot.exists
          ? SessionPlanActivity.fromSnapshot(updatedSnapshot)
          : null;
    } catch (e) {
      print('Error updating session plan activity $activityId: $e');
      return null;
    }
  }

  /// Delete an activity
  static Future<void> delete(String activityId) async {
    try {
      await docRef(_collectionPath, activityId).delete();
    } catch (e) {
      print('Error deleting session plan activity: $e');
    }
  }

  /// Get activities by course
  static Future<List<SessionPlanActivity>> getByCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();

      return snapshot.docs
          .map((doc) => SessionPlanActivity.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plan activities by course: $e');
      return [];
    }
  }

  /// Get activities by session plan
  static Future<List<SessionPlanActivity>> getBySessionPlan(
      String sessionPlanId) async {
    try {
      final sessionPlanRef = docRef('sessionPlans', sessionPlanId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('sessionPlanId', isEqualTo: sessionPlanRef)
          .orderBy('sessionPlanBlockId')
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => SessionPlanActivity.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plan activities by session plan: $e');
      return [];
    }
  }

  /// Get activities by block
  static Future<List<SessionPlanActivity>> getByBlock(
      String sessionPlanBlockId) async {
    try {
      final blockRef = docRef('sessionPlanBlocks', sessionPlanBlockId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('sessionPlanBlockId', isEqualTo: blockRef)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => SessionPlanActivity.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plan activities by block: $e');
      return [];
    }
  }

  /// Get a single activity by ID
  static Future<SessionPlanActivity?> getById(String activityId) async {
    try {
      final snapshot = await docRef(_collectionPath, activityId).get();
      return snapshot.exists
          ? SessionPlanActivity.fromSnapshot(snapshot)
          : null;
    } catch (e) {
      print('Error fetching session plan activity by ID: $e');
      return null;
    }
  }

  static Future<void> updateSortOrdersAndBlockChanges(
      List<SessionPlanActivity> activities) async {
    final batch = _firestore.batch();

    for (final activity in activities) {
      if (activity.id == null) continue;

      final docRef = _firestore.collection(_collectionPath).doc(activity.id);
      batch.update(docRef, {
        'sortOrder': activity.sortOrder,
        'sessionPlanBlockId': activity.sessionPlanBlockId,
        'modified': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
