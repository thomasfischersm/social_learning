import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/user_functions.dart';

import '../data/course.dart';
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
                return Column(
                  children: [
                    Text(
                      'Hello ${applicationState.userDisplayName ?? '<pick a display name>'}',
                      style: Theme.of(context).textTheme.headline3,
                    ),
                    TextButton(
                      onPressed: () {
                        showDisplayNameDialog(context, applicationState);
                      },
                      child: const Text('Change display name'),
                    ),
                    const Spacer(),
                    _createProfileImage(applicationState),
                    TextButton(
                        onPressed: () {
                          _pickProfileImage(context);
                        },
                        child: const Text('Upload profile image')),
                    const Spacer(),
                    const Divider(),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, NavigationEnum.sign_out.route),
                        child: const Text("Sign out")),
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
      String imageUrl = await storageRef.getDownloadURL();
      UserFunctions.updateProfilePhoto(fireStoragePath, imageUrl);

      applicationState.invalidateProfilePhoto();
    }
  }

  Widget _createProfileImage(ApplicationState applicationState) {
    print('create profile photo ${applicationState.profilePhotoUrl}');
    String? profilePhotoUrl = applicationState.profilePhotoUrl;
    if (profilePhotoUrl != null) {
      return Expanded(
          child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.scaleDown,
                      image: NetworkImage(profilePhotoUrl)))));
    } else {
      return const Icon(Icons.photo);
    }
  }
}
