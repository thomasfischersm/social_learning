import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Table of lessons with simple checkboxes (only graduation).
class InstructorClipboardTableWidget extends StatefulWidget {
  final User student;
  final LibraryState libraryState;

  const InstructorClipboardTableWidget(this.student, this.libraryState,
      {super.key});

  @override
  State<InstructorClipboardTableWidget> createState() =>
      InstructorClipboardTableState();
}

enum LessonState {
  none,
  graduated,
  practiced,
}

class InstructorClipboardTableState
    extends State<InstructorClipboardTableWidget> {
  static const flexLevelId = 'flex';
  String? _expandedLevelId;
  Map<String, LessonState> _lessonState = {};
  Map<String, PracticeRecord> _graduationRecord = {};

  @override
  void initState() {
    super.initState();
    _expandedLevelId = widget.libraryState.levels?.firstOrNull?.id;
    _loadPracticeRecords();
  }

  Future<void> _loadPracticeRecords() async {
    final practiceRecords =
        await PracticeRecordFunctions.fetchPracticeRecordsForMentee(
            widget.student.uid);
    final Map<String, LessonState> states = {};
    final Map<String, PracticeRecord> grads = {};
    for (var practiceRecord in practiceRecords) {
      final id = practiceRecord.lessonId.id;
      if (practiceRecord.isGraduation) {
        states[id] = LessonState.graduated;
        grads[id] = practiceRecord;
      } else if (states[id] != LessonState.graduated){
        states[id] = LessonState.practiced;
      }
    }
    setState(() {
      _lessonState = states;
      _graduationRecord = grads;
    });
  }

  void _toggleLevel(String levelId) {
    setState(() {
      _expandedLevelId = _expandedLevelId == levelId ? null : levelId;
    });
  }

  _goToLesson(String? lessonId) {
    if (lessonId != null) {
      Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
          arguments: LessonDetailArgument(lessonId));
    }
  }

  void _onCheckboxChanged(Lesson lesson, bool? checked) {
    print('Checkbox changed: ${lesson.title} $checked');
    final id = lesson.id!;
    // Only act on checking
    // if (checked == true) {
    final alreadyGraduated = _lessonState[id] == LessonState.graduated;
    if (alreadyGraduated) {
      print('Already graduated: $id');
      _showGraduationInfo(id, lesson.title);
      print('Graduation record: ${_graduationRecord[id]}');
    } else {
      _confirmGraduation(lesson);
    }
    // }
  }

  void _showGraduationInfo(String lessonId, String lessonTitle) {
    final rec = _graduationRecord[lessonId]!;
    final when = rec.timestamp?.toDate();
    final whenStr =
        when != null ? DateFormat.yMMMd().add_jm().format(when) : 'Unknown';
    // TODO: Show multiple graduation records if they exist.
    DialogUtils.showInfoDialog(
      context,
      'Already Graduated',
      '"$lessonTitle" was graduated on $whenStr.',
      () {},
    );
  }

  void _confirmGraduation(Lesson lesson) {
    DialogUtils.showConfirmationDialog(
      context,
      'Graduate Lesson?',
      'Are you sure you want to mark "${lesson.title}" as graduated?',
      () {
        final studentState = Provider.of<StudentState>(context, listen: false);
        studentState.recordTeachingWithCheck(
            lesson, widget.student, true, context);
        setState(() {
          _lessonState[lesson.id!] = LessonState.graduated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              children: _buildLevelRows(),
            ),
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildLevelRows() {
    final rows = <TableRow>[];
    for (var level in widget.libraryState.levels ?? []) {
      if (level.id == null) continue;
      rows.add(_levelHeaderRow(level.id!, level.title));
      if (_expandedLevelId == level.id) {
        rows.addAll(
            _buildLessonRows(widget.libraryState.getLessonsByLevel(level.id!)));
      }
    }
    final flex = widget.libraryState.getUnattachedLessons();
    if (flex.isNotEmpty) {
      rows.add(_levelHeaderRow(flexLevelId, 'Flex Lessons'));
      if (_expandedLevelId == flexLevelId) {
        rows.addAll(_buildLessonRows(flex));
      }
    }
    return rows;
  }

  TableRow _levelHeaderRow(String id, String title) {
    return TableRow(children: [
      InkWell(
        onTap: () => _toggleLevel(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(_expandedLevelId == id
                  ? Icons.arrow_drop_down
                  : Icons.arrow_right),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  softWrap: true,
                  style: CustomTextStyles.subHeadline
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox.shrink(),
    ]);
  }

  List<TableRow> _buildLessonRows(Iterable<Lesson> lessons) {
    return lessons.map((lesson) {
      final id = lesson.id!;
      bool? graduated;
      switch(_lessonState[id]) {
        case LessonState.none:
          graduated = false;
          break;
        case LessonState.graduated:
          graduated = true;
          break;
        case LessonState.practiced:
          graduated = null;
          break;
        default:
          graduated = false;
          break;
      }
      return TableRow(children: [
        Padding(
          padding: EdgeInsets.only(left: IconTheme.of(context).size ?? 24),
          child: InkWell(onTap: () => _goToLesson(lesson.id), child:Text(lesson.title, style: CustomTextStyles.getBody(context))),
        ),
        Center(
          child: Checkbox(
            tristate: true,
            value: graduated,
            onChanged: (val) => _onCheckboxChanged(lesson, val),
          ),
        ),
      ]);
    }).toList();
  }
}
