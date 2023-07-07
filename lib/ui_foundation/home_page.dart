import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data_support/Json_curriculum_sync.dart';
import 'package:social_learning/data_support/level_migration.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_enum.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
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
        bottomNavigationBar: const BottomBar(),
        body: Center(
            child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 310, maxHeight: 350),
                padding: const EdgeInsets.all(5.0 * 3.1),
                child: SingleChildScrollView(
                    child: Column(
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
                    CustomUiConstants.getGeneralFooter(context, withDivider: false)
                  ],
                )))));
  }

  _generateCourseList(BuildContext context) {
    return Consumer<LibraryState>(builder: (context, libraryState, child) {
      var children = <Widget>[];
      for (Course course in libraryState.availableCourses) {
        int index = course.description.indexOf('http');
        String pureText =
            course.description.substring(0, index).replaceAll('\\n', '\n');
        String linkText = course.description.substring(index);

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
            WidgetSpan(
                child: RichText(
                    text: TextSpan(
                        text: linkText,
                        style: CustomTextStyles.getLink(context),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(Uri.parse(linkText));
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
}
