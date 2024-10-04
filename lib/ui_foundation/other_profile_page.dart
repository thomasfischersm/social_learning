import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class OtherProfileArgument {
  String userId;
  String userUid;

  OtherProfileArgument(this.userId, this.userUid);
}

class OtherProfilePage extends StatefulWidget {
  const OtherProfilePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return OtherProfileState();
  }
}

class OtherProfileState extends State<OtherProfilePage> {
  User? _otherUser;

  String? get _otherUserId {
    return (ModalRoute.of(context)?.settings.arguments as OtherProfileArgument?)
        ?.userId;
  }

  String? get _otherUserUid {
    return (ModalRoute.of(context)?.settings.arguments as OtherProfileArgument?)
        ?.userUid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    String? otherUserId = _otherUserId;
    if (otherUserId != null) {
      FirebaseFirestore.instance
          .doc('users/$_otherUserId')
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
    User? otherUser = _otherUser;

    if (otherUser == null) {
      // Loading view.
      return Scaffold(
          appBar: AppBar(
            title: const Text('Loading profile...'),
          ),
          bottomNavigationBar: BottomBarV2.build(context),
          body: Center(
              child: CustomUiConstants.framePage(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomUiConstants.getTextPadding(
                  Text('Loading profile', style: CustomTextStyles.headline)),
            ],
          ))));
    } else if (otherUser.isProfilePrivate) {
      // Private profile view
      return Scaffold(
          appBar: AppBar(
            title: Text('Profile: ${otherUser.displayName}'),
          ),
          bottomNavigationBar: BottomBarV2.build(context),
          body: Center(
              child: CustomUiConstants.framePage(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomUiConstants.getTextPadding(Text(
                  'Profile: ${otherUser.displayName}',
                  style: CustomTextStyles.headline)),
              CustomUiConstants.getTextPadding(Text(
                  'This profile is set to private.',
                  style: CustomTextStyles.getBody(context))),
            ],
          ))));
    } else {
      // Find the course proficiency.
      LibraryState libraryState = Provider.of<LibraryState>(context);
      Course? selectedCourse = libraryState.selectedCourse;
      CourseProficiency? courseProficiency;
      if (selectedCourse != null) {
        courseProficiency = otherUser.getCourseProficiency(selectedCourse);
      }

      // Regular profile view
      return Scaffold(
          appBar: AppBar(
            title: Text('Profile: ${otherUser.displayName}'),
          ),
          bottomNavigationBar: BottomBarV2.build(context),
          body: Center(
              child: CustomUiConstants.framePage(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ProfileImageWidget(otherUser, context),
                  ),
                  Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomUiConstants.getTextPadding(Text(
                                  'Profile: ${otherUser.displayName}',
                                  style: CustomTextStyles.headline)),
                              if (courseProficiency != null)
                                CustomUiConstants.getTextPadding(Text(
                                    'Course completion: ${(courseProficiency.proficiency * 100).toStringAsFixed(0)}%',
                                    style: CustomTextStyles.getBody(context))),
                              if (_otherUser?.instagramHandle != null)
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: 'Insta: ',
                                          style: CustomTextStyles.getBody(
                                              context)),
                                      TextSpan(
                                        text: '@${_otherUser?.instagramHandle}',
                                        style:
                                            CustomTextStyles.getLink(context),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // Call your method here
                                            _openInstaProfile();
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                            ]),
                      ))
                ],
              ),
              CustomUiConstants.getTextPadding(Text(otherUser.profileText,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  style: CustomTextStyles.getBody(context))),
            ],
          ))));
    }
  }

  void _openInstaProfile() {
    UserFunctions.openInstaProfile(_otherUser);
  }
}
