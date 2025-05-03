import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course_plan.dart';

class CoursePlanFunctions {
  static Future<String> createCoursePlan(
      DocumentReference courseRef, String planJson) async {
    final docRef = await CoursePlan.collection.add({
      'courseId': courseRef,
      'planJson': planJson,
      'created': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<CoursePlan?> getCoursePlanByCourse(
      DocumentReference courseRef) async {
    final snapshot = await CoursePlan.collection
        .where('courseId', isEqualTo: courseRef)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CoursePlan.fromSnapshot(snapshot.docs.first);
  }

  static Future<CoursePlan?> getCoursePlanById(String id) async {
    final doc = await CoursePlan.collection.doc(id).get();
    if (!doc.exists) return null;
    return CoursePlan.fromDocument(doc);
  }

  static Future<void> updatePlanJson(
      String coursePlanId, String updatedPlanJson) async {
    await CoursePlan.collection
        .doc(coursePlanId)
        .update({'planJson': updatedPlanJson});
  }

  static Future<void> storeGeneratedJson(
      String coursePlanId, String generatedJson) async {
    await CoursePlan.collection
        .doc(coursePlanId)
        .update({'generatedJson': generatedJson});
  }
}

