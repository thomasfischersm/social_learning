import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/level_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class LevelListPage extends StatefulWidget {
  const LevelListPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LevelListState();
  }
}

class LevelListState extends State<LevelListPage> {
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
          return Text('${libraryState.selectedCourse?.title} Curriculum');
        })),
        bottomNavigationBar: const BottomBar(),
        body: Center(
          child: CustomUiConstants.framePage(Consumer<LibraryState>(
              builder: (context, libraryState, child) => Consumer<StudentState>(
                      builder: (context, studentState, child) {
                    List<LevelCompletion> levelCompletions =
                        studentState.getLevelCompletions(libraryState);

                    return SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomUiConstants.getTextPadding(Text(
                          '${libraryState.selectedCourse?.title} Curriculum',
                          style: CustomTextStyles.headline,
                        )),
                        generateLevelList(levelCompletions, libraryState),
                        CustomUiConstants.getTextPadding(Text(
                          '\nStats',
                          style: CustomTextStyles.headline,
                        )),
                        Text(
                          'Lessons practiced: ${studentState.getPracticeCount()}',
                          style: CustomTextStyles.getBody(context),
                        ),
                        Text(
                          'Lessons completed: ${studentState.getGraduationCount()}',
                          style: CustomTextStyles.getBody(context),
                        ),
                        Text(
                          'Lessons taught: ${studentState.getTeachCount()}',
                          style: CustomTextStyles.getBody(context),
                        ),
                        CustomUiConstants.getGeneralFooter(context)
                      ],
                    ));
                  }))),
        ));
  }

  Widget generateLevelList(List<LevelCompletion> levelCompletions, LibraryState libraryState) {
    if (levelCompletions.isEmpty) {
      return Text(
        'Undergoing maintenance - no levels!',
        style: CustomTextStyles.getBody(context),
      );
    }

    List<Widget> children = [];
    for (int i = 0; i < levelCompletions.length; i++) {
      LevelCompletion levelCompletion = levelCompletions[i];
      Level level = levelCompletion.level;

      String levelText = 'Level ${i + 1}: ${level.title}';
      TextStyle? levelTextStyle;
      if (levelCompletion.isLevelGraduated) {
        levelText += ' - Complete';
        levelTextStyle = CustomTextStyles.getFullyLearned(context);
      } else if (levelCompletion.graduatedLessonRawIds.isNotEmpty) {
        levelText +=
            ' - ${levelCompletion.lessonsGraduatedCount}/${levelCompletion.lessonCount} '
            '(${(levelCompletion.lessonsGraduatedCount * 100 / levelCompletion.lessonCount).round()}%)';
        levelTextStyle = CustomTextStyles.getPartiallyLearned(context);
      } else {
        levelTextStyle = CustomTextStyles.getBody(context);
      }

      children.add(InkWell(
          onTap: () {
            var levelId = level.id;
            if (levelId != null) {
              Navigator.pushNamed(context, NavigationEnum.levelDetail.route,
                  arguments: LevelDetailArgument(levelId));
            }
          },
          child: Text(
            levelText,
            style: levelTextStyle,
          )));
    }

    // Show Flex lessons.
    if (libraryState.getUnattachedLessons().isNotEmpty) {
      children.add(InkWell(
        onTap: () {
          Navigator.pushNamed(context, NavigationEnum.levelDetail.route,
              arguments: LevelDetailArgument.flexLessons());
        },
        child: Text('Flex Lessons', style: CustomTextStyles.getBody(context)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  int _getLevelNumber(List<Lesson>? lessons, index) {
    if (lessons == null) {
      return -1;
    }

    int currentLevel = 1;
    for (int i = 0; i < min(index, lessons.length); i++) {
      if (lessons[i].isLevel == true) {
        currentLevel++;
      }
    }

    return currentLevel;
  }
}
