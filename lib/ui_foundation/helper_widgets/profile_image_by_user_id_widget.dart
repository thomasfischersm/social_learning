import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';

class ProfileImageByUserIdWidget extends StatefulWidget {
  final DocumentReference userId;
  final LibraryState libraryState;
  final bool linkToOtherProfile;

  const ProfileImageByUserIdWidget(this.userId, this.libraryState,
      {super.key, this.linkToOtherProfile = false});

  @override
  State<StatefulWidget> createState() {
    return ProfileImageByUserIdWidgetState();
  }
}

class ProfileImageByUserIdWidgetState
    extends State<ProfileImageByUserIdWidget> {
  String? _profilePhotoUrl;
  Color? _borderColor;
  User? _user;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    String? profilePhotoUrl = _profilePhotoUrl;
    if (profilePhotoUrl != null) {
      Color? borderColor = _borderColor;
      if (borderColor != null) {
        avatar = Container(
            // padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.0)),
            child: _createCircleAvatar());
      } else {
        avatar = _createCircleAvatar();
      }
    } else {
      avatar = const Icon(Icons.photo);
    }

    if (widget.linkToOtherProfile) {
      return InkWell(onTap: _goToOtherProfile, child: avatar);
    } else {
      return avatar;
    }
  }

  CircleAvatar _createCircleAvatar() {
    print('Creating circle avatar with url: $_profilePhotoUrl');
    double logicalScreenWidth = MediaQuery.of(context).size.width;
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    double physicalScreenWidth = logicalScreenWidth * pixelRatio;

    // TODO: Use the cacheSize parameter to be better with memory usage.

    return CircleAvatar(
      backgroundImage: ResizeImage(
          NetworkImage(
            _profilePhotoUrl!,
          ),
          width: (physicalScreenWidth * .34).toInt(),
          policy: ResizeImagePolicy.fit),
      maxRadius: 100,
    );
  }

  Future<void> init() async {
    var userRef = docRef('users', widget.userId.id);
    // TODO: Add caching!
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      User user = User.fromSnapshot(userSnapshot);
      _user = user;
      Course? course = widget.libraryState.selectedCourse;
      Color? borderColor;
      if (course != null) {
        CourseProficiency? courseProficiency =
            user.getCourseProficiency(course);
        if (courseProficiency != null) {
          borderColor =
              BeltColorFunctions.getBeltColor(courseProficiency.proficiency);
        }
      }

      if (user.profileFireStoragePath != null) {
        String url = await FirebaseStorage.instance
            .ref(user.profileFireStoragePath)
            .getDownloadURL();
        if (mounted) {
          setState(() {
            _profilePhotoUrl = url;
            _borderColor = borderColor;
          });
        }
      }
    }
  }

  void _goToOtherProfile() {
    User? user = _user;

    if (user != null) {
      OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
    }
  }
}
