import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class LessonTableCell extends StatefulWidget {
  final Lesson? lesson;
  final User? mentor;
  final User? mentee;
  final SessionPairing sessionPairing;
  final bool isEditable;
  final String selectHintText;
  final OrganizerSessionState organizerSessionState;

  const LessonTableCell(
      this.lesson,
      this.mentor,
      this.mentee,
      this.sessionPairing,
      this.isEditable,
      this.selectHintText,
      this.organizerSessionState,
      {super.key});

  @override
  LessonTableCellState createState() => LessonTableCellState();
}

class LessonTableCellState extends State<LessonTableCell> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isEditable) {
      if (widget.lesson != null) {
        // Read-only cell
        return _buildReadonlyCell(false);
      } else {
        // Empty cell
        return SizedBox.shrink();
      }
    } else {
      if (widget.lesson != null) {
        // Deletable cell
        return _buildReadonlyCell(true);
      } else {
        // Editable cell
        return _buildEditableCell();
      }
    }
  }

  Widget _buildReadonlyCell(bool showDeleteButton) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: (Row(
          children: [
            Flexible(child:InkWell(
                onTap: () => _goToLesson(widget.lesson),
                child: Text(
                  widget.lesson?.title ?? '',
                  softWrap: true,
                  maxLines: null,
                ))),
            if (showDeleteButton) _createRemoveButton(removeLesson, context)
          ],
        )));
  }

  Widget _createRemoveButton(Function removeFunction, BuildContext context) {
    return InkWell(
        onTap: () => removeFunction(),
        child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.remove_circle_outline_rounded,
                color: Colors.blue,
                size:
                    Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0)));
  }

  _goToLesson(Lesson? lesson) {
    String? lessonId = lesson?.id;
    if (lessonId != null) {
      LessonDetailArgument.goToLessonDetailPage(context, lessonId);
    }
  }

  Widget _buildEditableCell() {
    return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: DropdownMenu<Lesson?>(
          dropdownMenuEntries: getSelectableLessons(),
          hintText: widget.selectHintText,
          onSelected: (Lesson? selectedLesson) => selectLesson(selectedLesson),
        ));
  }

  void removeLesson() {
    widget.organizerSessionState.removeLesson(widget.sessionPairing);
  }

  void selectLesson(Lesson? selectedLesson) {
    if (selectedLesson != null) {
      widget.organizerSessionState
          .updateLesson(selectedLesson, widget.sessionPairing);
    }
  }

  List<DropdownMenuEntry<Lesson?>> getSelectableLessons() {
    // Use levels as non-selectable entries to organize the menu.
    // Only show levels if the user can actually learn them.

    List<DropdownMenuEntry<Lesson?>> entries = [];
    BoolByReference hasBestLessonOccurred =
        BoolByReference(widget.mentee == null);
    LibraryState libraryState = Provider.of<LibraryState>(context, listen: false);

    var levels = libraryState.levels;
    if (levels != null) {
      for (Level level in levels) {
        String? levelId = level.id;
        if (levelId == null) {
          continue;
        }

        Iterable<Lesson> lessons = libraryState.getLessonsByLevel(levelId);
        List<DropdownMenuEntry<Lesson?>> levelEntries =
            getEntriesForLevel(level.title, lessons, hasBestLessonOccurred);
        entries.addAll(levelEntries);
      }
    }

    // Add flex lessons.
    entries.addAll(getEntriesForLevel('Flex Lessons',
        libraryState.getUnattachedLessons(), hasBestLessonOccurred));

    return entries;
  }

  List<DropdownMenuEntry<Lesson?>> getEntriesForLevel(String levelTitle,
      Iterable<Lesson> lessons, BoolByReference hasBestLessonOccurred) {
    bool canLearnAtLeastOneLesson = false;
    List<DropdownMenuEntry<Lesson?>> entries = [];

    // Add level.
    WidgetStateProperty<TextStyle> levelTextStyle =
        WidgetStateProperty.all(CustomTextStyles.subHeadline);
    WidgetStateProperty<Color?> levelBackgroundColor = WidgetStateProperty.all(
        Theme.of(context).colorScheme.surfaceContainerHighest);
    entries.add(DropdownMenuEntry<Lesson?>(
        value: null,
        label: levelTitle,
        enabled: false,
        style: ButtonStyle(
            textStyle: levelTextStyle, backgroundColor: levelBackgroundColor)));

    // Add lessons.
    for (Lesson lesson in lessons) {
      User? mentee = widget.mentee;
      bool hasMenteeGraduated = (mentee == null)
          ? false
          : widget.organizerSessionState.hasUserGraduatedLesson(mentee, lesson);

      User? mentor = widget.mentor;
      bool hasMentorGraduated = (mentor == null)
          ? true
          : widget.organizerSessionState.hasUserGraduatedLesson(mentor, lesson);
      if (mentor?.isAdmin == true) {
        hasMentorGraduated = true;
      }

      bool canLearn = hasMentorGraduated && !hasMenteeGraduated;
      bool canPractice = hasMentorGraduated && hasMenteeGraduated;
      canLearnAtLeastOneLesson =
          canLearnAtLeastOneLesson || canLearn || canPractice;

      if (canLearn) {
        WidgetStateProperty<Color>? backgroundColor =
            hasBestLessonOccurred.value
                ? null
                : WidgetStateProperty.all(Colors.blue.shade50);

        entries.add(DropdownMenuEntry<Lesson?>(
            value: lesson,
            label: lesson.title,
            enabled: true,
            style: ButtonStyle(
              backgroundColor: backgroundColor,
              textStyle: WidgetStateProperty.all(
                  CustomTextStyles.getBodyNote(context)
                      ?.copyWith(color: Colors.blue)),
            )));

        hasBestLessonOccurred.value = true;
      } else if (canPractice) {
        entries.add(DropdownMenuEntry<Lesson?>(
            value: lesson,
            label: lesson.title,
            enabled: true,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.green.shade50),
              textStyle: WidgetStateProperty.all(
                  CustomTextStyles.getBodyNote(context)
                      ?.copyWith(color: Colors.black)),
            )));
      } else {
        entries.add(DropdownMenuEntry<Lesson?>(
            value: lesson,
            label: lesson.title,
            enabled: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
              textStyle: WidgetStateProperty.all(
                  CustomTextStyles.getBodyNote(context)
                      ?.copyWith(color: Colors.grey)),
            )));
      }
    }

    // Decide if there was at least one relevant lesson to the user.
    if (canLearnAtLeastOneLesson) {
      return entries;
    } else {
      return [];
    }
  }
}

class BoolByReference {
  bool value;

  BoolByReference(this.value);
}
