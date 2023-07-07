import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/graduation_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class LevelDetailArgument {
  String levelId;

  LevelDetailArgument(this.levelId);
}

class LevelDetailPage extends StatefulWidget {
  const LevelDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LevelDetailState();
  }
}

class LevelDetailState extends State<LevelDetailPage> {
  @override
  Widget build(BuildContext context) {
    if (Provider.of<LibraryState>(context, listen: false).selectedCourse ==
        null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.pushNamed(context, NavigationEnum.home.route);
      });
    }

    return Scaffold(
        appBar: AppBar(title:
            Consumer<LibraryState>(builder: (context, libraryState, child) {
          LevelDetailArgument? argument = ModalRoute.of(context)!
              .settings
              .arguments as LevelDetailArgument?;
          var levelId = argument?.levelId;
          if (levelId != null) {
            Level? level = libraryState.findLevel(levelId);
            if (level != null) {
              int levelPosition = libraryState.findLevelPosition(level);
              return Text('Level ${levelPosition + 1}: ${level.title}');
            }
          }
          return const Text('Failed to load');
        })),
        bottomNavigationBar: const BottomBar(),
        body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              padding: const EdgeInsets.all(5.0 * 3.1),
              child: Consumer<LibraryState>(
                  builder: (context, libraryState, child) =>
                      Consumer<StudentState>(
                          builder: (context, studentState, child) {
                        LevelDetailArgument? argument = ModalRoute.of(context)!
                            .settings
                            .arguments as LevelDetailArgument?;
                        var levelId = argument?.levelId;
                        if (levelId == null) {
                          return const Text('Failed to load (1).');
                        }
                        Level? level = libraryState.findLevel(levelId);
                        if (level == null) {
                          return const Text('Failed to load (2).');
                        }
                        int levelPosition =
                            libraryState.findLevelPosition(level);

                        return SingleChildScrollView(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomUiConstants.getTextPadding(Text(
                              'Level ${levelPosition + 1}: ${level.title}',
                              style: CustomTextStyles.subHeadline,
                            )),
                            CustomUiConstants.getTextPadding(Text(
                              level.description ?? '',
                              style: CustomTextStyles.getBody(context),
                            )),
                            generateLessonList(
                                level, libraryState, studentState),
                            CustomUiConstants.getTextPadding(Text(
                              '',
                              style: CustomTextStyles.getBody(context),
                            )),
                            CustomUiConstants.getDivider(),
                            CustomUiConstants.getTextPadding(Text(
                              'P = Practiced lesson, T = Taught lesson',
                              style: CustomTextStyles.getBody(context),
                            )),
                            CustomUiConstants.getGeneralFooter(context)
                          ],
                        ));
                      }))),
        ));
  }

  Widget generateLessonList(
      Level level, LibraryState libraryState, StudentState studentState) {
    Iterable<Lesson> lessons = libraryState.getLessonsByLevel(level.id!);

    List<Widget> children = [];
    for (Lesson lesson in lessons) {
      List<Widget> columnChildren = [];

      LessonCount lessonCount = studentState.getCountsForLesson(lesson);
      TextStyle? textStyle;
      if (lessonCount.isGraduated) {
        textStyle = CustomTextStyles.getFullyLearned(context);
      } else if (lessonCount.practiceCount > 0) {
        textStyle = CustomTextStyles.getPartiallyLearned(context);
      } else {
        textStyle = CustomTextStyles.getBody(context);
      }

      TextStyle? emphasizedTextStyle =
          textStyle?.copyWith(fontWeight: FontWeight.bold);

      var text = lesson.title;
      if (lessonCount.teachCount > 0) {
        text +=
            ' (P:${lessonCount.practiceCount}, T:${lessonCount.teachCount})';
      } else if (lessonCount.practiceCount > 0) {
        text += ' (P:${lessonCount.practiceCount})';
      }
      columnChildren.add(Row(
        children: [
          Text(
            text,
            style: emphasizedTextStyle,
          ),
          if (lessonCount.isGraduated) Icon(Icons.workspace_premium, color: CustomTextStyles.fullyLearnedColor)
        ],
      ));
      // if ((lesson.synopsis != null) && (lesson.synopsis!.isNotEmpty)) {
      columnChildren.add(Text('${lesson.synopsis}\n'));
      // }

      children.add(InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren,
        ),
        onTap: () {
          Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
              arguments: LessonDetailArgument(lesson.id!));
        },
      ));
    }

    print('Done generate lesson list');
    if (1 == 2) return Text('Test');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
