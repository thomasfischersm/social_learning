import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_comparison_table.dart';
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
      FirebaseFirestore.instance
          .doc('users/$otherUserId')
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.exists) {
          setState(() {
            _otherUser = User.fromSnapshot(snapshot);
          });
        }
      });

      // Load the other user's PracticeRecords.
      // FirebaseFirestore.instance
      //     .collection('practiceRecords')
      //     .where('uid', isEqualTo: otherUserUid)
      //     .where('isGraduation', isEqualTo: true)
      //     .get()
      //     .then((QuerySnapshot<Map<String, dynamic>> snapshot) {
      //   if (snapshot.docs.isNotEmpty) {
      //     setState(() {
      //       _otherUserGraduatedLessonIds = snapshot.docs
      //           .map((doc) => PracticeRecord.fromSnapshot(doc).lessonId.id)
      //           .toSet();
      //     });
      //   }
      // });
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
            child: CustomUiConstants.framePage(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUiConstants.getIndentationTextPadding(
                    CustomUiConstants.getTextPadding(Text(
                        'You and ${_otherUser?.displayName}',
                        style: CustomTextStyles.headline))),
                Consumer<LibraryState>(builder: (context, libraryState, child) {
                  return _createComparisonTable(context, libraryState);
                }),
              ],
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
}
