import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../data/course.dart';
import 'application_state.dart';
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
      appBar: new AppBar(
        title: Text('Social Learning'),
      ),
      bottomNavigationBar: BottomBar(),
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
                      child: Text('Change display name'),
                    ),
                    const Spacer(),
                    const Divider(),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, NavigationEnum.sign_out.route),
                        child: new Text("Sign out")),
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
            title: Text("Enter a new display name"),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  _newDisplayName = value;
                });
              },
              controller: textFieldController,
              decoration: InputDecoration(hintText: 'Princess Fedora'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    applicationState.userDisplayName = textFieldController.value.text;
                    Navigator.pop(context);
                  });
                },
                child: Text("OK"),
              ),
            ],
          );
        });
  }
}
