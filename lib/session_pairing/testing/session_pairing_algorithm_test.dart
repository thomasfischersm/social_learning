import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';

import 'application_state_mock.dart';
import 'library_state_mock.dart';
import 'organizer_session_state_mock.dart';

class SessionPairingAlgorithmTest {
  void test() {
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
    // TODO:
  }

  void test2() {
    // Initiate mocks.
    ApplicationStateMock applicationState = ApplicationStateMock();
    LibraryStateMock libraryState = LibraryStateMock(10);
    OrganizerSessionStateMock organizerSessionState =
    OrganizerSessionStateMock(applicationState, libraryState);

    // Create test users.
    organizerSessionState.addTestUser('A', false, []);
    organizerSessionState.addTestUser('B', false, [libraryState.lessons![0]]);
    organizerSessionState.addTestUser('C', false, [libraryState.lessons![0], libraryState.lessons![1]]);
    organizerSessionState.addTestUser('D', false, [libraryState.lessons![0],libraryState.lessons![1],libraryState.lessons![2]]);

    // Try pairing
    SessionPairingAlgorithm algorithm = SessionPairingAlgorithm();
    PairedSession pairedSession = algorithm.generateNextSessionPairing(
        organizerSessionState, libraryState);

    // Output the result.
    print('***** Test Result ****');
    pairedSession.debugPrint();
    print('********************');

    // Evaluate the result.
    // TODO:
  }
}
