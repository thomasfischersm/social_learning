import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/fast/fast_session_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/testing/PairedSessionTester.dart';
import 'package:social_learning/session_pairing/testing/application_state_mock.dart';
import 'package:social_learning/session_pairing/testing/library_state_mock.dart';
import 'package:social_learning/session_pairing/testing/organizer_session_state_mock.dart';

class FastSessionPairingAlgorithmTest {
  void testAll() {
    test2BasicTwoStudent();
    test2BasicFourStudent();
    test2FourStudentFixRemaining();
    test2EightStudent();

    // testBasicTeacherStudent();
    // testBasic2Students();
    // testBasic4Students();
    // test4students1lesson();
    // testIgnoresInactiveParticipants();
  }

  void test2BasicTwoStudent() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);

    // Try pairing
    PairedSession pairedSession =
    FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('B', 'A', 'Lesson 1000')
        .go('T2 Basic 2-student test');
  }

  void test2BasicFourStudent() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]], learnCount: 1);
    organizerSessionState.addTestUser('C', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('D', false, [libraryState.lessons![0],libraryState.lessons![1]], learnCount: 1);

    // Try pairing
    PairedSession pairedSession =
    FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('D', 'C', 'Lesson 1001')
        .assertPair('B', 'A', 'Lesson 1000')
        .go('T2 Basic 4-student test');
  }

  void test2FourStudentFixRemaining() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]], teachCount: 1);
    organizerSessionState.addTestUser('C', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('D', false, [libraryState.lessons![0],libraryState.lessons![1]], teachCount: 1);

    // Try pairing
    PairedSession pairedSession =
    FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('D', 'B', 'Lesson 1001')
        .assertPair('C', 'A', 'Lesson 1000')
        .go('T2 4-student fix remaining');
  }


  void test2EightStudent() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, [libraryState.lessons![0],libraryState.lessons![1], libraryState.lessons![2], libraryState.lessons![3]]);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0],libraryState.lessons![1], libraryState.lessons![2]]);
    organizerSessionState.addTestUser('C', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('D', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('E', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('F', false, [], teachCount: 4);
    organizerSessionState.addTestUser('G', false, [], teachCount: 3);
    organizerSessionState.addTestUser('H', false, [], teachCount: 2);
    organizerSessionState.addTestUser('I', false, [], teachCount: 1);

    // Try pairing
    PairedSession pairedSession =
    FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('A', 'E', 'Lesson 1001')
        .assertPair('B', 'I', 'Lesson 1000')
        .assertPair('C', 'H', 'Lesson 1000')
        .assertPair('D', 'G', 'Lesson 1000')
        .assertUnpaired(['F'])
        .go('T2 8-student basic');
  }

  void testBasicTeacherStudent() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', true, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);

    // Try pairing
    PairedSession pairedSession =
        FastSessionPairingAlgorithm.generateNextSessionPairing(
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
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);

    // Try pairing
    PairedSession pairedSession = FastSessionPairingAlgorithm.generateNextSessionPairing(
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
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
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
    PairedSession pairedSession = FastSessionPairingAlgorithm.generateNextSessionPairing(
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
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('B', false, []);
    organizerSessionState.addTestUser('C', false, []);
    organizerSessionState.addTestUser('D', false, []);

    // Try pairing
    PairedSession pairedSession = FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('A', 'B', 'Lesson 1000')
        .assertUnpaired(['C', 'D']).go('4 students 1 lesson');
  }

  void testIgnoresInactiveParticipants() {
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10, applicationState);
    OrganizerSessionStateMock organizerSessionState =
        OrganizerSessionStateMock(applicationState, libraryState);

    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]],
        isActive: false);
    organizerSessionState.addTestUser(
        'C', false, [libraryState.lessons![0], libraryState.lessons![1]]);

    PairedSession pairedSession = FastSessionPairingAlgorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    PairedSessionTester(pairedSession, organizerSessionState)
        .assertPair('C', 'A', 'Lesson 1000')
        .go('inactive participants are ignored');
  }
}
