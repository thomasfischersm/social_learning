import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_comparison_table.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_by_user_id_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/data/user.dart';

class ProfileComparisonArgument {
  String userId;
  String userUid;

  ProfileComparisonArgument(this.userId, this.userUid);
}

class ProfileComparisonPage extends StatefulWidget {
  const ProfileComparisonPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileComparisonState();
  }
}

class ProfileComparisonState extends State<ProfileComparisonPage> {
  User? _otherUser;

  String? get _otherUserUid {
    return (ModalRoute.of(context)?.settings.arguments
            as ProfileComparisonArgument?)
        ?.userUid;
  }

  String? get _otherUserId {
    return (ModalRoute.of(context)?.settings.arguments
            as ProfileComparisonArgument?)
        ?.userId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    String? otherUserId = _otherUserId;
    if (otherUserId != null) {
      // Load the other user info.
      docRef('users', otherUserId)
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.exists) {
          setState(() {
            _otherUser = User.fromSnapshot(snapshot);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(
                enableCourseLoadingGuard: true,
                Consumer<ApplicationState>(
              builder: (context, applicationState, child) {
                return Consumer<LibraryState>(
                    builder: (context, libraryState, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _createHeaderWidget(applicationState, libraryState),
                      _createComparisonTable(context, libraryState)
                    ],
                  );
                });
              },
            ))));
  }

  Widget _createComparisonTable(
      BuildContext context, LibraryState libraryState) {
    if (_otherUser == null) {
      return const CircularProgressIndicator();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('practiceRecords')
            .where('menteeUid', isEqualTo: _otherUserUid)
            .where('isGraduation', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return SelectableText('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final practiceRecords = snapshot.data!.docs
              .map((doc) => PracticeRecord.fromSnapshot(doc));

          var otherUserGraduatedLessonIds = practiceRecords
              .map((practiceRecord) => practiceRecord.lessonId.id)
              .toSet();

          return Consumer<StudentState>(
              builder: (context, studentState, child) {
            ApplicationState applicationState =
                Provider.of<ApplicationState>(context, listen: false);

            Iterable<String> currentUserGraduatedLessonIds =
                studentState.getGraduatedLessonIds();

            currentUserGraduatedLessonIds = _handleAdminCase(
                applicationState.currentUser,
                currentUserGraduatedLessonIds,
                context,
                libraryState);
            otherUserGraduatedLessonIds = _handleAdminCase(_otherUser,
                    otherUserGraduatedLessonIds, context, libraryState)
                .toSet();

            return ProfileComparisonTable(
                _otherUser,
                currentUserGraduatedLessonIds,
                otherUserGraduatedLessonIds,
                libraryState);
          });
        });
  }

  Iterable<String> _handleAdminCase(
      User? user,
      Iterable<String> currentUserGraduatedLessonIds,
      BuildContext context,
      LibraryState libraryState) {
    if ((user?.isAdmin == true) && (libraryState.selectedCourse != null)) {
      List<String> adminLessonIds = [];
      for (Lesson lesson in libraryState.lessons ?? []) {
        if (lesson.id != null) {
          adminLessonIds.add(lesson.id!);
        }
      }
      return adminLessonIds;
    } else {
      return currentUserGraduatedLessonIds;
    }
  }

  Widget _createHeaderWidget(
      ApplicationState appState,
      LibraryState libraryState,
      ) {
    final currentUser = appState.currentUser;
    final otherUser = _otherUser;

    if (currentUser == null || otherUser == null) {
      return const SizedBox.shrink();
    }

    const TextStyle nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    const TextStyle actionStyle = TextStyle(fontSize: 14);
    const double avatarRadius = 28;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1) Avatars + names + arrows
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ProfileImageWidget(
                          currentUser,
                          context,
                          maxRadius: avatarRadius,
                          linkToOtherProfile: false,
                        ),
                        const SizedBox(height: 12),
                        Text(currentUser.displayName, style: nameStyle),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_forward, size: 16),
                            SizedBox(width: 4),
                            Text('Teach', style: actionStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ProfileImageWidget(
                          otherUser,
                          context,
                          maxRadius: avatarRadius,
                          linkToOtherProfile: true,
                        ),
                        const SizedBox(height: 12),
                        Text(otherUser.displayName, style: nameStyle),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back, size: 16),
                            SizedBox(width: 4),
                            Text('Learn', style: actionStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2) Explanatory line
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'You teach ${otherUser.displayName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${otherUser.displayName} teaches you',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
