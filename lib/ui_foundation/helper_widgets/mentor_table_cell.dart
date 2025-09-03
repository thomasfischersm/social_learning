import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_table_cell.dart';

class MentorTableCell extends UserTableCell {
  final Lesson? lesson;
  final OrganizerSessionState organizerSessionState;

  const MentorTableCell(super.user, super.sessionPairing, super.isEditable,
      super.selectHintText, this.lesson, this.organizerSessionState,
      {super.key});

  @override
  UserTableCellState createState() => UserTableCellState();

  @override
  List<DropdownMenuEntry<User>> getSelectableUsers() {
    // Derive the set of inactive user UIDs.
    Set<String> inactiveUserUids =
        organizerSessionState.sessionParticipants
            .where((participant) => !participant.isActive)
            .map((participant) => participant.participantUid)
            .toSet();

    // Get all users.
    List<User> users = List.of(organizerSessionState.participantUsers);

    // Remove inactive users.
    users.removeWhere((user) => inactiveUserUids.contains(user.uid));

    // Remove users that are already in pairings.
    List<SessionPairing>? currentRound = organizerSessionState.lastRound;
    print('Participant users: ${organizerSessionState.participantUsers.length} and currentRound: ${currentRound?.length}');
    if (currentRound != null) {
      for (SessionPairing pairing in currentRound) {
        var mentorId = pairing.mentorId;
        if (mentorId != null) {
          users.removeWhere((user) => user.id == mentorId.id);
        }

        var menteeId = pairing.menteeId;
        if (menteeId != null) {
          users.removeWhere((user) => user.id == menteeId.id);
        }
      }
    }

    // Sort alphabetical.
    users.sort((a, b) => a.displayName.compareTo(b.displayName));

    return users
        .map((user) => DropdownMenuEntry<User>(
            value: user,
            label: user.displayName,
            enabled: (lesson == null)
                ? true
                : organizerSessionState.hasUserGraduatedLesson(user, lesson!)))
        .toList();
  }

  @override
  void removeUser() {
    organizerSessionState.removeMentor(sessionPairing);
  }

  @override
  void selectUser(User? selectedUser) {
    if (selectedUser != null) {
      organizerSessionState.addMentor(selectedUser, sessionPairing);
    }
  }
}
