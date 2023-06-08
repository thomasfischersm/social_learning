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
          LevelDetailArgument? argument =
          ModalRoute.of(context)!.settings.arguments as LevelDetailArgument?;
          Level? level = libraryState.findLevel(argument?.levelId);
          int levelPosition = libraryState.findLevelPosition(level);
          return Text('Level ${levelPosition}: ${level.title}');
        })),
        bottomNavigationBar: const BottomBar(),
        body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              child: Consumer<LibraryState>(
                  builder: (context, libraryState, child) =>
                      Consumer<StudentState>(
                          builder: (context, studentState, child) {
                            List<LevelCompletion> levelCompletions =
                            studentState.getLevelCompletions(libraryState);

                            return Row(
                              children: [
                                CustomUiConstants.getTextPadding(Text(
                                  '${libraryState.selectedCourse?.title} Curriculum',
                                  style: CustomTextStyles.headline,
                                )),
                                generateLevelList(levelCompletions),
                                CustomUiConstants.getTextPadding(Text(
                                  '\nStats',
                                  style: CustomTextStyles.headline,
                                )),
                                Text('Lessons practiced: ${studentState.getPracticeCount()}', style: CustomTextStyles.getBody(context),),
                                Text('Lessons completed: ${studentState.getGraduationCount()}', style: CustomTextStyles.getBody(context),),
                                Text('Lessons taught: ${studentState.getTeachCount()}', style: CustomTextStyles.getBody(context),),
                              ],
                            );
                          }))),
        ));
  }

  ListView generateLevelList(List<LevelCompletion> levelCompletions) {
    return ListView.builder(
        itemCount: levelCompletions.length,
        itemBuilder: (context, index) {
          var levelCompletion = levelCompletions[index];
          Level level = levelCompletion.level;

          String levelText = 'Level ${index + 1}: ${level.title}';
          TextStyle? levelTextStyle;
          if (levelCompletion.isLevelGraduated) {
            levelText += ' - Complete';
            levelTextStyle = CustomTextStyles.getFullyLearned(context);
          } else if (levelCompletion.graduatedLessonIds.length > 0) {
            levelText +=
            ' - ${levelCompletion.lessonsGraduatedCount}/${levelCompletion.lessonCount} '
                '(${levelCompletion.lessonsGraduatedCount * 100 / levelCompletion.lessonCount}%)';
            levelTextStyle = CustomTextStyles.getPartiallyLearned(context);
          } else {
            levelTextStyle = CustomTextStyles.getBody(context);
          }

          return InkWell(
              onTap: () {
                if (level != null) {
                  Navigator.pushNamed(context, NavigationEnum.levelDetail.route,
                      arguments: LevelDetailArgument(level.id));
                }
              },
              child: Text(
                levelText,
                style: levelTextStyle,
              ));
        });
  }

  int _getLevelNumber(List<Lesson>? lessons, index) {
    if (lessons == null) {
      return -1;
    }

    int currentLevel = 1;
    for (int i = 0; i < min(index, lessons.length); i++) {
      if (lessons[i].isLevel) {
        currentLevel++;
      }
    }

    return currentLevel;
  }
}
