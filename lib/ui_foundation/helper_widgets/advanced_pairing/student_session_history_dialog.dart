import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';

class StudentSessionHistoryDialog {
  static void show(BuildContext context, User user) {
    final sessionPairings = _findSessionPairings(context, user);

    DialogUtils.showInfoDialogWithContent(
        context,
        'Session history for ${user.displayName}',
        SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(context, user, sessionPairings),
            ...sessionPairings
                .expand((pairing) => _buildPairingRow(context, user, pairing))
          ],
        )),
        confirmLabel: 'Dismiss');
  }

  static List<SessionPairing> _findSessionPairings(
      BuildContext context, User user) {
    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();

    return organizerSessionState.allPairings
        .where((pairing) =>
            pairing.mentorId?.id == user.id ||
            pairing.menteeId?.id == user.id ||
            pairing.additionalStudentIds.any((ref) => ref.id == user.id))
        .toList()
      ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));
  }

  static Widget _buildHeaderRow(
      BuildContext context, User user, List<SessionPairing> sessionPairings) {
    final int teachCount = sessionPairings
        .where((pairing) => pairing.mentorId?.id == user.id)
        .length;
    final int learnCount = sessionPairings
        .where((pairing) =>
            pairing.menteeId?.id == user.id ||
            pairing.additionalStudentIds.any((ref) => ref.id == user.id))
        .length;

    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 0,
            horizontalTitleGap: 12,
            leading: SizedBox.square(
                dimension: 64,
                child: ProfileImageWidgetV2.fromUser(
                  user,
                  maxRadius: 32,
                )),
            title: Row(children: [
              Expanded(
                  child: Text(user.displayName,
                      style: CustomTextStyles.subHeadline,
                      overflow: TextOverflow.ellipsis)),
              IconButton(
                  icon: const Icon(Icons.content_paste_rounded, size: 20),
                  tooltip: 'View clipboard',
                  onPressed: () => _navigateToClipboard(context, user)),
              IconButton(
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  tooltip: 'View profile',
                  onPressed: () => _navigateToOtherProfile(context, user))
            ]),
            subtitle: Text('Learned: $learnCount · Taught: $teachCount',
                style: CustomTextStyles.getCaption(context))));
  }

  static void _navigateToClipboard(BuildContext context, User user) {
    InstructorClipboardArgument.navigateTo(context, user.id, user.uid);
  }

  static void _navigateToOtherProfile(BuildContext context, User user) {
    OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
  }

  static List<Widget> _buildPairingRow(
      BuildContext context, User dialogUser, SessionPairing pairing) {
    LibraryState libraryState = context.read<LibraryState>();
    Lesson? lesson = libraryState.findLesson(pairing.lessonId?.id);

    List<DocumentReference> learnerUserIds = [
      pairing.menteeId,
      ...pairing.additionalStudentIds
    ].whereType<DocumentReference>().toList();
    print('learnerUserIds: $learnerUserIds');

    // Make the current user be first (if contained in the list).
    learnerUserIds.sort((a, b) {
      if (a.id == dialogUser.id) return -1;
      if (b.id == dialogUser.id) return 1;
      return 0;
    });

    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();
    User? mentorUser = organizerSessionState.getUserById(pairing.mentorId?.id);
    List<User> learnerUsers = learnerUserIds
        .map((userRef) => organizerSessionState.getUserById(userRef.id))
        .whereType<User>()
        .toList();
    print('learnerUsers: $learnerUsers');

    return [
    Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [InkWell(
          onTap: () => _navigateToLesson(context, lesson),
          child: Text(lesson?.title ?? 'Lesson not found',
              style: CustomTextStyles.getBody(context))),
      Row(children: [
        _frameProfilePhoto(context, dialogUser, mentorUser),
        const SizedBox(width: 4),
        Icon(Icons.arrow_right_alt_rounded,
          size: 22,
          color: CustomTextStyles.getBody(context)?.color,),
        const SizedBox(width: 4),
        ...learnerUsers.expand((learnerUser) => [
              _frameProfilePhoto(context, dialogUser, learnerUser),
              const SizedBox(width: 6)
            ]),
      ]),
      SizedBox(height: 8),
    ]))];
  }

  static Widget _frameProfilePhoto(
      BuildContext context, User dialogUser, User? profilePhotoUser) {
    if (profilePhotoUser == null) {
      return SizedBox.shrink();
    }

    return SizedBox.square(
        dimension: 32,
        child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (dialogUser.id == profilePhotoUser.id)
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                    blurRadius: 4,
                    spreadRadius: 3,
                  )
              ],
            ),
            child: ProfileImageWidgetV2.fromUser(
              profilePhotoUser,
              maxRadius: 32,
              linkToOtherProfile: true,
            )));
  }

  static void _navigateToLesson(BuildContext context, Lesson? lesson) {
    String? lessonId = lesson?.id;
    if (lessonId != null) {
      LessonDetailArgument.goToLessonDetailPage(context, lessonId);
    }
  }
}
