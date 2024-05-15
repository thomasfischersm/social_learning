import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';

import 'application_state_mock.dart';
import 'library_state_mock.dart';
import 'organizer_session_state_mock.dart';
import 'PairedSessionTester.dart';

class SessionPairingAlgorithmTest {
  void testAll() {
    testBasicTeacherStudent();
    testBasic2Students();
    testBasic4Students();
    test4students1lesson();
  }

  void testBasicTeacherStudent() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', true, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);

    // Try pairing
    SessionPairingAlgorithm algorithm = SessionPairingAlgorithm();
    PairedSession pairedSession = algorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('A', 'B', 'Lesson 1001')
        .go('Instructor teaching student test');
  }


  void testBasic2Students() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);

    // Try pairing
    SessionPairingAlgorithm algorithm = SessionPairingAlgorithm();
    PairedSession pairedSession = algorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('B', 'A', 'Lesson 1000')
        .go('Basic 2-student test');
  }

  void testBasic4Students() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser(
        'C', false, [libraryState.lessons![0], libraryState.lessons![1]]);
    organizerSessionState.addTestUser('D', false, [
      libraryState.lessons![0],
      libraryState.lessons![1],
      libraryState.lessons![2]
    ]);

    // Try pairing
    SessionPairingAlgorithm algorithm = SessionPairingAlgorithm();
    PairedSession pairedSession = algorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('B', 'A', 'Lesson 1000')
        .assertPair('D', 'C', 'Lesson 1002')
        .go('Basic 4-student test');
  }


  void test4students1lesson() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('B', false, []);
    organizerSessionState.addTestUser('C', false, []);
    organizerSessionState.addTestUser('D', false, []);

    // Try pairing
    SessionPairingAlgorithm algorithm = SessionPairingAlgorithm();
    PairedSession pairedSession = algorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('A', 'B', 'Lesson 1000')
        .assertUnpaired(['C', 'D'])
        .go('4 students 1 lesson');
  }
}
