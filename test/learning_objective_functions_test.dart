import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = FirebaseFirestore.instance;
  });

  test('addObjective creates and fetches objective', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    final list = await LearningObjectiveFunctions.getObjectivesForCourse('c1');
    expect(list.first.name, 'obj');
    expect(obj.name, 'obj');
  });
}
