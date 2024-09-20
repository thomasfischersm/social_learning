import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';

class ProfileImageByUserIdWidget extends StatefulWidget {
  final DocumentReference userId;
  final LibraryState libraryState;

  const ProfileImageByUserIdWidget(this.userId, this.libraryState, {super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileImageByUserIdWidgetState();
  }
}

class ProfileImageByUserIdWidgetState extends State<ProfileImageByUserIdWidget> {
  String? _profilePhotoUrl;
  Color? _borderColor;
  // String? _lastProfileFireStoragePath;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    String? profilePhotoUrl = _profilePhotoUrl;
    if (profilePhotoUrl != null) {
      Color? borderColor = _borderColor;
      if (borderColor != null) {
        return Container(
          // padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.0)),
            child: _createCircleAvatar());
      } else {
        return _createCircleAvatar();
      }
    } else {
      return const Icon(Icons.photo);
    }
  }

  CircleAvatar _createCircleAvatar() {
    return CircleAvatar(
      backgroundImage: NetworkImage(_profilePhotoUrl!),
      maxRadius: 100,
    );
  }

  Future<void> init() async {
    var userRef = FirebaseFirestore.instance.doc('/users/${widget.userId.id}');
    // TODO: Add caching!
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      User user = User.fromSnapshot(userSnapshot);
      Course? course = widget.libraryState.selectedCourse;
      Color? borderColor;
      if (course != null) {
        CourseProficiency? courseProficiency = user.getCourseProficiency(course);
        if (courseProficiency != null) {
          borderColor = BeltColorFunctions.getBeltColor(courseProficiency.proficiency);
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
}