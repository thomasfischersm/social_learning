import 'package:flutter/material.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class ProfileComparisonTable extends StatefulWidget {
  final User? otherUser;
  final Iterable<String> currentUserGraduatedLessonIds;
  final Iterable<String> otherUserGraduatedLessonIds;
  final LibraryState libraryState;

  const ProfileComparisonTable(
      this.otherUser,
      this.currentUserGraduatedLessonIds,
      this.otherUserGraduatedLessonIds,
      this.libraryState,
      {super.key});

  @override
  ProfileComparisonTableState createState() => ProfileComparisonTableState();
}

class ProfileComparisonTableState extends State<ProfileComparisonTable> {
  static const flexLevelId = 'flex';

  String? _expandedLevelId;

  @override
  void initState() {
    super.initState();

    // Find the first level where the students can learn from each other.
    _expandedLevelId = findInitialLevel();
  }

  String? findInitialLevel() {
    // Find the first level where the students can learn from each other.
    for (Level level in widget.libraryState.levels ?? []) {
      String? levelId = level.id;
      if (levelId != null) {
        for (Lesson lesson in widget.libraryState.getLessonsByLevel(levelId)) {
          String? lessonId = lesson.id;
          if (lessonId != null) {
            bool currentUserGraduated =
                widget.currentUserGraduatedLessonIds.contains(lessonId);
            bool otherUserGraduated =
                widget.otherUserGraduatedLessonIds.contains(lessonId);

            bool canTeach = currentUserGraduated && !otherUserGraduated;
            bool canLearn = !currentUserGraduated && otherUserGraduated;

            if (canTeach || canLearn) {
              return levelId;
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    User? otherUser = widget.otherUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth()
            },
            children: [
              ...buildLevelRows(context),
            ],
          ),
        ),
      ),
    );
  }

  List<TableRow> buildLevelRows(BuildContext context) {
    List<TableRow> rows = [];
    for (Level level in widget.libraryState.levels ?? []) {
      String? levelId = level.id;
      if (levelId != null) {
        rows.add(TableRow(children: [
          InkWell(
              onTap: () => _toggleLevel(levelId),
              child: Row(children: [
                if (_expandedLevelId == levelId)
                  const Icon(Icons.arrow_drop_down)
                else
                  const Icon(Icons.arrow_right),
                Flexible(   // <-- bounds the Text to the remaining space
                  child: Text(
                    level.title,
                    style: CustomTextStyles.subHeadline
                        .copyWith(fontWeight: FontWeight.bold),
                    softWrap: true,             // allow breaking
                    maxLines: 2,                // up to two lines (or null = unlimited)
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ])),
          const SizedBox.shrink()
        ]));

        if (_expandedLevelId == levelId) {
          rows.addAll(_buildLessonRows(
              context, widget.libraryState.getLessonsByLevel(levelId)));
        }
      }
    }

    // Handle flex lessons.
    if (widget.libraryState.getUnattachedLessons().isNotEmpty) {
      rows.add(TableRow(children: [
        InkWell(
            onTap: () => _toggleLevel(flexLevelId),
            child: Row(children: [
              if (_expandedLevelId == flexLevelId)
                const Icon(Icons.arrow_drop_down)
              else
                const Icon(Icons.arrow_right),
              Text('Flex Lessons',
                  style: CustomTextStyles.subHeadline
                      .copyWith(fontWeight: FontWeight.bold)),
            ])),
        const SizedBox.shrink()
      ]));

      if (_expandedLevelId == flexLevelId) {
        rows.addAll(_buildLessonRows(
            context, widget.libraryState.getUnattachedLessons()));
      }
    }

    return rows;
  }

  _toggleLevel(String levelId) {
    setState(() {
      if (_expandedLevelId == levelId) {
        _expandedLevelId = null;
      } else {
        _expandedLevelId = levelId;
      }
    });
  }

  Iterable<TableRow> _buildLessonRows(
      BuildContext context, Iterable<Lesson> lessons) {
    List<TableRow> rows = [];

    for (Lesson lesson in lessons) {
      String? lessonId = lesson.id;
      if (lessonId != null) {
        bool currentUserGraduated =
            widget.currentUserGraduatedLessonIds.contains(lessonId);
        bool otherUserGraduated =
            widget.otherUserGraduatedLessonIds.contains(lessonId);

        bool canTeach = currentUserGraduated && !otherUserGraduated;
        bool canLearn = !currentUserGraduated && otherUserGraduated;
        bool canPractice = currentUserGraduated && otherUserGraduated;

        Widget actionButton;
        if (canTeach) {
          actionButton = _createActionButton(
              context, 'Teach', const Color(0xFFEEC8A8), lessonId);
        } else if (canLearn) {
          actionButton = _createActionButton(
              context, 'Learn', const Color(0xFFBFD7EA), lessonId);
        } else if (canPractice) {
          actionButton =
              _createActionButton(context, 'Practice', Colors.grey, lessonId);
        } else {
          // Invisible button to keep the same size.
          actionButton = const TextButton(
            onPressed: null, // Makes the button non-functional
            child: Text(
              'Practice',
              style: TextStyle(
                  color: Colors.transparent), // Makes the text invisible
            ),
          );
        }

        rows.add(TableRow(children: [
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                  padding:
                      EdgeInsets.only(left: IconTheme.of(context).size ?? 24),
                  child: InkWell(
                      onTap: () => _goToLesson(lessonId),
                      child: Text(lesson.title,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTextStyles.getBody(context))))),
          Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: actionButton),
        ]));
      }
    }

    return rows;
  }

  TextButton _createActionButton(
      BuildContext context, String text, Color color, String lessonId) {
    return TextButton(
        style: TextButton.styleFrom(backgroundColor: color),
        onPressed: () => _goToLesson(lessonId),
        child: Text(text, style: CustomTextStyles.getBody(context)));
  }

  _goToLesson(String lessonId) {
    Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
        arguments: LessonDetailArgument(lessonId));
  }
}
