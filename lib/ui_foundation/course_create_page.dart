import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseCreatePage extends StatefulWidget {
  const CourseCreatePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CourseCreateState();
  }
}

class CourseCreateState extends State<CourseCreatePage> {
  final courseNameController = TextEditingController();
  final invitationCodeController = TextEditingController();
  final descriptionController = TextEditingController();

  String? courseNameError;
  String? invitationCodeError;

  bool _isFormComplete = false;

  @override
  void initState() {
    super.initState();

    courseNameController.addListener(_checkFormComplete);
    invitationCodeController.addListener(_checkFormComplete);
    descriptionController.addListener(_checkFormComplete);
  }

  void _checkFormComplete() {
    bool isFormComplete = (courseNameController.text.trim().length >= 3) &&
        (invitationCodeController.text.trim().length >= 3) &&
        (descriptionController.text.trim().length >= 3);

    if (isFormComplete != _isFormComplete) {
      setState(() {
        _isFormComplete = isFormComplete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        floatingActionButton: FloatingActionButton(
            backgroundColor: _isFormComplete
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
            onPressed: _createCourse,
            child: const Icon(Icons.add)),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Consumer2<LibraryState, ApplicationState>(
                    builder:
                        (context, libraryState, applicationState, child) {
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                  topRight: Radius.circular(16.0),
                                ),
                              ),
                              child: Text('Create Course',
                                  style: CustomTextStyles.headline),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  TextField(
                                    decoration: CustomUiConstants
                                        .getFilledInputDecoration(
                                      context,
                                      labelText: 'Course Name',
                                    ).copyWith(errorText: courseNameError),
                                    controller: courseNameController,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: CustomUiConstants
                                        .getFilledInputDecoration(
                                      context,
                                      labelText: 'Invitation Code',
                                    ).copyWith(
                                        errorText: invitationCodeError),
                                    controller: invitationCodeController,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: CustomUiConstants
                                        .getFilledInputDecoration(
                                      context,
                                      labelText: 'Description',
                                    ),
                                    controller: descriptionController,
                                    minLines: 5,
                                    maxLines: null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
  }

  void _createCourse() async {
    // Ignore until the form is complete.
    if (!_isFormComplete) {
      print('Form is not complete');
      return;
    }

    String courseName = courseNameController.text;
    String invitationCode = invitationCodeController.text;
    String description = descriptionController.text;
    print('Attempting to create course $courseName');

    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);

    // Check if the course title already exists.
    if (await libraryState.doesCourseTitleExist(courseName)) {
      setState(() {
        courseNameError = 'Course title already exists';
      });
      return;
    } else {
      setState(() {
        courseNameError = null;
      });
    }

    // Check if the invitation code already exists.
    if (await libraryState.doesInvitationCodeExist(invitationCode)) {
      setState(() {
        invitationCodeError = 'Invitation code already exists';
      });
      return;
    } else {
      setState(() {
        invitationCodeError = null;
      });
    }

    libraryState
        .createPrivateCourse(courseName, invitationCode, description,
            applicationState, libraryState)
        .then((course) {
      if (context.mounted) {
        Navigator.pushNamed(context, NavigationEnum.cmsSyllabus.route);
      }
    });
  }
}
