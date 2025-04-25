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

  /// Fetches one page of students in [courseId], with cursor-based pagination,
  /// sorted according to [sort], and optionally filtered by name prefix.
  ///
  /// - [courseId]: the Firestore ID of the course.
  /// - [startAfterDoc]: if non-null, begins the page after this document (for pagination).
  /// - [pageSize]: how many students per page (default 20).
  /// - [sort]: which sort order to apply (defaults to alphabetical).
  /// - [nameFilter]: if non-null and ≥3 chars, filters to users whose sortName starts with this prefix.
  static Future<StudentPage> getStudentPage({
    required String courseId,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    int pageSize = 20,
    StudentSortOption sort = StudentSortOption.alphabetical,
    String? nameFilter,
  }) async {
    final courseRef = FirebaseFirestore.instance.doc('/courses/$courseId');
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('enrolledCourseIds', arrayContains: courseRef);

    // 1) Name-prefix filter
    if (nameFilter != null && nameFilter.length >= 3) {
      final start = nameFilter;
      final end = '$nameFilter\uf8ff';
      query = query
          .where('sortName', isGreaterThanOrEqualTo: start)
          .where('sortName', isLessThanOrEqualTo: end);
    }

    // 2) Sort order
    switch (sort) {
      case StudentSortOption.recent:
        query = query.orderBy('lastLessonTimestamp', descending: true);
        break;
      case StudentSortOption.advanced:
        query = query.orderBy('proficiency_$courseId', descending: true);
        break;
      case StudentSortOption.newest:
        query = query.orderBy('created', descending: true);
        break;
      case StudentSortOption.atRisk:
        final now = DateTime.now();
        final sevenDaysAgo =
            Timestamp.fromDate(now.subtract(const Duration(days: 7)));
        final thirtyDaysAgo =
            Timestamp.fromDate(now.subtract(const Duration(days: 30)));
        query = query
            .where('lastLessonTimestamp', isLessThanOrEqualTo: sevenDaysAgo)
            .where('lastLessonTimestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .orderBy('lastLessonTimestamp', descending: true);
        break;
      case StudentSortOption.alphabetical:
      default:
        query = query.orderBy('sortName');
    }

    // 3) Pagination cursor + fetch one extra to detect hasMore
    query = query.limit(pageSize + 1);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    // 4) Execute and map to StudentPage
    final snap = await query.get();
    final docs = snap.docs;
    final hasMore = docs.length == pageSize + 1;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;

    final students = pageDocs.map((doc) => User.fromSnapshot(doc)).toList();
    final lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;

    return StudentPage(
      students: students,
      lastDoc: lastDoc,
      hasMore: hasMore,
    );
  }
}

/// How to sort the student roster.
enum StudentSortOption {
  /// Most recently active students first (needs a `lastActivity` Timestamp on User).
  recent,

  /// Students with highest proficiency first (needs a course‐specific proficiency field).
  advanced,

  /// Students who most recently joined first (needs a `createdAt` Timestamp on User).
  newest,

  /// Students inactive 7–30 days ago (at‐risk), ordered by last activity ascending.
  atRisk,

  /// Alphabetical by sortName
  alphabetical,
}

/// A single "page" of students.
class StudentPage {
  final List<User> students;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  StudentPage({
    required this.students,
    required this.lastDoc,
    required this.hasMore,
  });
}
