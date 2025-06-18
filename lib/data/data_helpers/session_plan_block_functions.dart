import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_plan_block.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';

class SessionPlanBlockFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'sessionPlanBlocks';

  /// Create a new block under a session plan
  static Future<SessionPlanBlock?> create({
    required String courseId,
    required String sessionPlanId,
    String? name,
    required int sortOrder,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final sessionPlanRef = docRef('sessionPlans', sessionPlanId);

      final docRefBlock = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'sessionPlanId': sessionPlanRef,
        'name': name,
        'sortOrder': sortOrder,
        'created': FieldValue.serverTimestamp(),
        'modified': FieldValue.serverTimestamp(),
      });

      final snapshot = await docRefBlock.get();
      return snapshot.exists ? SessionPlanBlock.fromSnapshot(snapshot) : null;
    } catch (e) {
      print('Error creating session plan block: $e');
      return null;
    }
  }

  /// Update block name or sortOrder and return updated block
  static Future<SessionPlanBlock?> update({
    required String blockId,
    String? name,
    int? sortOrder,
  }) async {
    try {
      final doc = docRef(_collectionPath, blockId);
      final Map<String, dynamic> updates = {
        'modified': FieldValue.serverTimestamp(),
      };
      if (name != null) updates['name'] = name;
      if (sortOrder != null) updates['sortOrder'] = sortOrder;

      await doc.update(updates);
      final snapshot = await doc.get();
      return snapshot.exists ? SessionPlanBlock.fromSnapshot(snapshot) : null;
    } catch (e) {
      print('Error updating session plan block $blockId: $e');
      return null;
    }
  }

  /// Delete a block
  static Future<void> delete(String blockId) async {
    try {
      await docRef(_collectionPath, blockId).delete();
    } catch (e) {
      print('Error deleting session plan block: $e');
    }
  }

  /// Get blocks by courseId
  static Future<List<SessionPlanBlock>> getByCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .get();

      return snapshot.docs
          .map((doc) => SessionPlanBlock.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plan blocks by course: $e');
      return [];
    }
  }

  /// Get blocks by sessionPlanId
  static Future<List<SessionPlanBlock>> getBySessionPlan(
      String sessionPlanId) async {
    try {
      final sessionPlanRef = docRef('sessionPlans', sessionPlanId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('sessionPlanId', isEqualTo: sessionPlanRef)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => SessionPlanBlock.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching session plan blocks by session plan: $e');
      return [];
    }
  }

  /// Get single block by ID
  static Future<SessionPlanBlock?> getById(String blockId) async {
    try {
      final snapshot = await docRef(_collectionPath, blockId).get();
      return snapshot.exists ? SessionPlanBlock.fromSnapshot(snapshot) : null;
    } catch (e) {
      print('Error fetching session plan block by ID: $e');
      return null;
    }
  }

  static Future<void> batchUpdateSortOrders(
      List<SessionPlanBlock> blocksToUpdate) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var block in blocksToUpdate) {
      if (block.id == null) continue;
      final ref = docRef(_collectionPath, block.id!);
      batch.update(ref, {'sortOrder': block.sortOrder});
    }

    await batch.commit();
  }
}
