import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/instructor_dashboard_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

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
}
