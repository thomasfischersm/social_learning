import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: const BottomBar(),
        body: Center(
            child: CustomUiConstants.framePage(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(
                Text('Create Course', style: CustomTextStyles.headline)),
            Consumer<LibraryState>(
              builder: (context, libraryState, child) {
                return Consumer<ApplicationState>(
                    builder: (context, applicationState, child) {
                  return Table(columnWidths: const <int, TableColumnWidth>{
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  }, children: <TableRow>[
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Course name:')),
                      TextField(controller: courseNameController),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Invitation code:')),
                      TextField(controller: invitationCodeController),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Description:')),
                      TextField(controller: descriptionController, minLines: 5, maxLines: null,),
                    ]),
                  ]);
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      _createCourse(
                          context,
                          courseNameController.text,
                          invitationCodeController.text,
                          descriptionController.text);
                    },
                    child: const Text('Create')),
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.sessionHome.route),
                    child: const Text('Cancel'))
              ],
            )
          ],
        ))));
  }

  void _createCourse(BuildContext context, String courseName,
      String invitationCode, String description) {
    print('Attempting to create course $courseName');

    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    var libraryState = Provider.of<LibraryState>(context, listen: false);

    libraryState
        .createPrivateCourse(courseName, invitationCode, description,
            applicationState, libraryState)
        .then((course) {

      Navigator.pushNamed(context, NavigationEnum.cmsSyllabus.route);
    });
  }
}
