import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class LevelDetailArgument {
  String? levelId;
  bool isFlexLessons = false;

  LevelDetailArgument(this.levelId);

  LevelDetailArgument.flexLessons() {
    isFlexLessons = true;
  }
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
          } else if (argument?.isFlexLessons == true) {
            return const Text('Flex Lessons');
          }
          return const Text('Failed to load');
        })),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(
              enableCourseLoadingGuard: true,
              Consumer2<LibraryState, StudentState>(
                  builder: (context, libraryState, studentState, child) {
                LevelDetailArgument? argument = ModalRoute.of(context)!
                    .settings
                    .arguments as LevelDetailArgument?;
                var levelId = argument?.levelId;
                var isFlexLessons = argument?.isFlexLessons;
                if ((levelId == null) && (isFlexLessons != true)) {
                  return const Text('Failed to load (1).');
                }

                if (isFlexLessons == true) {
                  return _generateFlexLessonView(
                      libraryState, studentState);
                } else {
                  return _generateRegularLessonView(
                      levelId!, libraryState, studentState);
                }
              })),
        ));
  }

  _generateRegularLessonView(
      String levelId, LibraryState libraryState, StudentState studentState) {
    Level? level = libraryState.findLevel(levelId);
    if (level == null) {
      return const Text('Failed to load (2).');
    }
    int levelPosition = libraryState.findLevelPosition(level);
    Iterable<Lesson> lessons = libraryState.getLessonsByLevel(level.id!);

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
        generateLessonList(lessons, libraryState, studentState),
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
  }

  _generateFlexLessonView(
      LibraryState libraryState, StudentState studentState) {
    Iterable<Lesson> lessons = libraryState.getUnattachedLessons();

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomUiConstants.getTextPadding(Text(
          'Flex Lessons',
          style: CustomTextStyles.subHeadline,
        )),
        CustomUiConstants.getTextPadding(const Text(
          'These are optional lessons that enrich the learning experience, allow deeper dives into topics, or supplement specific student needs.',
        )),
        generateLessonList(lessons, libraryState, studentState),
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
  }

  Widget generateLessonList(
      Iterable<Lesson> lessons, LibraryState libraryState, StudentState studentState) {
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
          Flexible(
              child: Text(
            text,
            style: emphasizedTextStyle,
          )),
          if (lessonCount.isGraduated)
            Icon(Icons.workspace_premium,
                color: CustomTextStyles.fullyLearnedColor)
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
    if (1 == 2) return const Text('Test');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
