import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class SessionRoundCard extends StatelessWidget {
  final String roundNumber;
  final SessionPairing? sessionPairing;
  late User? _mentor;
  late User? _mentee;
  late Lesson? _lesson;

  SessionRoundCard(this.roundNumber, this.sessionPairing,
      StudentSessionState studentSessionState, LibraryState libraryState,
      {super.key}) {
    String? mentorId = sessionPairing?.mentorId?.id;
    if (mentorId != null) {
      _mentor = studentSessionState.getUserById(mentorId);
    } else {
      _mentor = null;
    }

    String? menteeId = sessionPairing?.menteeId?.id;
    if (menteeId != null) {
      _mentee = studentSessionState.getUserById(menteeId);
    } else {
      _mentee = null;
    }

    String? lessonId = sessionPairing?.lessonId?.id;
    if (lessonId != null) {
      _lesson = libraryState.findLesson(lessonId);
    } else {
      _lesson = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(16.0),
      // ),
      // elevation: 4.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _createRoundBand(context),
          if (sessionPairing != null)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Flexible(flex: 1, child: _createProfileColumn(context)),
              Flexible(flex: 2, child: _createLessonColumn(context))
            ])
          else
            Text('No pairing this round.', textAlign: TextAlign.center)
        ],
      ),
    );
  }

  Widget _createRoundBand(BuildContext context) {
    String teachOrLearnString;
    if (sessionPairing == null) {
      teachOrLearnString = '';
    } else if ((_mentor == null) || (_mentee == null)) {
      teachOrLearnString = ' - Awaiting partner';
    } else if (_mentor == getOtherUser(context)) {
      teachOrLearnString = ' - Your turn to learn';
    } else {
      teachOrLearnString = ' - Your turn to teach';
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Text(
        'Round $roundNumber$teachOrLearnString',
        style: CustomTextStyles.subHeadline.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _createProfileColumn(BuildContext context) {
    User? otherUser = getOtherUser(context);

    if (otherUser != null) {
      return Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                  aspectRatio: 1,
                  child: ProfileImageWidget(
                    otherUser,
                    context,
                    linkToOtherProfile: true,
                  )),
              Text(otherUser.displayName,
                  style: CustomTextStyles.getBody(context))
            ],
          ));
    } else {
      return Text('<Not assigned>', style: CustomTextStyles.getBody(context));
    }
  }

  Widget _createLessonColumn(BuildContext context) {
    Lesson? lesson = _lesson;
    if (lesson != null) {
      return InkWell(
          onTap: () =>
              LessonDetailArgument.goToLessonDetailPage(context, lesson.id!),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lesson.coverFireStoragePath != null)
                Align(
                    alignment: Alignment.topRight,
                    child: LessonCoverImageWidget(lesson.coverFireStoragePath)),
              Text(lesson.title, style: CustomTextStyles.getBody(context))
            ],
          ));
    } else {
      return Text('<Not assigned>', style: CustomTextStyles.getBody(context));
    }
  }

  User? getOtherUser(BuildContext context) {
    ApplicationState applicationState = Provider.of<ApplicationState>(context);
    return (_mentor?.id == applicationState.currentUser?.id)
        ? _mentee
        : _mentor;
  }
}
