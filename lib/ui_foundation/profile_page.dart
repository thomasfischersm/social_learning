import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/enable_location_button.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_lookup_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_progress_video_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_text_editor.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/download_url_cache_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/radar_widget.dart';
import 'package:social_learning/ui_foundation/view_skill_assessment_page.dart';

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
  bool _hasSkillRubric = false;
  String? _checkedCourseId;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(),
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

            final libraryState = Provider.of<LibraryState>(context);
            unawaited(_checkSkillRubric(libraryState.selectedCourse));
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
                              onTap: _pickProfileImage,
                              child: Stack(children: [
                                ProfileImageWidgetV2.fromUser(currentUser,
                                    enableDoubleTapSwitch: false),
                                const Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Icon(Icons.edit, color: Colors.grey))
                              ]),
                            ))),
                    if (_hasSkillRubric) ...[
                      const SizedBox(width: 4),
                      Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              ViewSkillAssessmentPageArgument.navigateTo(
                                  context, currentUser.uid);
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = constraints.biggest.shortestSide;
                                return Stack(children: [
                                  Center(
                                    child: SizedBox(
                                        width: size,
                                        height: size,
                                        child: RadarWidget(
                                          user: currentUser,
                                          size: size,
                                          showLabels: false,
                                        )),
                                  ),
                                  const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(Icons.remove_red_eye,
                                          color: Colors.grey))
                                ]);
                              },
                            ),
                          ))
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                      onTap: () =>
                          showDisplayNameDialog(context, applicationState),
                      child: Row(children: [
                        Text(
                          applicationState.userDisplayName ??
                              '<pick a display name>',
                          style: CustomTextStyles.subHeadline,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, color: Colors.grey),
                      ])),
                ),
                ProfileTextEditor(applicationState),
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
                      icon: Icon(Icons.edit, color: Colors.grey)),
                ]),
                Row(children: [
                  const SizedBox(width: 10),
                  Text('Calendly: ', style: CustomTextStyles.getBody(context)),
                  InkWell(
                      onTap: () => _openCalendlyUrl(context, applicationState),
                      child: Text(currentUser.calendlyHandle ?? '<enter>',
                          style: CustomTextStyles.getBody(context))),
                  IconButton(
                      onPressed: () =>
                          _editCalendlyUrl(context, applicationState),
                      icon: Icon(Icons.edit, color: Colors.grey)),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ValueInputDialog(
          'Edit your display name',
          applicationState.userDisplayName ?? '', // Default value
          'Princess Fedora',
          'OK',
          (value) {
            if (value == null || (value.trim().length < 3)) {
              return 'Your display name is too short.';
            }
            return null; // No error
          },
          (newValue) {
            // Handle confirmed new value
            applicationState.userDisplayName = newValue;
          },
        );
      },
    );
  }

  void showDisplayNameDialog2(
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
              ElevatedButton(
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

  void _pickProfileImage() async {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    // Pick the photo from the user.
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    int length = await file?.length() ?? -1;

    // Upload the photo to Firebase.
    if (file != null) {
      String userId = auth.FirebaseAuth.instance.currentUser?.uid ?? '';
      String fireStoragePath = '/users/$userId/profilePhoto';
      String thumbnailFireStoragePath = '/users/$userId/profilePhotoThumbnail';
      String tinyFireStoragePath = '/users/$userId/profilePhotoTiny';
      Reference storageRef = FirebaseStorage.instance.ref(fireStoragePath);
      Reference thumbnailRef =
          FirebaseStorage.instance.ref(thumbnailFireStoragePath);
      Reference tinyRef = FirebaseStorage.instance.ref(tinyFireStoragePath);
      // var storageRef = FirebaseStorage.instance.ref().child(
      //     '/profilePhoto');
      // var uploadTask = await storageRef.putFile(File(file.path));
      Uint8List imageData = await file.readAsBytes();
      Uint8List thumbnailData = await _buildResizedImageBytes(imageData, 320);
      Uint8List tinyData = await _buildResizedImageBytes(imageData, 80);
      await storageRef.putData(
          imageData, SettableMetadata(contentType: file.mimeType));
      await thumbnailRef.putData(
          thumbnailData, SettableMetadata(contentType: 'image/jpeg'));
      await tinyRef.putData(
          tinyData, SettableMetadata(contentType: 'image/jpeg'));
      UserFunctions.updateProfilePhotoPaths(
          fireStoragePath, thumbnailFireStoragePath, tinyFireStoragePath);

      if (mounted) {
        DownloadUrlCacheState cacheState =
            context.read<DownloadUrlCacheState>();
        cacheState.invalidate(fireStoragePath);
        cacheState.invalidate(thumbnailFireStoragePath);
        cacheState.invalidate(tinyFireStoragePath);
      }

      applicationState.invalidateProfilePhoto();

      // Note: Old photos don't have to be deleted because the new photo is
      // saved to the same cloud storage path.
    }
  }

  Future<Uint8List> _buildResizedImageBytes(
      Uint8List imageData, int targetDimension) async {
    img.Image? decoded = img.decodeImage(imageData);
    if (decoded == null) {
      return imageData;
    }
    int targetWidth;
    int targetHeight;
    if (decoded.width <= decoded.height) {
      targetWidth = targetDimension;
      targetHeight = (decoded.height * targetDimension / decoded.width).round();
    } else {
      targetHeight = targetDimension;
      targetWidth = (decoded.width * targetDimension / decoded.height).round();
    }
    if (targetWidth >= decoded.width || targetHeight >= decoded.height) {
      return img.encodeJpg(decoded, quality: 100);
    }
    img.Image resized = img.copyResize(decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic);
    return img.encodeJpg(resized, quality: 100);
  }

  Future<Uint8List> _buildResizedImageBytesSkia(
    Uint8List imageData,
    int targetDimension,
  ) async {
    // Decode via Skia
    final ui.Codec codec = await ui.instantiateImageCodec(imageData);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image src = frame.image;

    // Compute aspect-correct target size (match your logic)
    int targetWidth;
    int targetHeight;
    if (src.width <= src.height) {
      targetWidth = targetDimension;
      targetHeight = (src.height * targetDimension / src.width).round();
    } else {
      targetHeight = targetDimension;
      targetWidth = (src.width * targetDimension / src.height).round();
    }

    // Avoid upscaling (match your behavior)
    if (targetWidth >= src.width || targetHeight >= src.height) {
      // Your code re-encodes to JPEG(100) even if no resize.
      // If you *really* want that, do it here:
      final byteData = await src.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return imageData;

      final pngBytes = byteData.buffer.asUint8List();
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) return imageData;

      return Uint8List.fromList(img.encodeJpg(decoded, quality: 100));
      // Better option (usually): return imageData;
    }

    // Draw scaled using Skia
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;

    final srcRect =
        ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble());
    final dstRect =
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());

    canvas.drawImageRect(src, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    final ui.Image dst = await picture.toImage(targetWidth, targetHeight);

    // Extract bytes. Use PNG as an intermediate (Skia can encode PNG).
    final dstByteData = await dst.toByteData(format: ui.ImageByteFormat.png);
    if (dstByteData == null) return imageData;

    final Uint8List dstPngBytes = dstByteData.buffer.asUint8List();

    // Convert PNG -> JPEG using `image` package
    final img.Image? decodedDst = img.decodeImage(dstPngBytes);
    if (decodedDst == null) return imageData;

    return Uint8List.fromList(img.encodeJpg(decodedDst, quality: 100));
  }

  Future<void> _deleteExistingImage(Reference imageRef) async {
    try {
      await imageRef.delete();
    } catch (error) {
      if (error is FirebaseException && error.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }

  void _toogleIsPrivateProfile(
      BuildContext context, ApplicationState applicationState) {
    applicationState.setIsProfilePrivate(
        !applicationState.currentUser!.isProfilePrivate, applicationState);
  }

  void _editInstagramHandle(
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

  void _editCalendlyUrl(
      BuildContext context, ApplicationState applicationState) {
    TextEditingController textFieldController =
        TextEditingController(text: applicationState.currentUser?.calendlyUrl);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enter a new Calendly URL"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: textFieldController,
                decoration:
                    const InputDecoration(hintText: 'https://calendly.com/...'),
              ),
              Text('Tip: Offer office hours to learners all over the world.',
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
                  UserFunctions.updateCalendlyUrl(
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

  void _openInstagram(
      BuildContext context, ApplicationState applicationState) async {
    User? currentUser = applicationState.currentUser;

    await UserFunctions.openInstaProfile(currentUser);
  }

  void _openCalendlyUrl(
      BuildContext context, ApplicationState applicationState) async {
    User? currentUser = applicationState.currentUser;

    await UserFunctions.openCalendlyUrl(currentUser);
  }
}
