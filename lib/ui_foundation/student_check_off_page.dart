// lib/ui_foundation/student_checkoff_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Arguments to pass into the check-off page.
class StudentCheckOffArgument {
  final String studentId;
  final String studentUid;

  StudentCheckOffArgument(this.studentId, this.studentUid);

  static void navigateTo(
      BuildContext context, String studentId, String studentUid) {
    Navigator.pushNamed(
      context,
      NavigationEnum.studentCheckOff.route,
      arguments: StudentCheckOffArgument(studentId, studentUid),
    );
  }
}

class StudentCheckOffPage extends StatefulWidget {
  const StudentCheckOffPage({super.key});
  @override
  State<StudentCheckOffPage> createState() => _StudentCheckOffState();
}

class _StudentCheckOffState extends State<StudentCheckOffPage> {
  User? _student;
  int _lessonsLearned = 0;
  int _lessonsTaught = 0;

  String? get _studentId =>
      (ModalRoute.of(context)?.settings.arguments as StudentCheckOffArgument?)
          ?.studentId;
  String? get _studentUid =>
      (ModalRoute.of(context)?.settings.arguments as StudentCheckOffArgument?)
          ?.studentUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _studentId;
    final uid = _studentUid;
    if (id != null && uid != null) {
      UserFunctions.getUserById(id).then((u) {
        if (u != null) setState(() => _student = u);
      });
      PracticeRecordFunctions.getLessonsLearnedCount(uid).then((count) {
        setState(() => _lessonsLearned = count);
      });
      PracticeRecordFunctions.getLessonsTaughtCount(uid).then((count) {
        setState(() => _lessonsTaught = count);
      });
    }
  }

  String _relativeSince(DateTime joined) {
    final diff = DateTime.now().difference(joined);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    }
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    }
    final years = diff.inDays ~/ 365;
    return '$years year${years > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach’s Clipboard')),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Consumer<LibraryState>(
            builder: (context, libraryState, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _createHeader(libraryState),
                  if (_student == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    StudentCheckOffTable(_student!, libraryState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _createHeader(LibraryState libraryState) {
    if (_student == null) return const SizedBox.shrink();

    final course = libraryState.selectedCourse;
    final prof = course != null
        ? _student!.getCourseProficiency(course)?.proficiency ?? 0
        : 0.0;
    final progressPct = (prof * 100).round();
    final since = _relativeSince(_student!.created.toDate());
    final bodyStyle = CustomTextStyles.getBody(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileImageWidget(
                    _student!,
                    context,
                    maxRadius: 32,
                    linkToOtherProfile: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _student!.displayName,
                      style: CustomTextStyles.headline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statColumn('Since', since, bodyStyle)),
                  Expanded(child: _statColumn('Learned', '$_lessonsLearned', bodyStyle)),
                  Expanded(child: _statColumn('Taught', '$_lessonsTaught', bodyStyle)),
                  Expanded(child: _statColumn('Progress', '$progressPct%', bodyStyle)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, TextStyle? bodyStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: bodyStyle),
        const SizedBox(height: 4),
        Text(value, style: bodyStyle),
      ],
    );
  }
}

class StudentCheckOffTable extends StatefulWidget {
  final User student;
  final LibraryState libraryState;
  const StudentCheckOffTable(this.student, this.libraryState, {super.key});

  @override
  State<StudentCheckOffTable> createState() => _StudentCheckOffTableState();
}

class _StudentCheckOffTableState extends State<StudentCheckOffTable> {
  static const flexLevelId = 'flex';
  String? _expandedLevelId;
  final Set<String> _checkedLessons = {};

  @override
  void initState() {
    super.initState();
    _expandedLevelId = widget.libraryState.levels?.first.id;
  }

  void _toggleLevel(String levelId) {
    setState(() {
      _expandedLevelId = _expandedLevelId == levelId ? null : levelId;
    });
  }

  void _toggleLessonChecked(String lessonId, bool? isChecked) {
    setState(() {
      if (isChecked == true)
        _checkedLessons.add(lessonId);
      else
        _checkedLessons.remove(lessonId);
    });
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
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
            },
            children: [
              ..._buildLevelRows(),
            ],
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
        rows.addAll(_buildLessonRows(
            widget.libraryState.getLessonsByLevel(level.id!)));
      }
    }
    final flexLessons = widget.libraryState.getUnattachedLessons();
    if (flexLessons.isNotEmpty) {
      rows.add(_levelHeaderRow(flexLevelId, 'Flex Lessons'));
      if (_expandedLevelId == flexLevelId) {
        rows.addAll(_buildLessonRows(flexLessons));
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
    return lessons
        .where((l) => l.id != null)
        .map((lesson) {
      final id = lesson.id!;
      final checked = _checkedLessons.contains(id);
      return TableRow(children: [
        Padding(
          padding: EdgeInsets.only(left: IconTheme.of(context).size ?? 24),
          child: Text(lesson.title, style: CustomTextStyles.getBody(context)),
        ),
        Center(
          child: Checkbox(
            value: checked,
            onChanged: (v) => _toggleLessonChecked(id, v),
          ),
        ),
      ]);
    }).toList();
  }
}
