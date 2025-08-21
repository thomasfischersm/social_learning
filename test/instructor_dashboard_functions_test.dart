import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/instructor_dashboard_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

Map<String, dynamic> buildUser(
  DocumentReference courseRef,
  String courseId,
  String sortName, {
  Timestamp? lastLessonTimestamp,
  double? proficiency,
  Timestamp? created,
}) {
  return {
    'uid': sortName,
    'displayName': sortName,
    'sortName': sortName,
    'profileText': '',
    'isAdmin': false,
    'isProfilePrivate': false,
    'isGeoLocationEnabled': false,
    'created': created ?? Timestamp.fromDate(DateTime.now()),
    'enrolledCourseIds': [courseRef],
    if (lastLessonTimestamp != null) 'lastLessonTimestamp': lastLessonTimestamp,
    if (proficiency != null) 'proficiency_$courseId': proficiency,
  };
}

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('getStudentCount returns number of enrolled users', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('users').add({'enrolledCourseIds': [courseRef]});
    await fake.collection('users').add({'enrolledCourseIds': [courseRef]});
    final count = await InstructorDashboardFunctions.getStudentCount('c1');
    expect(count, 2);
  });

  test('getStudentCount returns 0 when no users enrolled', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final count = await InstructorDashboardFunctions.getStudentCount('c1');
    expect(count, 0);
  });

  test('getLessonCount returns number of lessons for course', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('lessons').add({'courseId': courseRef});
    await fake.collection('lessons').add({'courseId': courseRef});
    await fake.collection('lessons').add({'courseId': courseRef});
    final count = await InstructorDashboardFunctions.getLessonCount('c1');
    expect(count, 3);
  });

  test('getSessionsTaughtCount excludes creator as mentee', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't', 'creatorId': 'creator'});
    final course = Course('c1', 't', 'creator', 'd', false, null);
    await fake
        .collection('practiceRecords')
        .add({'courseId': courseRef, 'menteeUid': 'student1'});
    await fake
        .collection('practiceRecords')
        .add({'courseId': courseRef, 'menteeUid': 'creator'});
    await fake
        .collection('practiceRecords')
        .add({'courseId': courseRef, 'menteeUid': 'student2'});
    final count = await InstructorDashboardFunctions.getSessionsTaughtCount(course);
    expect(count, 2);
  });

  test('getMostAdvancedStudent returns user when analytics and user exist',
      () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('users').doc('u1').set(buildUser(courseRef, 'c1', 'Alice'));
    await fake
        .collection('courseAnalytics')
        .doc('c1')
        .set({'topStudentId': 'u1'});
    final user =
        await InstructorDashboardFunctions.getMostAdvancedStudent('c1');
    expect(user?.id, 'u1');
  });

  test('getMostAdvancedStudent returns null when analytics missing', () async {
    final user =
        await InstructorDashboardFunctions.getMostAdvancedStudent('c1');
    expect(user, isNull);
  });

  test('getMostAdvancedStudent returns null when user missing', () async {
    await fake
        .collection('courseAnalytics')
        .doc('c1')
        .set({'topStudentId': 'u1'});
    final user =
        await InstructorDashboardFunctions.getMostAdvancedStudent('c1');
    expect(user, isNull);
  });

  test('getStudentPage sorts alphabetically and paginates', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('users').doc('u1').set(buildUser(courseRef, 'c1', 'Alice'));
    await fake.collection('users').doc('u2').set(buildUser(courseRef, 'c1', 'Bob'));
    await fake.collection('users').doc('u3').set(buildUser(courseRef, 'c1', 'Carl'));
    final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: 'c1', pageSize: 2);
    expect(page.students.map((u) => u.id).toList(), ['u1', 'u2']);
    expect(page.hasMore, true);
    expect(page.lastDoc?.id, 'u2');
  });

  test('getStudentPage applies name filter', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('users').doc('u1').set(buildUser(courseRef, 'c1', 'Alice'));
    await fake.collection('users').doc('u2').set(buildUser(courseRef, 'c1', 'Bob'));
    final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: 'c1', nameFilter: 'Ali');
    expect(page.students.length, 1);
    expect(page.students.first.id, 'u1');
    expect(page.hasMore, false);
  });

  test('getStudentPage sorts by recent activity', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final now = DateTime.now();
    await fake.collection('users').doc('u1').set(buildUser(
        courseRef, 'c1', 'Alice',
        lastLessonTimestamp: Timestamp.fromDate(now.subtract(const Duration(days: 1)))));
    await fake.collection('users').doc('u2').set(buildUser(
        courseRef, 'c1', 'Bob',
        lastLessonTimestamp: Timestamp.fromDate(now.subtract(const Duration(days: 3)))));
    final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: 'c1', sort: StudentSortOption.recent);
    expect(page.students.map((u) => u.id).toList(), ['u1', 'u2']);
  });

  test('getStudentPage sorts by advanced proficiency', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    await fake.collection('users').doc('u1').set(
        buildUser(courseRef, 'c1', 'Alice', proficiency: 0.5));
    await fake.collection('users').doc('u2').set(
        buildUser(courseRef, 'c1', 'Bob', proficiency: 0.8));
    final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: 'c1', sort: StudentSortOption.advanced);
    expect(page.students.map((u) => u.id).toList(), ['u2', 'u1']);
  });

  test('getStudentPage filters at-risk students', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final now = DateTime.now();
    final ten = Timestamp.fromDate(now.subtract(const Duration(days: 10)));
    final twenty = Timestamp.fromDate(now.subtract(const Duration(days: 20)));
    final forty = Timestamp.fromDate(now.subtract(const Duration(days: 40)));
    await fake.collection('users').doc('u1').set(
        buildUser(courseRef, 'c1', 'Alice', lastLessonTimestamp: ten));
    await fake.collection('users').doc('u2').set(
        buildUser(courseRef, 'c1', 'Bob', lastLessonTimestamp: twenty));
    await fake.collection('users').doc('u3').set(
        buildUser(courseRef, 'c1', 'Carl', lastLessonTimestamp: forty));
    final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: 'c1', sort: StudentSortOption.atRisk);
    expect(page.students.map((u) => u.id).toList(), ['u1', 'u2']);
  });
}
