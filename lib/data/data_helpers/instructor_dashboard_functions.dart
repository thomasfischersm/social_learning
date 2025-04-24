import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';

/// Collection of helper functions for the Instructor Dashboard.
class InstructorDashboardFunctions {
  InstructorDashboardFunctions._(); // private constructor to prevent instantiation

  /// Returns the count of users enrolled in the given course.
  ///
  /// Uses Firestore aggregation query to get a server-side count.
  /// Returns null on error or if the count is unavailable.
  static Future<int?> getStudentCount(String courseId) async {
    try {
      final courseRef = FirebaseFirestore.instance.doc('/courses/$courseId');
      final agg = await FirebaseFirestore.instance
          .collection('users')
          .where('enrolledCourseIds', arrayContains: courseRef)
          .count()
          .get();
      return agg.count; // int? count
    } catch (e) {
      // log error if you have logging
      return null;
    }
  }

  /// Returns the count of lessons in the given course.
  /// Uses Firestore aggregation query to get a server-side count.
  /// Returns null on error or if the count is unavailable.
  static Future<int?> getLessonCount(String courseId) async {
    try {
      final courseRef = FirebaseFirestore.instance.doc('/courses/$courseId');
      final agg = await FirebaseFirestore.instance
          .collection('lessons')
          .where('courseId', isEqualTo: courseRef)
          .count()
          .get();
      return agg.count;
    } catch (e) {
      return null;
    }
  }

  /// Returns the count of practice sessions (lessons taught) in the given course.
  /// This counts all PracticeRecords for the course.
  /// Uses Firestore aggregation query. Returns null on error.
  static Future<int?> getSessionsTaughtCount(Course course) async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('courseId', isEqualTo: course.docRef)
          .where('menteeUid', isNotEqualTo: course.creatorId)
          .count()
          .get();
      return agg.count;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Returns the ID of the most advanced student for this course,
  /// or null if none has been recorded yet.
  static Future<String?> _getTopStudentId(String courseId) async {
    print('Fetching top student ID for course $courseId');
    try {
      final analyticsSnap = await FirebaseFirestore.instance
          .collection('courseAnalytics')
          .doc(courseId)
          .get();

      if (!analyticsSnap.exists) return null;
      return analyticsSnap.data()?['topStudentId'] as String?;
    } catch (e, stack) {
      print('Error fetching top student ID for course $courseId: $e');
      print(stack);
      return null;
    }
  }


  /// Fetches the full [User] object for the most advanced student,
  /// or null if there isn’t one yet.
  static Future<User?> getMostAdvancedStudent(String courseId) async {
    final topId = await _getTopStudentId(courseId);
    print('Top student ID: $topId');
    if (topId == null) {
      print('No top student ID found for course $courseId');
      return null;
    }

    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(topId).get();

    print('Got most advanced student: ${userSnap.data()}');
    return userSnap.exists ? User.fromSnapshot(userSnap) : null;
  }
}
