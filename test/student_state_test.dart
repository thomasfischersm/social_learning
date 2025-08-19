import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';

class _FakeApplicationState extends ApplicationState {
  @override
  Future<void> init() async {}
}

void main() {
  test('getLessonStatus returns 3 when lesson taught', () {
    final fakeFirestore = FakeFirebaseFirestore();
    final appState = _FakeApplicationState();
    final libraryState = LibraryState(appState);
    final studentState = StudentState(appState, libraryState);

    final lessonRef = fakeFirestore.doc('lessons/l1');
    final courseRef = fakeFirestore.doc('courses/c1');
    final lesson = Lesson(
      'l1',
      courseRef,
      null,
      0,
      'title',
      null,
      'instructions',
      null,
      null,
      null,
      null,
      null,
      false,
      'creator',
      [],
    );

    final learnRecord = PracticeRecord(
      'r1',
      lessonRef,
      courseRef,
      'u1',
      'u2',
      true,
      null,
      null,
    );
    final teachRecord = PracticeRecord(
      'r2',
      lessonRef,
      courseRef,
      'u3',
      'u2',
      true,
      null,
      null,
    );

    studentState.setPracticeRecords(
      learnRecords: [learnRecord],
      teachRecords: [teachRecord],
    );

    expect(studentState.getLessonStatus(lesson), 3);
  });
}

