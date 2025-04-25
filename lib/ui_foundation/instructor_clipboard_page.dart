import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_clipboard/instructor_clipboard_header_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_clipboard/instructor_clipboard_table_widget.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Arguments to pass into the check-off page.
class InstructorClipboardArgument {
  final String studentId;
  final String studentUid;

  InstructorClipboardArgument(this.studentId, this.studentUid);

  static void navigateTo(
      BuildContext context, String studentId, String studentUid) {
    Navigator.pushNamed(
      context,
      NavigationEnum.instructorClipboard.route,
      arguments: InstructorClipboardArgument(studentId, studentUid),
    );
  }
}

class InstructorClipboardPage extends StatefulWidget {
  const InstructorClipboardPage({super.key});
  @override
  State<InstructorClipboardPage> createState() => _StudentCheckOffState();
}

class _StudentCheckOffState extends State<InstructorClipboardPage> {
  User? _student;
  int _lessonsLearned = 0;
  int _lessonsTaught = 0;

  String? get _studentId =>
      (ModalRoute.of(context)?.settings.arguments as InstructorClipboardArgument?)
          ?.studentId;
  String? get _studentUid =>
      (ModalRoute.of(context)?.settings.arguments as InstructorClipboardArgument?)
          ?.studentUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _studentId, uid = _studentUid;
    if (id != null && uid != null) {
      UserFunctions.getUserById(id).then((user) {
        setState(() => _student = user);
      });
      PracticeRecordFunctions.getLessonsLearnedCount(uid).then((count) {
        setState(() => _lessonsLearned = count);
      });
      PracticeRecordFunctions.getLessonsTaughtCount(uid).then((count) {
        setState(() => _lessonsTaught = count);
      });
    }
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
              if (_student == null) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InstructorClipboardHeaderWidget(
                    student: _student!,
                    lessonsLearned: _lessonsLearned,
                    lessonsTaught: _lessonsTaught,
                    libraryState: libraryState,
                  ),
                  InstructorClipboardTableWidget(_student!, libraryState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

