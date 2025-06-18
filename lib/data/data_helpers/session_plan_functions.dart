import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_plan.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';

class SessionPlanFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'sessionPlans';

  /// Create a new session plan
  static Future<SessionPlan?> create({
    required String courseId,
    required String name,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final docRefPlan = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'name': name,
        'created': FieldValue.serverTimestamp(),
        'modified': FieldValue.serverTimestamp(),
      });

      final snapshot = await docRefPlan.get();
      return snapshot.exists
          ? SessionPlan.fromSnapshot(snapshot)
          : null;
    } catch (e) {
      print('Error creating session plan: $e');
      return null;
    }
  }

  static Future<SessionPlan> getOrCreateSessionPlanForCourse(String courseId) async {
    final courseRef = docRef('courses', courseId);
    final query = await _firestore
        .collection(_collectionPath)
        .where('courseId', isEqualTo: courseRef)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return SessionPlan.fromSnapshot(query.docs.first);
    }

    // No plan exists yet — create a new one
    final docRefPlan = await _firestore.collection(_collectionPath).add({
      'courseId': courseRef,
      'name': 'Session Plan',
      'created': FieldValue.serverTimestamp(),
      'modified': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRefPlan.get();
    return SessionPlan.fromSnapshot(snapshot);
  }


  /// Update the name of an existing session plan and return the updated object
  static Future<SessionPlan?> updateSessionPlan({
    required String sessionPlanId,
    required String name,
  }) async {
    try {
      final doc = docRef(_collectionPath, sessionPlanId);

      await doc.update({
        'name': name,
        'modified': FieldValue.serverTimestamp(),
      });

      final updatedSnapshot = await doc.get();
      return updatedSnapshot.exists
          ? SessionPlan.fromSnapshot(updatedSnapshot)
          : null;
    } catch (e) {
      print('Error updating session plan $sessionPlanId: $e');
      return null;
    }
  }

  /// Delete a session plan by ID
  static Future<void> delete(String sessionPlanId) async {
    try {
      await docRef(_collectionPath, sessionPlanId).delete();
    } catch (e) {
      print('Error deleting session plan: $e');
    }
  }

  /// Get all session plans for a given course
  static Future<List<SessionPlan>> getByCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();

      return snapshot.docs
          .map((doc) => SessionPlan.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plans: $e');
      return [];
    }
  }

  /// Get a single session plan by ID
  static Future<SessionPlan?> getById(String sessionPlanId) async {
    try {
      final snapshot = await docRef(_collectionPath, sessionPlanId).get();
      return snapshot.exists
          ? SessionPlan.fromSnapshot(snapshot)
          : null;
    } catch (e) {
      print('Error fetching session plan by ID: $e');
      return null;
    }
  }
}
