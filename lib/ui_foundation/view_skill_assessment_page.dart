import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/user.dart' as model;
import 'package:social_learning/data/data_helpers/skill_assessment_functions.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/create_skill_assessment_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/skill_assessment/skill_assessment_view_header_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/skill_assessment/skill_dimension_view_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/skill_assessment/legacy_skill_dimension_view_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Arguments to navigate to [ViewSkillAssessmentPage].
class ViewSkillAssessmentPageArgument {
  final String studentUid;

  const ViewSkillAssessmentPageArgument(this.studentUid);

  static void navigateTo(BuildContext context, String studentUid) {
    Navigator.pushNamed(
      context,
      NavigationEnum.viewSkillAssessment.route,
      arguments: ViewSkillAssessmentPageArgument(studentUid),
    );
  }
}

class ViewSkillAssessmentPage extends StatefulWidget {
  const ViewSkillAssessmentPage({super.key});

  @override
  State<ViewSkillAssessmentPage> createState() => _ViewSkillAssessmentPageState();
}

class _ViewSkillAssessmentPageState extends State<ViewSkillAssessmentPage> {
  Future<_PageData>? _dataFuture;
  int _index = 0;
  bool _initializedIndex = false;

  String? get _studentUidArg =>
      (ModalRoute.of(context)?.settings.arguments
              as ViewSkillAssessmentPageArgument?)
          ?.studentUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataFuture ??= _loadData();
  }

  Future<_PageData> _loadData() async {
    final appState = context.read<ApplicationState>();
    final libraryState = context.read<LibraryState>();
    final courseId = libraryState.selectedCourse?.id;
    final currentUser =
        appState.currentUser ?? await appState.currentUserBlocking;
    final studentUid = _studentUidArg ?? currentUser?.uid;
    if (courseId == null || studentUid == null) {
      return _PageData(null, [], {}, null);
    }

    final studentFuture = _loadStudent(studentUid, currentUser);
    final assessmentsFuture = _loadAssessments(courseId, studentUid);
    final rubricFuture = _loadRubric(courseId);

    final results = await Future.wait([
      studentFuture,
      assessmentsFuture,
      rubricFuture,
    ]);

    final student = results[0] as model.User?;
    final assessments = results[1] as List<SkillAssessment>;
    assessments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final rubric = results[2] as SkillRubric?;

    final instructors = await _loadInstructors(assessments);

    return _PageData(student, assessments, instructors, rubric);
  }

  bool get _isInstructorView => _studentUidArg != null;

  Future<bool> _handlePop(model.User? student) async {
    if (_isInstructorView && student != null) {
      Navigator.pushReplacementNamed(
        context,
        NavigationEnum.instructorClipboard.route,
        arguments: InstructorClipboardArgument(student.id, student.uid),
      );
    } else {
      Navigator.pushReplacementNamed(context, NavigationEnum.profile.route);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationState>();
    final libraryState = context.watch<LibraryState>();
    final course = libraryState.selectedCourse;
    final currentUser = appState.currentUser;
    final showFab =
        course != null && currentUser != null && course.creatorId == currentUser.uid;
    print('showFab: $showFab course=$course course.creatorId=${course?.creatorId} currentUser.id=${currentUser?.uid}');

    return Scaffold(
      appBar: const LearningLabAppBar(title: 'Skill Assessment'),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () async {
                final data = await _dataFuture;
                final student = data?.student;
                if (!mounted || student == null) return;
                CreateSkillAssessmentPageArgument.navigateTo(
                    context, student.id, student.uid);
              },
              tooltip: 'Create Assessment',
              child: const Icon(Icons.add),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          FutureBuilder<_PageData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final student = data.student;
              final assessments = data.assessments;
              final rubric = data.rubric;
              if (student == null || rubric == null) {
                return const Text('No skill assessments found.');
              }
              if (assessments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No skill assessments found.'),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          CreateSkillAssessmentPageArgument.navigateTo(
                            context,
                            student.id,
                            student.uid,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create a skill assessment'),
                      ),
                    ],
                  ),
                );
              }
              if (!_initializedIndex) {
                _index = assessments.length - 1;
                _initializedIndex = true;
              }
              final assessment = assessments[_index];
              return WillPopScope(
                onWillPop: () => _handlePop(student),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkillAssessmentViewHeaderCard(
                      student: student,
                      assessments: assessments,
                      currentIndex: _index,
                      instructors: data.instructors,
                      onIndexChanged: (i) {
                        setState(() => _index = i);
                      },
                    ),
                    const SizedBox(height: 8),
                    ..._buildDimensionWidgets(rubric, assessment),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDimensionWidgets(
      SkillRubric rubric, SkillAssessment assessment) {
    final widgets = <Widget>[];
    final rubricMap = {for (var d in rubric.dimensions) d.id: d};
    final assessedIds = <String>{};

    for (final assessDim in assessment.dimensions) {
      assessedIds.add(assessDim.id);
      final rubricDim = rubricMap[assessDim.id];
      if (rubricDim != null) {
        widgets.add(
          SkillDimensionViewCard(
            dimension: rubricDim,
            selectedDegree: assessDim.degree,
          ),
        );
      } else {
        widgets.add(
          LegacySkillDimensionViewCard(dimension: assessDim),
        );
      }
    }

    for (final dim in rubric.dimensions) {
      if (!assessedIds.contains(dim.id)) {
        widgets.add(
          CustomCard(
            title: dim.name,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This dimension did not exist at the time of assessing.',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<model.User?> _loadStudent(
      String studentUid, model.User? currentUser) async {
    if (_studentUidArg == null) {
      return currentUser;
    }
    return UserFunctions.getUserByUid(studentUid);
  }

  Future<List<SkillAssessment>> _loadAssessments(
      String courseId, String studentUid) {
    return SkillAssessmentFunctions.allForUser(
        courseId: courseId, studentUid: studentUid);
  }

  Future<SkillRubric?> _loadRubric(String courseId) {
    return SkillRubricsFunctions.loadForCourse(courseId);
  }

  Future<Map<String, model.User>> _loadInstructors(
      List<SkillAssessment> assessments) async {
    final instructorUids = assessments.map((a) => a.instructorUid).toSet();
    final futures = instructorUids.map(UserFunctions.getUserByUid).toList();
    final users = await Future.wait(futures);
    final map = <String, model.User>{};
    for (final user in users) {
      map[user.uid] = user;
    }
    return map;
  }
}

class _PageData {
  final model.User? student;
  final List<SkillAssessment> assessments;
  final Map<String, model.User> instructors;
  final SkillRubric? rubric;

  _PageData(this.student, this.assessments, this.instructors, this.rubric);
}
