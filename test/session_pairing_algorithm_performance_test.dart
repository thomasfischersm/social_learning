import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/testing/application_state_mock.dart';
import 'package:social_learning/session_pairing/testing/library_state_mock.dart';
import 'package:social_learning/session_pairing/testing/organizer_session_state_mock.dart';

class SessionPairingAlgorithmPerformanceTest {
  final SessionPairingAlgorithm _algorithm = SessionPairingAlgorithm();

  void runForStudentCount(int studentCount) {
    final applicationState = ApplicationStateMock();
    final libraryState = LibraryStateMock(studentCount);
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

void main() {
  final performanceTest = SessionPairingAlgorithmPerformanceTest();

  for (int studentCount = 2; studentCount <= 20; studentCount++) {
    test(
        'SessionPairingAlgorithm performance with '
        '$studentCount students', () {
      performanceTest.runForStudentCount(studentCount);
    });
  }
}
