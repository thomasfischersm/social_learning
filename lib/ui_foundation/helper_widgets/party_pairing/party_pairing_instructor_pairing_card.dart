import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/progress_checkbox.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class PartyPairingInstructorPairingCard extends StatefulWidget {
  const PartyPairingInstructorPairingCard({super.key});

  @override
  State<PartyPairingInstructorPairingCard> createState() =>
      _PartyPairingInstructorPairingCardState();
}

class _PartyPairingInstructorPairingCardState
    extends State<PartyPairingInstructorPairingCard> {
  bool _isInstructorParticipating = false;

  @override
  Widget build(BuildContext context) {
    OrganizerSessionState organizerSessionState =
        context.watch<OrganizerSessionState>();
    LibraryState libraryState = context.watch<LibraryState>();

    User? instructorUser = _findInstructorUser(organizerSessionState);
    SessionPairing? instructorPairing =
        _findInstructorPairing(organizerSessionState, instructorUser);
    Lesson? lesson = _getLessonForPairing(libraryState, instructorPairing);
    List<User?> learners = _getLearnersForPairing(
        organizerSessionState, instructorUser, instructorPairing);

    return CustomCard(
      title: 'Instructor Pairing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParticipationRow(context),
          if (instructorPairing != null) ...[
            const SizedBox(height: 12),
            _buildLessonRow(context, lesson),
            const SizedBox(height: 12),
            _buildLearnerTable(
              context: context,
              learners: learners,
              lesson: lesson,
              organizerSessionState: organizerSessionState,
            ),
            const SizedBox(height: 12),
            _buildCompleteButton(organizerSessionState, instructorPairing),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No active pairing yet.',
              style: CustomTextStyles.getBodyNote(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipationRow(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _isInstructorParticipating,
      onChanged: _onParticipationToggled,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        'Instructor participates in pairings',
        style: CustomTextStyles.getBody(context),
      ),
    );
  }

  Widget _buildLessonRow(BuildContext context, Lesson? lesson) {
    if (lesson == null) {
      return Text(
        'Lesson not assigned',
        style: CustomTextStyles.getBody(context),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Lesson: ',
          style: CustomTextStyles.getBody(context),
        ),
        InkWell(
          onTap: () =>
              LessonDetailArgument.goToLessonDetailPage(context, lesson.id!),
          child: Text(
            lesson.title,
            style: CustomTextStyles.getBody(context)
                .copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildLearnerTable({
    required BuildContext context,
    required List<User?> learners,
    required Lesson? lesson,
    required OrganizerSessionState organizerSessionState,
  }) {
    List<TableRow> learnerRows = _buildLearnerRows(
      context: context,
      learners: learners,
      lesson: lesson,
      organizerSessionState: organizerSessionState,
    );
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: learnerRows,
    );
  }

  List<TableRow> _buildLearnerRows({
    required BuildContext context,
    required List<User?> learners,
    required Lesson? lesson,
    required OrganizerSessionState organizerSessionState,
  }) {
    if (learners.isEmpty) {
      return [
        _buildLearnerRow(
          context: context,
          label: 'Learners:',
          learner: null,
          bottomPadding: 0,
          lesson: lesson,
          organizerSessionState: organizerSessionState,
        ),
      ];
    }

    return [
      for (int i = 0; i < learners.length; i++)
        _buildLearnerRow(
          context: context,
          label: i == 0 ? 'Learners:' : '',
          learner: learners[i],
          bottomPadding: i == learners.length - 1 ? 0 : 8,
          lesson: lesson,
          organizerSessionState: organizerSessionState,
        ),
    ];
  }

  TableRow _buildLearnerRow({
    required BuildContext context,
    required String label,
    required User? learner,
    required double bottomPadding,
    required Lesson? lesson,
    required OrganizerSessionState organizerSessionState,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Text(label, style: CustomTextStyles.getBodyNote(context)),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12, bottom: bottomPadding),
          child: _buildLearnerContent(context, learner),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12, bottom: bottomPadding),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildLearnerProgress(
                  learner,
                  lesson,
                  organizerSessionState,
                ) ??
                const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildLearnerContent(BuildContext context, User? learner) {
    if (learner == null) {
      return Text('<Not assigned>', style: CustomTextStyles.getBody(context));
    }

    return Row(
      children: [
        ProfileImageWidgetV2.fromUser(
          learner,
          key: ValueKey(learner.id),
          maxRadius: 18,
          linkToOtherProfile: true,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => OtherProfileArgument.goToOtherProfile(
              context,
              learner.id,
              learner.uid,
            ),
            child: Text(
              learner.displayName,
              style: CustomTextStyles.getBody(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildLearnerProgress(
    User? learner,
    Lesson? lesson,
    OrganizerSessionState organizerSessionState,
  ) {
    if (learner == null || lesson == null) {
      return null;
    }

    double progressValue = _getLearnerLessonProgress(
      organizerSessionState,
      lesson,
      learner,
    );
    return ProgressCheckbox(value: progressValue);
  }

  Widget _buildCompleteButton(
    OrganizerSessionState organizerSessionState,
    SessionPairing pairing,
  ) {
    return ElevatedButton(
      onPressed: () => _completePairing(organizerSessionState, pairing),
      child: const Text('Complete pairing'),
    );
  }

  User? _findInstructorUser(OrganizerSessionState organizerSessionState) {
    String? organizerUid = organizerSessionState.currentSession?.organizerUid;
    if (organizerUid == null) {
      return null;
    }

    return organizerSessionState.participantUsers.firstWhereOrNull(
      (user) => user.uid == organizerUid,
    );
  }

  SessionPairing? _findInstructorPairing(
    OrganizerSessionState organizerSessionState,
    User? instructorUser,
  ) {
    if (instructorUser == null) {
      return null;
    }

    String instructorId = instructorUser.id;
    return organizerSessionState.allPairings.firstWhereOrNull((pairing) {
      if (pairing.isCompleted) {
        return false;
      }

      bool isMentor = pairing.mentorId?.id == instructorId;
      bool isMentee = pairing.menteeId?.id == instructorId;
      bool isAdditional = pairing.additionalStudentIds
          .any((studentId) => studentId.id == instructorId);
      return isMentor || isMentee || isAdditional;
    });
  }

  Lesson? _getLessonForPairing(
    LibraryState libraryState,
    SessionPairing? pairing,
  ) {
    return libraryState.findLesson(pairing?.lessonId?.id);
  }

  List<User?> _getLearnersForPairing(
    OrganizerSessionState organizerSessionState,
    User? instructorUser,
    SessionPairing? pairing,
  ) {
    if (pairing == null || instructorUser == null) {
      return [];
    }

    List<String> learnerIds = [
      if (pairing.mentorId?.id != null) pairing.mentorId!.id,
      if (pairing.menteeId?.id != null) pairing.menteeId!.id,
      ...pairing.additionalStudentIds.map((student) => student.id),
    ];

    return learnerIds
        .where((id) => id != instructorUser.id)
        .map(organizerSessionState.getUserById)
        .toList();
  }

  double _getLearnerLessonProgress(
    OrganizerSessionState organizerSessionState,
    Lesson lesson,
    User learner,
  ) {
    Iterable<PracticeRecord> learnerRecords = organizerSessionState
        .practiceRecords
        .where((record) =>
            record.menteeUid == learner.uid &&
            record.lessonId.id == lesson.id);

    return PracticeRecordFunctions.getLearnerLessonProgress(
      lesson: lesson,
      practiceRecords: learnerRecords,
    );
  }

  void _onParticipationToggled(bool? value) {
    bool isSelected = value ?? false;
    setState(() {
      _isInstructorParticipating = isSelected;
    });
  }

  Future<void> _completePairing(
    OrganizerSessionState organizerSessionState,
    SessionPairing pairing,
  ) async {
    String? pairingId = pairing.id;
    if (pairingId == null) {
      return;
    }

    await organizerSessionState.completePairing(pairingId);
  }
}
