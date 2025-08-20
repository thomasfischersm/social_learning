import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_glow_painter.dart';

/// Unified version of [ProfileImageWidget] and [ProfileImageByUserIdWidget].
///
/// Displays a user's profile image with an optional belt-colored border and can
/// link to the user's profile page. The widget can be constructed either with a
/// [User] object or a Firestore document reference to the user. All Firebase
/// calls are delegated to [UserFunctions].
class ProfileImageV3 extends StatefulWidget {
  final User? _user;
  final DocumentReference? _userRef;
  final double? maxRadius;
  final bool linkToOtherProfile;
  final bool listenForProfileUpdate;
  final bool _useCurrentUser;
  final double teachLearnRatio;

  const ProfileImageV3._(this._user, this._userRef,
      {super.key,
      this.maxRadius,
      this.linkToOtherProfile = false,
      this.listenForProfileUpdate = false,
      bool useCurrentUser = false,
      this.teachLearnRatio = 0.0})
      : _useCurrentUser = useCurrentUser;

  /// Creates a [ProfileImageV3] from an existing [User] object.
  factory ProfileImageV3.fromUser(User user,
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      double teachLearnRatio = 0.0}) {
    return ProfileImageV3._(user, null,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        teachLearnRatio: teachLearnRatio);
  }

  /// Creates a [ProfileImageV3] from a user document reference.
  factory ProfileImageV3.fromUserId(DocumentReference userRef,
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      double teachLearnRatio = 0.0}) {
    return ProfileImageV3._(null, userRef,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        teachLearnRatio: teachLearnRatio);
  }

  /// Creates a [ProfileImageV3] for the currently logged-in user.
  factory ProfileImageV3.fromCurrentUser(
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      double teachLearnRatio = 0.0}) {
    return ProfileImageV3._(null, null,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        useCurrentUser: true,
        teachLearnRatio: teachLearnRatio);
  }

  @override
  State<ProfileImageV3> createState() => _ProfileImageV3State();
}

class _ProfileImageV3State extends State<ProfileImageV3> {
  User? _user;
  String? _profilePhotoUrl;
  StreamSubscription<User>? _userSubscription;

  @override
  void initState() {
    super.initState();
    ProfileGlowPainter.ensureShader().then((_) {
      if (mounted) setState(() {});
    });
    _init();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget._useCurrentUser) {
      final applicationState =
          Provider.of<ApplicationState>(context, listen: false);
      User? currentUser = applicationState.currentUser;
      currentUser ??= await applicationState.currentUserBlocking;
      if (currentUser != null) {
        _updateUser(currentUser);
        if (widget.listenForProfileUpdate) {
          _userSubscription =
              UserFunctions.listenToUser(currentUser.id).listen(_updateUser);
        }
      }
    } else if (widget._user != null) {
      _updateUser(widget._user!);
      if (widget.listenForProfileUpdate) {
        _userSubscription = UserFunctions.listenToUser(widget._user!.id)
            .listen(_updateUser);
      }
    } else if (widget._userRef != null) {
      if (widget.listenForProfileUpdate) {
        _userSubscription =
            UserFunctions.listenToUser(widget._userRef!.id).listen(_updateUser);
      } else {
        User user = await UserFunctions.getUserById(widget._userRef!.id);
        _updateUser(user);
      }
    }
  }

  void _updateUser(User user) {
    _user = user;
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    if (_user == null) return;
    String? url = await UserFunctions.getProfilePhotoUrl(_user!);
    if (mounted) {
      setState(() {
        _profilePhotoUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final libraryState = Provider.of<LibraryState>(context);
      final borderColor = _computeBorderColor(libraryState);
      final maxDisplayRadius = _calculateDisplayRadius(constraints);
      Widget avatar;
      if (_profilePhotoUrl != null) {
        avatar = _buildAvatarWithImage(context, borderColor, maxDisplayRadius,
            constraints.maxWidth);
      } else {
        avatar = CircleAvatar(
          maxRadius: maxDisplayRadius,
          child: Icon(Icons.photo, size: maxDisplayRadius),
        );
      }

      final glowRatio = widget.teachLearnRatio;
      if (glowRatio > 0.5) {
        final glowStrength = ((glowRatio - 0.5) / 0.5).clamp(0.0, 1.0);
        final glowExtent = maxDisplayRadius * (0.5 * glowStrength);
        avatar = Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: (maxDisplayRadius + glowExtent) * 2,
              height: (maxDisplayRadius + glowExtent) * 2,
              child: CustomPaint(
                painter: ProfileGlowPainter(
                    avatarRadius: maxDisplayRadius,
                    glowStrength: glowStrength),
              ),
            ),
            avatar,
          ],
        );
      }

      if (widget.linkToOtherProfile) {
        return InkWell(onTap: _goToOtherProfile, child: avatar);
      }
      return avatar;
    });
  }

  double _calculateDisplayRadius(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final unconstrainedRadius = availableWidth / 2;
    final maxRadius = widget.maxRadius;
    if (maxRadius == null) {
      return unconstrainedRadius;
    }
    return maxRadius < unconstrainedRadius ? maxRadius : unconstrainedRadius;
  }

  Widget _buildAvatarWithImage(BuildContext context, Color? borderColor,
      double maxDisplayRadius, double availableWidth) {
    Widget avatar = _createCircleAvatar(context, maxDisplayRadius, availableWidth);

    if (borderColor != null) {
      avatar = Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.0)),
          child: avatar);
    }
    return avatar;
  }

  CircleAvatar _createCircleAvatar(
      BuildContext context, double maxDisplayRadius, double availableWidth) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenPhysicalWidth =
        MediaQuery.of(context).size.width * pixelRatio * 0.34;
    final displayDiameter = maxDisplayRadius * 2;
    final physicalWidth = displayDiameter * pixelRatio;
    final resizeWidth =
        physicalWidth < screenPhysicalWidth ? physicalWidth : screenPhysicalWidth;

    return CircleAvatar(
      backgroundImage: ResizeImage(NetworkImage(_profilePhotoUrl!),
          width: resizeWidth.toInt(), policy: ResizeImagePolicy.fit),
      maxRadius: maxDisplayRadius,
    );
  }

  Color? _computeBorderColor(LibraryState libraryState) {
    final user = _user;
    final course = libraryState.selectedCourse;
    if (user != null && course != null) {
      final courseProficiency = user.getCourseProficiency(course);
      if (courseProficiency != null) {
        return BeltColorFunctions.getBeltColor(courseProficiency.proficiency);
      }
    }
    return null;
  }

  void _goToOtherProfile() {
    final user = _user;
    if (user != null) {
      OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
    }
  }
}

