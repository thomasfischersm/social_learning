import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/skill_assessment.dart';

class SkillAssessmentFunctions {
  static FirebaseFirestore get _firestore => FirestoreService.instance;
  static const String _collectionPath = 'skillAssessments';

  static Future<SkillAssessment?> create({
    required String courseId,
    required String studentUid,
    required String instructorUid,
    String? notes,
    required List<SkillAssessmentDimension> dimensions,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final docRefAssessment = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'studentUid': studentUid,
        'instructorUid': instructorUid,
        'notes': notes,
        'dimensions': dimensions.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await docRefAssessment.get();
      return SkillAssessment.fromSnapshot(snapshot);
    } catch (e) {
      print('Error creating skill assessment: $e');
      return null;
    }
  }

  static Future<SkillAssessment?> latestForUser({
    required String courseId,
    required String studentUid,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return SkillAssessment.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      print('Error fetching latest skill assessment: $e');
      return null;
    }
  }

  static Future<List<SkillAssessment>> allForUser({
    required String courseId,
    required String studentUid,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SkillAssessment.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading skill assessments: $e');
      return [];
    }
  }
}

