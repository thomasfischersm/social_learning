import 'package:social_learning/session_pairing/paired_session.dart';
import 'organizer_session_state_mock.dart';

/// Tests that the pairing algorithm created the right kind of PairedSession.
///
/// Usage example:
///   testPairedSession()
///     .assertPair('A', 'B', '1000')
///     .assertPair('C', 'D', '1002')
//      .assertUnpaired(null)
//      .go();
class PairedSessionTester {
  final PairedSession _pairedSession;
  final OrganizerSessionStateMock _organizerSessionState;

  final List<ExpectedPair> _expectedPairs = [];
  final List<String> _unpairedParticipants = [];

  PairedSessionTester(this._pairedSession, this._organizerSessionState);

  PairedSessionTester assertPair(
      String mentorName, String learnerName, String lessonName) {
    _expectedPairs.add(ExpectedPair(mentorName, learnerName, lessonName));
    return this;
  }

  PairedSessionTester assertUnpaired(List<String> participantNames) {
    _unpairedParticipants.addAll(participantNames);
    return this;
  }

  bool go(String testName) {
    bool success = true;

    // Quick count tests.
    if (_pairedSession.pairs.length != _expectedPairs.length) {
      print(
          'Expected ${_expectedPairs.length} pairs but got ${_pairedSession.pairs.length}');
      success = false;
    }

    if (_pairedSession.unpairedParticipants.length !=
        _unpairedParticipants.length) {
      print(
          'Expected ${_unpairedParticipants.length} unpaired participants but got ${_pairedSession.unpairedParticipants.length}');
      success = false;
    }

    // Check the pairings.
    for (var pair in _pairedSession.pairs) {
      var mentor = _organizerSessionState.getUser(pair.teachingParticipant);
      var learner = _organizerSessionState.getUser(pair.learningParticipant);
      var lesson = pair.lesson;
      var expectedPair = _expectedPairs.removeAt(0);
      if (mentor?.displayName != expectedPair._mentorDisplayName ||
          learner?.displayName != expectedPair._learnerDisplayName ||
          lesson?.title != expectedPair._lessonTitle) {
        print(
            'Expected pair ${expectedPair._mentorDisplayName} -> ${expectedPair._learnerDisplayName} -> ${expectedPair._lessonTitle} but got ${mentor?.displayName} -> ${learner?.displayName} -> ${lesson?.title}');
        success = false;
      }
    }

    // Check the unpaired participants.
    for (var participantName in _unpairedParticipants) {
      var participant =
          _organizerSessionState.getUserByDisplayName(participantName);
      if (!_pairedSession.unpairedParticipants
          .any((p) => p.participantId.id == participant!.id)) {
        print(
            'Expected participant $participantName to be unpaired but was paired');
        success = false;
      }
    }

    if (success) {
      print('+++ $testName: Success +++');
    } else {
      print('!!! $testName: Failed !!!');
    }

    return success;
  }
}

class ExpectedPair {
  final String _mentorDisplayName;
  final String _learnerDisplayName;
  final String _lessonTitle;

  ExpectedPair(
      this._mentorDisplayName, this._learnerDisplayName, this._lessonTitle);
}
