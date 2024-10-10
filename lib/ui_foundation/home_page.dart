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
  final TextEditingController _invitationCodeController =
      TextEditingController();

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
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createAppHeading(),
                _createCoursesCard(),
                SizedBox(height: 8),
                _createJoinPrivateCourseCard(),

                CustomUiConstants.getDivider(),
                CustomUiConstants.getGeneralFooter(context, withDivider: false)
              ],
            ))));
  }

  Widget _createAppHeading() {
    return ExpansionTile(
        tilePadding: EdgeInsets.only(left: 16),
        trailing: SizedBox.shrink(),
        title: Row(
          children: [
            Text(
              'Learning Labs ',
              style: CustomTextStyles.headline,
            ),
            Icon(Icons.info_outline)
          ],
        ),
        children: [
          Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Learning Labs are a format where you learn hands-on from '
                'the student ahead of you. Then you teach the next '
                'student after you to deepen your own grasp on the '
                'material.\n\n'
                'The app shows you the lessons, tracks your progress, and '
                'matches you up with other students during sessions.',
                style: CustomTextStyles.getBody(context),
              )),
        ]);
  }

  Widget _createCoursesCard() {
    return Card(
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
                )),
            child: Text('Courses',
                style:
                    CustomTextStyles.subHeadline.copyWith(color: Colors.white)),
          ),
          Consumer<LibraryState>(builder: (context, libraryState, child) {
            return Column(
                children: libraryState.availableCourses
                    .map((course) => _createCourseWidget(course, libraryState))
                    .toList());
          }),
        ],
      ),
    );
  }

  Widget _createCourseWidget(Course course, LibraryState libraryState) {
    // Prepare the text.
    String pureText;
    String? linkText;

    int index = course.description.indexOf('http');
    if (index >= 0) {
      pureText = course.description.substring(0, index).replaceAll('\\n', '\n');
      linkText = course.description.substring(index);
    } else {
      pureText = course.description.replaceAll('\\n', '\n');
    }

    return Row(children: [
      Flexible(
          child: ExpansionTile(
        trailing: SizedBox.shrink(),
        tilePadding: EdgeInsets.only(left: 8),
        childrenPadding: EdgeInsets.only(left: 8),
        title: Row(children: [
          Text(
            '${course.title} ',
            style: CustomTextStyles.subHeadline,
          ),
          Icon(Icons.info_outline)
        ]),
        children: [
          RichText(
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
          ]))
        ],
      )),
      IconButton(
          onPressed: () => _openCourse(course, libraryState),
          icon: Icon(Icons.start))
    ]);
  }

  Widget _createJoinPrivateCourseCard() {
    return Card(
        child: Column(children: [
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
        child: Text(
          'Join A Private Course',
          style: CustomTextStyles.subHeadline.copyWith(color: Colors.white),
        ),
      ),
      Padding(
          padding: EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invitationCodeController,
                  decoration:
                      const InputDecoration(hintText: 'Invitation code'),
                ),
              ),
              TextButton(
                onPressed: () => _joinPrivateCourse(context),
                child: const Text('Join'),
              )
            ],
          )),
      Row(
        children: [
          Flexible(
              child: Padding(padding: EdgeInsets.all(8),child:ExpansionTile(
                  trailing: SizedBox.shrink(),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.only(bottom: 8),
                  title: Row(children: [
                    Text('Create a private course ',
                        style: CustomTextStyles.getBody(context)),
                    Icon(Icons.info_outline)
                  ]),
                  children: [
                Text(
                    'You can create your own course to teach a subject, for a special event workshop, or corporate in-house training. Your course will be private by default and only accessible through an invitation code.',
                    style: CustomTextStyles.getBody(context))
              ]))),
          Padding(padding: EdgeInsets.only(right:8), child:InkWell(
              onTap: _createCourse,
              child: Column(children: [
                const Icon(Icons.start),
                Text(
                  'create',
                  style: CustomTextStyles.getBody(context),
                )
              ])))
        ],
      ),
    ]));
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
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    Course? course =
        await libraryState.joinPrivateCourse(_invitationCodeController.text);
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
      print(
          'The currently selected course is ${libraryState.selectedCourse?.title}');
      Navigator.pushNamed(context, NavigationEnum.levelList.route);
      print('Navigated to curriculum');
    }
    // TODO: The page switch isn't working yet.
  }
}
