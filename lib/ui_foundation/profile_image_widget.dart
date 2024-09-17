import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:provider/provider.dart';

class ProfileImageWidget extends StatefulWidget {
  final User _user;
  final LibraryState _libraryState;

  ProfileImageWidget(this._user, BuildContext context, {super.key})
      : _libraryState = Provider.of<LibraryState>(context, listen: false);

  @override
  State<StatefulWidget> createState() {
    return ProfileImageWidgetState();
  }
}

class ProfileImageWidgetState extends State<ProfileImageWidget> {
  String? _profilePhotoUrl;
  String? _lastProfileFireStoragePath;
  Color? _borderColor;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastProfileFireStoragePath != widget._user.profileFireStoragePath) {
      init();
    }
    var profilePhotoUrl = _profilePhotoUrl;
    if (profilePhotoUrl != null) {
      Color? borderColor = _borderColor;
      if (borderColor != null) {
        print('Drawing profile with border color: $borderColor');
        return Container(
            // padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.0)),
            child: _createCircleAvatar());
      } else {
        print('Drawing profile without border color');
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
    _lastProfileFireStoragePath = widget._user.profileFireStoragePath;
    if (_lastProfileFireStoragePath != null) {
      String url = await FirebaseStorage.instance
          .ref(_lastProfileFireStoragePath)
          .getDownloadURL();

      Color? borderColor;
      var course = widget._libraryState.selectedCourse;
      if (course != null) {
        CourseProficiency? courseProficiency =
            widget._user.getCourseProficiency(course);
        if (courseProficiency != null) {
          borderColor =
              BeltColorFunctions.getBeltColor(courseProficiency.proficiency);
        }
      }

      if (mounted) {
        setState(() {
          _profilePhotoUrl = url;
          _borderColor = borderColor;
        });
      }
    }
  }
}
