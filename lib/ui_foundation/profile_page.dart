import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/data_helpers/progress_video_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/enable_location_button.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_lookup_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_progress_video_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_text_editor.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/youtube_video_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/application_state.dart';
import 'ui_constants/navigation_enum.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  String? _newDisplayName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Learning'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(Consumer<ApplicationState>(
              builder: (context, applicationState, child) {
            if (UserFunctions.isFirebaseAuthLoggedOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamed(context, NavigationEnum.landing.route);
              });
            }

            User? currentUser = applicationState.currentUser;
            if (currentUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileLookupWidget(applicationState),
                Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CustomUiConstants.getDivider()),
                Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: InkWell(
                              onTap: () => _pickProfileImage(context),
                              child: Stack(children: [
                                ProfileImageWidget(currentUser, context),
                                Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Icon(Icons.edit,color: Colors.grey))
                              ]),
                            ))),
                    const SizedBox(width: 4),
                    Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            InkWell(
                                onTap: () => showDisplayNameDialog(
                                    context, applicationState),
                                child: Row(children: [
                                  Text(
                                    applicationState.userDisplayName ??
                                        '<pick a display name>',
                                    style: CustomTextStyles.subHeadline,
                                  ),
                                  const SizedBox(width: 4),
                                   Icon(Icons.edit,color: Colors.grey),
                                ])),
                            ProfileTextEditor(applicationState)
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Settings',
                  style: CustomTextStyles.subHeadline,
                ),
                Row(children: [
                  const SizedBox(width: 10),
                  Text('Instagram: ', style: CustomTextStyles.getBody(context)),
                  InkWell(
                      onTap: () => _openInstagram(context, applicationState),
                      child: Text(currentUser.instagramHandle ?? '<enter>',
                          style: CustomTextStyles.getBody(context))),
                  IconButton(
                      onPressed: () =>
                          _editInstagramHandle(context, applicationState),
                      icon: Icon(Icons.edit,color: Colors.grey)),
                ]),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Checkbox(
                        value: currentUser.isProfilePrivate,
                        onChanged: (isChecked) =>
                            _toogleIsPrivateProfile(context, applicationState)),
                    // Flexible(child:Text(
                    //     'Enable private profile. (Your profile will still be visible in session and to instructors.',softWrap: true,
                    //     style: CustomTextStyles.getBody(context))),
                    Flexible(
                        child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: 'Make private profile. ',
                            style: CustomTextStyles.getBodyNote(context)),
                        TextSpan(
                            text:
                                '(Your profile will still be visible in session and to instructors.)',
                            style: CustomTextStyles.getBodySmall(context))
                      ]),
                    )),
                  ],
                ),
                EnableLocationButton(applicationState),
                Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CustomUiConstants.getDivider()),
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.signOut.route),
                    child: const Text("Sign out.")),
                Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CustomUiConstants.getDivider()),
                ProfileProgressVideoWidget(currentUser),
                CustomUiConstants.getGeneralFooter(context)
              ],
            );
          }))),
    );
  }

  void showDisplayNameDialog(
      BuildContext context, ApplicationState applicationState) {
    TextEditingController textFieldController =
        TextEditingController(text: applicationState.userDisplayName);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enter a new display name"),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  _newDisplayName = value;
                });
              },
              controller: textFieldController,
              decoration: const InputDecoration(hintText: 'Princess Fedora'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    applicationState.userDisplayName =
                        textFieldController.value.text;
                    Navigator.pop(context);
                  });
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
  }

  void _pickProfileImage(BuildContext context) async {
    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    // Pick the photo from the user.
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    int length = await file?.length() ?? -1;

    // Upload the photo to Firebase.
    if (file != null) {
      var fireStoragePath =
          '/users/${auth.FirebaseAuth.instance.currentUser?.uid}/profilePhoto';
      var storageRef = FirebaseStorage.instance.ref(fireStoragePath);
      // var storageRef = FirebaseStorage.instance.ref().child(
      //     '/profilePhoto');
      // var uploadTask = await storageRef.putFile(File(file.path));
      var imageData = await file.readAsBytes();
      await storageRef.putData(
          imageData, SettableMetadata(contentType: file.mimeType));
      UserFunctions.updateProfilePhoto(fireStoragePath);

      applicationState.invalidateProfilePhoto();

      // Note: Old photos don't have to be deleted because the new photo is
      // saved to the same cloud storage path.
    }
  }

  _toogleIsPrivateProfile(
      BuildContext context, ApplicationState applicationState) {
    applicationState.setIsProfilePrivate(
        !applicationState.currentUser!.isProfilePrivate, applicationState);
  }

  _editInstagramHandle(
      BuildContext context, ApplicationState applicationState) {
    TextEditingController textFieldController = TextEditingController(
        text: applicationState.currentUser?.instagramHandle);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enter a new Instagram handle"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _newDisplayName = value;
                  });
                },
                controller: textFieldController,
                decoration: const InputDecoration(hintText: '@princessfedora'),
              ),
              Text(
                  'Tip: Slip into DMs to arrange study/practice sessions with other students.',
                  style: CustomTextStyles.getBodySmall(context))
            ]),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  UserFunctions.updateInstagramHandle(
                      textFieldController.value.text, applicationState);

                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
  }

  _openInstagram(
      BuildContext context, ApplicationState applicationState) async {
    User? currentUser = applicationState.currentUser;

    await UserFunctions.openInstaProfile(currentUser);
  }
}
