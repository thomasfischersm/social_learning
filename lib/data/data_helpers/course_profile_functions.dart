import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/util/print_util.dart';

class CourseProfileFunctions {
  // Use a getter so tests can override the Firestore instance via
  // [FirestoreService]. If this were a `final` field it would capture the
  // default instance at import time and ignore the test override, leading to
  // "not-found" errors when using [FakeFirebaseFirestore].
  static FirebaseFirestore get _firestore => FirestoreService.instance;
  static const String _collectionPath = 'courseProfiles';

  static Future<CourseProfile?> getCourseProfile(String courseId) async {
    dprint('Fetching course profile for courseId: $courseId');
    try {
      final courseRef = docRef('courses', courseId);
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        dprint('No course profile found for $courseId');
        return null;
      }
      dprint('Course profiles found: ${querySnapshot.docs.length} for course $courseId');
      return CourseProfile.fromSnapshot(querySnapshot.docs.first);
    } catch (e) {
      dprint('Error fetching course profile for $courseId: $e');
      return null;
    }
  }

  static Future<CourseProfile> saveCourseProfile(CourseProfile profile) async {
    try {
      final data = profile.toJson();

      if (profile.id != null) {
        // Update existing
        final dataToUpdate = {
          ...data,
          'modifiedAt': FieldValue.serverTimestamp(),
        };
        dataToUpdate.remove('createdAt');

        await docRef(_collectionPath, profile.id!).update(dataToUpdate);
        dprint('Course profile updated successfully.');
      } else {
        // Create new
        await _firestore.collection(_collectionPath).add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        dprint('Course profile created successfully.');
      }

      // Fetch the updated profile
      return (await getCourseProfile(profile.courseId.id))!;
    } catch (e) {
      dprint('Error saving course profile: $e');
      rethrow;
    }
  }
}
