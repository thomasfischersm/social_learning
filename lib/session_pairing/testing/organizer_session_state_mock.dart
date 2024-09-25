import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/learning_strategy_enum.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class OrganizerSessionStateMock extends OrganizerSessionState {
  final List<SessionParticipant> _sessionParticipants = [];
  final List<User> _participantUsers = [];
  final Map<SessionParticipant, List<Lesson>> _graduatedLessons = {};
  final _course = Course(
      '/courses/malta', 'Malta', 'u58', 'A beautiful island', false, null);
  final _courseRef = FirebaseFirestore.instance.doc('/courses/malta');

  int _uniqueIdGenerator = 2;

  String get nextId => '${_uniqueIdGenerator++}';
  final String _sessionId = '1';

  OrganizerSessionStateMock(super.applicationState, super.libraryState);

  @override
  get sessionParticipants => _sessionParticipants;

  @override
  User? getUser(SessionParticipant participant) => _participantUsers
      .firstWhere((user) => user.id == participant.participantId.id);

  @override
  User? getUserById(String id) =>
      _participantUsers.firstWhere((user) => user.id == id);

  @override
  User? getUserByDisplayName(String displayName) =>
      _participantUsers.firstWhere((user) => user.displayName == displayName);

  @override
  List<Lesson> getGraduatedLessons(SessionParticipant participant) =>
      _graduatedLessons[participant] ?? [];

  addTestUser(String name, bool isAdmin, List<Lesson> graduatedLessons) {
    var user = User(nextId, nextId, name, name, 'my profile', isAdmin, 'n/a', null, null, false, null, false, null, null);
    _participantUsers.add(user);

    var userRef = FirebaseFirestore.instance.doc('/users/${user.id}');
    var sessionRef = FirebaseFirestore.instance.doc('/sessions/$_sessionId');
    var participant = SessionParticipant(
        nextId,
        sessionRef,
        userRef,
        user.uid,
        _courseRef,
        isAdmin,
        true,
        0,
        0,
        LearningStrategyEnum.completeBeforeAdvance);
    _sessionParticipants.add(participant);
    print('$name has user id ${user.id} and participant id ${participant.id}');

    _graduatedLessons[participant] = graduatedLessons;
  }
}
