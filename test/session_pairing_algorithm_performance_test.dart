import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/testing/application_state_mock.dart';
import 'package:social_learning/session_pairing/testing/library_state_mock.dart';
import 'package:social_learning/session_pairing/testing/organizer_session_state_mock.dart';

class SessionPairingAlgorithmPerformanceTest {
  final SessionPairingAlgorithm _algorithm = SessionPairingAlgorithm();

  void runForStudentCount(int studentCount) {
    final applicationState = ApplicationStateMock();
    final libraryState = LibraryStateMock(studentCount, applicationState);
    final organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    final List<Lesson> lessons = List<Lesson>.from(libraryState.lessons ?? []);
    final Lesson? graduatedLesson = lessons.isNotEmpty ? lessons.first : null;

    final int graduatedStudentCount = studentCount ~/ 2;
    for (int i = 0; i < studentCount; i++) {
      final hasGraduated = i < graduatedStudentCount;
      final graduatedLessons =
          (hasGraduated && graduatedLesson != null) ? [graduatedLesson] : <Lesson>[];
      organizerSessionState.addTestUser(
        'Student ${i + 1}',
        false,
        graduatedLessons,
      );
    }

    final stopwatch = Stopwatch()..start();
    final pairing =
        _algorithm.generateNextSessionPairing(organizerSessionState, libraryState);
    stopwatch.stop();

    expect(pairing, isNotNull);

    final elapsed = stopwatch.elapsed;
    final elapsedMicroseconds = elapsed.inMicroseconds;
    final elapsedMilliseconds = elapsed.inMilliseconds;
    print(
      'SessionPairingAlgorithm pairing with $studentCount students took '
      '${elapsedMilliseconds}ms (${elapsedMicroseconds}µs)',
    );
  }
}

late FakeFirebaseFirestore _fake;

void main() {
  setUp(() {
    _fake = FakeFirebaseFirestore();
    FirestoreService.instance = _fake;
  });

  final performanceTest = SessionPairingAlgorithmPerformanceTest();
  Map<int, int> runsToTime = {};

  for (int studentCount = 2; studentCount <= 12; studentCount++) {
    test(
        'SessionPairingAlgorithm performance with '
        '$studentCount students', () {
      final stopwatch = Stopwatch()..start();
      performanceTest.runForStudentCount(studentCount);
      stopwatch.stop();

      runsToTime[studentCount] = stopwatch.elapsed.inMilliseconds;
      print('Size of times: ${runsToTime.length}');

      List<int> keys = runsToTime.keys.toList()..sort();
      for (int key in keys) {
        print('Students: $key, Time: ${runsToTime[key]}s');
      }
      print('Done!');
    });
  }

}
