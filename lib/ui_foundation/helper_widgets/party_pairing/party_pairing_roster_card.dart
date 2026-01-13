import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_next_lesson_recommender.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class PartyPairingRosterCard extends StatelessWidget {
  const PartyPairingRosterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: 'Student Roster',
      child: Consumer2<OrganizerSessionState, LibraryState>(
        builder: (context, organizerSessionState, libraryState, child) {
          List<Lesson> lessons = libraryState.lessons ?? [];
          List<SessionParticipant> participants =
              _sortedParticipants(organizerSessionState, lessons);
          if (participants.isEmpty) {
            return Text(
              'No students have joined yet.',
              style: CustomTextStyles.getBody(context),
            );
          }

          double learnToTeachRatio =
              organizerSessionState.getLearnTeachRatio();
          Set<String> pairedParticipantIds =
              _buildPairedParticipantIds(organizerSessionState);

          List<TableRow> rows = <TableRow>[];
          rows.add(_buildHeaderRow(context));

          for (SessionParticipant participant in participants) {
            rows.add(_buildParticipantRow(
              context,
              organizerSessionState,
              libraryState,
              participant,
              learnToTeachRatio,
              pairedParticipantIds,
            ));
          }

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
              3: FlexColumnWidth(),
            },
            children: rows,
          );
        },
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context) {
    TextStyle? headerStyle = CustomTextStyles.getBodyNote(context)
        ?.copyWith(fontWeight: FontWeight.bold);

    return TableRow(children: <Widget>[
      _buildHeaderCell(context, 'Student', headerStyle),
      _buildHeaderCell(context, 'Teach', headerStyle,
          alignment: Alignment.centerRight),
      _buildHeaderCell(context, 'Learn', headerStyle,
          alignment: Alignment.centerRight),
      _buildHeaderCell(context, 'Next Lesson', headerStyle),
    ]);
  }

  TableRow _buildParticipantRow(
    BuildContext context,
    OrganizerSessionState organizerSessionState,
    LibraryState libraryState,
    SessionParticipant participant,
    double learnToTeachRatio,
    Set<String> pairedParticipantIds,
  ) {
    User? user = organizerSessionState.getUser(participant);
    String displayName = user?.displayName ?? 'Unknown';
    String userId = participant.participantId.id;
    int teachCount = organizerSessionState.getTeachCountForUser(userId);
    int learnCount = organizerSessionState.getLearnCountForUser(userId);
    Lesson? nextLesson = PartyPairingNextLessonRecommender.recommendNextLesson(
      organizerSessionState,
      libraryState,
      participant,
    );

    bool isPaired = pairedParticipantIds.contains(userId);
    Color rowColor = _rowColor(context, participant, learnToTeachRatio);
    Color cellColor = _applyOverlayColor(context, rowColor, isPaired);

    return TableRow(children: <Widget>[
      _buildRowCell(
        context,
        cellColor,
        InkWell(
          onTap: () => InstructorClipboardArgument.navigateTo(
            context,
            userId,
            participant.participantUid,
          ),
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      _buildRowCell(
        context,
        cellColor,
        Align(
          alignment: Alignment.centerRight,
          child: Text('$teachCount'),
        ),
      ),
      _buildRowCell(
        context,
        cellColor,
        Align(
          alignment: Alignment.centerRight,
          child: Text('$learnCount'),
        ),
      ),
      _buildRowCell(
        context,
        cellColor,
        _buildLessonLink(context, nextLesson),
      ),
    ]);
  }

  Widget _buildHeaderCell(
    BuildContext context,
    String label,
    TextStyle? style, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return CustomUiConstants.getIndentationTextPadding(
      Align(
        alignment: alignment,
        child: Text(label, style: style),
      ),
    );
  }

  Widget _buildRowCell(
    BuildContext context,
    Color backgroundColor,
    Widget child,
  ) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );
  }

  Widget _buildLessonLink(BuildContext context, Lesson? lesson) {
    if (lesson == null) {
      return const Text('-');
    }

    TextStyle? linkStyle = CustomTextStyles.getBodyNote(context)?.copyWith(
      decoration: TextDecoration.underline,
    );

    return InkWell(
      onTap: () => LessonDetailArgument.goToLessonDetailPage(
        context,
        lesson.id!,
      ),
      child: Text(
        lesson.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: linkStyle,
      ),
    );
  }

  Color _rowColor(
    BuildContext context,
    SessionParticipant participant,
    double learnToTeachRatio,
  ) {
    double teachDeficit =
        participant.teachCount * learnToTeachRatio - participant.learnCount;
    double intensity = min(teachDeficit.abs() / 5.0, 1.0);
    Color base = Theme.of(context).colorScheme.surfaceVariant;
    if (teachDeficit > 0) {
      base = Color.lerp(base, Colors.green.shade200, intensity) ?? base;
    } else if (teachDeficit < 0) {
      base = Color.lerp(base, Colors.red.shade200, intensity) ?? base;
    }
    return base;
  }

  Color _applyOverlayColor(
    BuildContext context,
    Color baseColor,
    bool isPaired,
  ) {
    if (!isPaired) {
      return baseColor;
    }

    Color overlay = Theme.of(context).colorScheme.scrim.withOpacity(0.12);
    return Color.alphaBlend(overlay, baseColor);
  }

  Set<String> _buildPairedParticipantIds(
    OrganizerSessionState organizerSessionState,
  ) {
    Set<String> participantIds = <String>{};

    for (SessionPairing pairing in organizerSessionState.allPairings) {
      if (pairing.isCompleted) {
        continue;
      }

      if (pairing.mentorId != null) {
        participantIds.add(pairing.mentorId!.id);
      }
      if (pairing.menteeId != null) {
        participantIds.add(pairing.menteeId!.id);
      }
      for (DocumentReference studentId in pairing.additionalStudentIds) {
        participantIds.add(studentId.id);
      }
    }

    return participantIds;
  }

  List<SessionParticipant> _sortedParticipants(
    OrganizerSessionState organizerSessionState,
    List<Lesson> orderedLessons,
  ) {
    List<SessionParticipant> participants = List<SessionParticipant>.from(
      organizerSessionState.sessionParticipants,
    );
    Map<String, int> lessonIndexById = <String, int>{
      for (int i = 0; i < orderedLessons.length; i++) orderedLessons[i].id!: i
    };

    participants.sort((a, b) {
      User? userA = organizerSessionState.getUser(a);
      User? userB = organizerSessionState.getUser(b);
      List<int> graduatedA = organizerSessionState
          .getGraduatedLessons(a)
          .map((lesson) => lessonIndexById[lesson.id] ?? -1)
          .toList();
      List<int> graduatedB = organizerSessionState
          .getGraduatedLessons(b)
          .map((lesson) => lessonIndexById[lesson.id] ?? -1)
          .toList();

      int highestA = graduatedA.isEmpty ? -1 : graduatedA.reduce(max);
      int highestB = graduatedB.isEmpty ? -1 : graduatedB.reduce(max);
      if (highestA != highestB) {
        return highestB.compareTo(highestA);
      }

      if (graduatedA.length != graduatedB.length) {
        return graduatedB.length.compareTo(graduatedA.length);
      }

      DateTime createdA = userA?.created.toDate() ?? DateTime.now();
      DateTime createdB = userB?.created.toDate() ?? DateTime.now();
      return createdA.compareTo(createdB);
    });

    return participants;
  }
}
