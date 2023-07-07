import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/profile_image_widget.dart';

import '../state/application_state.dart';
import 'bottom_bar.dart';
import 'navigation_enum.dart';

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
      bottomNavigationBar: const BottomBar(),
      body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              child: Consumer<ApplicationState>(
                  builder: (context, applicationState, child) {
                return SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ProfileImageWidget(applicationState
                                  .currentUser?.profileFireStoragePath),
                            )),
                        Expanded(
                          flex: 1,
                          child: Text(
                            applicationState.userDisplayName ??
                                '<pick a display name>',
                            style: CustomTextStyles.subHeadline,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Settings',
                      style: CustomTextStyles.subHeadline,
                    ),
                    TextButton(
                        onPressed: () {
                          _pickProfileImage(context);
                        },
                        child: const Text('Upload profile image.')),
                    TextButton(
                      onPressed: () {
                        showDisplayNameDialog(context, applicationState);
                      },
                      child: const Text('Change display name.'),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: CustomUiConstants.getDivider()),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, NavigationEnum.signOut.route),
                        child: const Text("Sign out.")),
                    CustomUiConstants.getGeneralFooter(context)
                  ],
                ));
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
    }
  }
}
