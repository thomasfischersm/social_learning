import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data_support/json_curriculum_sync.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_constants/navigation_enum.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  final TextEditingController _invitationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // LevelMigration.migrate();
    // JsonCurriculumSync.export();
    // JsonCurriculumSync.convertTextToJson(
    //     'acroyoga-origin.txt', '/courses/V4UYTsc7mK4oEHNLFXMU');
    // JsonCurriculumSync.convertTextToJson(
    //     'bachata-origin.txt', '/courses/4ZUgIakaAbcCiVWMxSKb');

    // JsonCurriculumSync.importV2();
    // JsonCurriculumSync.export();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Center(
            child: CustomUiConstants.framePage(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(Text(
              'Learning Labs',
              style: CustomTextStyles.headline,
            )),
            CustomUiConstants.getTextPadding(Text(
              'Learning Labs are a format where you learn hands-on from '
              'the student ahead of you. Then you teach the next '
              'student after you to deepen your own grasp on the '
              'material.\n\n'
              'The app shows you the lessons, tracks your progress, and '
              'matches you up with other students during sessions.',
              style: CustomTextStyles.getBody(context),
            )),
            CustomUiConstants.getDivider(),
            CustomUiConstants.getTextPadding(Text(
              'Courses',
              style: CustomTextStyles.headline,
            )),
            _generateCourseList(context),
            CustomUiConstants.getTextPadding(Text('Join a private course',
                style: CustomTextStyles.subHeadline)),
            Row(
              children: [
                Expanded(child:TextField(
                  controller: _invitationCodeController,
                  decoration:
                      const InputDecoration(hintText: 'Invitation code'),
                )),
                TextButton(
                  onPressed: () => _joinPrivateCourse(context),
                  child: const Text('Join'),
                )
              ],
            ),
            CustomUiConstants.getDivider(),
            CustomUiConstants.getTextPadding(Text(
                'Create your own private course',
                style: CustomTextStyles.subHeadline)),
            GestureDetector(
                onTap: () {
                  _createCourse();
                },
                child: Row(
                  children: [
                    Flexible(
                        child: CustomUiConstants.getTextPadding(Text(
                            'You can create your own course to teach a subject, for a special event workshop, or corporate in-house training. Your course will be private by default and only accessible through an invitation code.',
                            style: CustomTextStyles.getBody(context)))),
                    Column(children: [
                      const Icon(Icons.start),
                      Text(
                        'create',
                        style: CustomTextStyles.getBody(context),
                      )
                    ]),
                  ],
                )),
            CustomUiConstants.getDivider(),
            CustomUiConstants.getGeneralFooter(context, withDivider: false)
          ],
        ))));
  }

  _generateCourseList(BuildContext context) {
    return Consumer<LibraryState>(builder: (context, libraryState, child) {
      var children = <Widget>[];
      for (Course course in libraryState.availableCourses) {
        String pureText;
        String? linkText;

        int index = course.description.indexOf('http');
        if (index >= 0) {
          pureText =
              course.description.substring(0, index).replaceAll('\\n', '\n');
          linkText = course.description.substring(index);
        } else {
          pureText = course.description.replaceAll('\\n', '\n');
        }

        Column textColumn =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            child: CustomUiConstants.getTextPadding(
                Text(course.title, style: CustomTextStyles.subHeadline)),
            onTap: () {
              _openCourse(course, libraryState);
            },
          ),
          CustomUiConstants.getRichTextPadding(RichText(
              text: TextSpan(children: [
            TextSpan(style: CustomTextStyles.getBody(context), text: pureText),
            if (linkText != null)
              WidgetSpan(
                  child: RichText(
                      text: TextSpan(
                          text: linkText,
                          style: CustomTextStyles.getLink(context),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launchUrl(Uri.parse(linkText!));
                            })))
          ]))),
          CustomUiConstants.getDivider(),
        ]);

        Column actionColumn = Column(children: [
          const Icon(Icons.start),
          Text(
            'open',
            style: CustomTextStyles.getBody(context),
          )
        ]);

        Row row = Row(
          children: [
            Flexible(child: textColumn),
            GestureDetector(
              child: actionColumn,
              onTap: () {
                _openCourse(course, libraryState);
              },
            )
          ],
        );

        children.add(row);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    });
  }

  _openCourse(Course course, LibraryState libraryState) {
    libraryState.selectedCourse = course;
    Navigator.pushNamed(context, NavigationEnum.levelList.route);
  }

  _createCourse() {
    Navigator.pushNamed(context, NavigationEnum.createCourse.route);
  }

  _joinPrivateCourse(BuildContext context) async {
    // Join the private course.
    LibraryState libraryState = Provider.of<LibraryState>(context, listen: false);
    Course? course = await libraryState.joinPrivateCourse(_invitationCodeController.text);
    print('Joined course: ${course?.title}');

    if (course == null) {
      Fluttertoast.showToast(
        msg: "The invitation code doesn't exist.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Navigate to the curriculum of the private course.
    if (context.mounted) {
      print('The currently selected course is ${libraryState.selectedCourse?.title}');
      Navigator.pushNamed(context, NavigationEnum.levelList.route);
      print('Navigated to curriculum');
    }
    // TODO: The page switch isn't working yet.
  }
}
