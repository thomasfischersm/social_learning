import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class ProfileImageWidget extends StatefulWidget {
  final User _user;
  final LibraryState _libraryState;
  final double? maxRadius;
  final bool linkToOtherProfile;

  ProfileImageWidget(this._user, BuildContext context,
      {super.key, this.maxRadius, this.linkToOtherProfile = false})
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

    Widget? avatar;

    var profilePhotoUrl = _profilePhotoUrl;
    if (profilePhotoUrl != null) {
      Color? borderColor = _borderColor;
      if (borderColor != null) {
        print('Drawing profile with border color: $borderColor');
        avatar = Container(
            // padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.0)),
            child: _createCircleAvatar());
      } else {
        print('Drawing profile without border color');
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
      maxRadius: widget.maxRadius ?? 100,
    );
  }

  Future<void> init() async {
    _lastProfileFireStoragePath = widget._user.profileFireStoragePath;
    if (_lastProfileFireStoragePath != null) {
      String url = await FirebaseStorage.instance
          .ref(_lastProfileFireStoragePath)
          .getDownloadURL();

      print('Got profile photo url: $url');

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

  void _goToOtherProfile() {
    OtherProfileArgument.goToOtherProfile(context, widget._user.id, widget._user.uid);
  }
}
