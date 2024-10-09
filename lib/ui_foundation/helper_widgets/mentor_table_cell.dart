import 'package:flutter/material.dart';
import 'package:googleapis/dataproc/v1.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_table_cell.dart';

class MentorTableCell extends UserTableCell {
  final Lesson? lesson;
  final OrganizerSessionState organizerSessionState;

  MentorTableCell(super.user, super.sessionPairing, super.isEditable,
      super.selectHintText, this.lesson, this.organizerSessionState,
      {super.key});

  @override
  UserTableCellState createState() => UserTableCellState();

  @override
  List<DropdownMenuEntry<User>> getSelectableUsers() {
    // Get all users.
    List<User> users = List.of(organizerSessionState.participantUsers);

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
    organizerSessionState.removeMentor(user, sessionPairing);
  }

  @override
  void selectUser(User? selectedUser) {
    if (selectedUser != null) {
      organizerSessionState.addMentor(selectedUser, sessionPairing);
    }
  }
}
