import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/cloud_functions/skill_rubric_generation_response.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
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

  test('replaceRubricForCourse includes lessons in degree description', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final generated = GeneratedSkillDimension(
      name: 'Dimension',
      description: '',
      degrees: [
        GeneratedSkillDegree(
          name: 'Degree 1',
          criteria: 'Criteria text',
          lessons: ['Exercise 1', 'Exercise 2'],
        ),
      ],
    );

    await SkillRubricsFunctions.replaceRubricForCourse(
      courseId: 'c1',
      generated: [generated],
    );

    final loaded = await SkillRubricsFunctions.loadForCourse('c1');
    final description = loaded!.dimensions.first.degrees.first.description;
    final exerciseText = ['Exercise 1', 'Exercise 2'].map((e) => '- $e').join('\n');
    final expected =
        ['Criteria text', exerciseText].where((s) => s.trim().isNotEmpty).join('\n\n');
    expect(description, expected);
  });
}
