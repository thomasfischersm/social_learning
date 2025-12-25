import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/download_url_cache_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/radar_widget.dart';

/// Unified version of [ProfileImageWidget] and [ProfileImageByUserIdWidget].
///
/// Displays a user's profile image with an optional belt-colored border and can
/// link to the user's profile page. Double-tapping toggles a radar widget in
/// place of the profile image. The widget can be constructed either with a
/// [User] object or a Firestore document reference to the user. All Firebase
/// calls are delegated to [UserFunctions].
class ProfileImageWidgetV2 extends StatefulWidget {
  final User? _user;
  final DocumentReference? _userRef;
  final double? maxRadius;
  final bool linkToOtherProfile;
  final bool listenForProfileUpdate;
  final bool _useCurrentUser;
  final bool enableDoubleTapSwitch;

  const ProfileImageWidgetV2._(this._user, this._userRef,
      {super.key,
      this.maxRadius,
      this.linkToOtherProfile = false,
      this.listenForProfileUpdate = false,
      this.enableDoubleTapSwitch = true,
      bool useCurrentUser = false})
      : _useCurrentUser = useCurrentUser;

  /// Creates a [ProfileImageWidgetV2] from an existing [User] object.
  factory ProfileImageWidgetV2.fromUser(User user,
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      bool enableDoubleTapSwitch = true}) {
    return ProfileImageWidgetV2._(user, null,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        enableDoubleTapSwitch: enableDoubleTapSwitch);
  }

  /// Creates a [ProfileImageWidgetV2] from a user document reference.
  factory ProfileImageWidgetV2.fromUserId(DocumentReference userRef,
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      bool enableDoubleTapSwitch = true}) {
    return ProfileImageWidgetV2._(null, userRef,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        enableDoubleTapSwitch: enableDoubleTapSwitch);
  }

  /// Creates a [ProfileImageWidgetV2] for the currently logged-in user.
  factory ProfileImageWidgetV2.fromCurrentUser(
      {Key? key,
      double? maxRadius,
      bool linkToOtherProfile = false,
      bool listenForProfileUpdate = false,
      bool enableDoubleTapSwitch = true}) {
    return ProfileImageWidgetV2._(null, null,
        key: key,
        maxRadius: maxRadius,
        linkToOtherProfile: linkToOtherProfile,
        listenForProfileUpdate: listenForProfileUpdate,
        enableDoubleTapSwitch: enableDoubleTapSwitch,
        useCurrentUser: true);
  }

  @override
  State<ProfileImageWidgetV2> createState() => _ProfileImageWidgetV2State();
}

class _ProfileImageWidgetV2State extends State<ProfileImageWidgetV2> {
  User? _user;
  String? _profilePhotoUrl;
  StreamSubscription<User>? _userSubscription;
  bool _showRadar = false;
  bool _hasSkillRubric = false;
  String? _checkedCourseId;

  @override
  void initState() {
    super.initState();
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
        _userSubscription =
            UserFunctions.listenToUser(widget._user!.id).listen(_updateUser);
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
    if (_user == null) {
      return;
    }
    DownloadUrlCacheState cacheState = context.read<DownloadUrlCacheState>();
    String? url =
        await cacheState.getDownloadUrl(_user?.profileFireStoragePath);
    if (mounted) {
      setState(() {
        _profilePhotoUrl = url;
      });
    }
  }

  Future<void> _checkSkillRubric(Course? course) async {
    final courseId = course?.id;
    if (courseId == null) {
      if (_checkedCourseId != null || _hasSkillRubric) {
        setState(() {
          _checkedCourseId = null;
          _hasSkillRubric = false;
        });
      }
      return;
    }
    if (_checkedCourseId == courseId) {
      return;
    }
    _checkedCourseId = courseId;
    final SkillRubric? rubric =
        await SkillRubricsFunctions.loadForCourse(courseId);
    final hasRubric =
        rubric != null && rubric.dimensions.any((d) => d.degrees.isNotEmpty);
    if (mounted) {
      setState(() {
        _hasSkillRubric = hasRubric;
      });
    }
  }

  void _toggleRadar() {
    if (_user == null) return;
    setState(() {
      _showRadar = !_showRadar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final libraryState = Provider.of<LibraryState>(context);
      unawaited(_checkSkillRubric(libraryState.selectedCourse));
      final borderColor = _computeBorderColor(libraryState);

      Widget avatar;
      final maxDisplayRadius = _calculateDisplayRadius(constraints);

      if (_showRadar && _user != null) {
        avatar = _buildRadarAvatar(borderColor, maxDisplayRadius);
      } else if (_profilePhotoUrl != null) {
        avatar = _buildAvatarWithImage(
            context, borderColor, maxDisplayRadius, constraints.maxWidth);
      } else {
        avatar = CircleAvatar(
          maxRadius: maxDisplayRadius,
          child: Icon(Icons.photo, size: maxDisplayRadius),
        );
      }

      return GestureDetector(
        onDoubleTap: widget.enableDoubleTapSwitch && _hasSkillRubric
            ? _toggleRadar
            : null,
        onTap: widget.linkToOtherProfile ? _goToOtherProfile : null,
        child: avatar,
      );
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
    Widget avatar =
        _createCircleAvatar(context, maxDisplayRadius, availableWidth);

    if (borderColor != null) {
      final borderWidth = CustomUiConstants.profileBorderWidth;
      avatar = Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth)),
          child: avatar);
    }
    return avatar;
  }

  Widget _buildRadarAvatar(Color? borderColor, double maxDisplayRadius) {
    final borderWidth = CustomUiConstants.profileBorderWidth;
    final diameter = maxDisplayRadius * 2;
    Widget radar = SizedBox(
      width: diameter,
      height: diameter,
      child: RadarWidget(user: _user!, size: diameter, showLabels: false),
    );
    radar = ClipOval(child: radar);
    if (borderColor != null) {
      radar = Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth)),
          child: radar);
    }
    return radar;
  }

  CircleAvatar _createCircleAvatar(
      BuildContext context, double maxDisplayRadius, double availableWidth) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenPhysicalWidth =
        MediaQuery.of(context).size.width * pixelRatio * 0.34;
    final displayDiameter = maxDisplayRadius * 2;
    final physicalWidth = displayDiameter * pixelRatio;
    final resizeWidth = physicalWidth < screenPhysicalWidth
        ? physicalWidth
        : screenPhysicalWidth;

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
