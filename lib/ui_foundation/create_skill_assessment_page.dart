import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/user.dart' as model;
import 'package:social_learning/data/data_helpers/skill_assessment_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/ui_foundation/helper_widgets/skill_assessment/skill_assessment_header_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/skill_assessment/skill_dimension_card.dart';

/// Arguments to navigate to [CreateSkillAssessmentPage].
class CreateSkillAssessmentPageArgument {
  final String studentId;
  final String studentUid;

  CreateSkillAssessmentPageArgument(this.studentId, this.studentUid);

  static void navigateTo(
      BuildContext context, String studentId, String studentUid) {
    Navigator.pushNamed(
      context,
      NavigationEnum.createSkillAssessment.route,
      arguments: CreateSkillAssessmentPageArgument(studentId, studentUid),
    );
  }
}

class CreateSkillAssessmentPage extends StatefulWidget {
  const CreateSkillAssessmentPage({super.key});

  @override
  State<CreateSkillAssessmentPage> createState() =>
      _CreateSkillAssessmentPageState();
}

class _CreateSkillAssessmentPageState extends State<CreateSkillAssessmentPage> {
  model.User? _student;
  SkillAssessment? _latestAssessment;
  final TextEditingController _notesController = TextEditingController();
  final Map<String, int?> _selectedDegrees = {};
  final Map<String, int> _previousDegrees = {};

  String? get _studentId => (ModalRoute.of(context)?.settings.arguments
          as CreateSkillAssessmentPageArgument?)
      ?.studentId;
  String? get _studentUid => (ModalRoute.of(context)?.settings.arguments
          as CreateSkillAssessmentPageArgument?)
      ?.studentUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CourseDesignerState>().ensureInitialized();

    final id = _studentId, uid = _studentUid;
    if (_student == null && id != null && uid != null) {
      Future.microtask(() async {
        final user = await UserFunctions.getUserById(id);
        if (!mounted) return;
        setState(() => _student = user);
        final courseId = context.read<LibraryState>().selectedCourse?.id;
        if (courseId != null) {
          final assessment = await SkillAssessmentFunctions.latestForUser(
              courseId: courseId, studentUid: uid);
          if (assessment != null && mounted) {
            setState(() {
              _latestAssessment = assessment;
              for (final d in assessment.dimensions) {
                _previousDegrees[d.id] = d.degree;
              }
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(title: 'Skill Assessment'),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: Consumer2<CourseDesignerState, LibraryState>(
        builder: (context, designerState, libraryState, _) {
          final rubric = designerState.skillRubric;
          final course = libraryState.selectedCourse;
          if (rubric == null ||
              _student == null ||
              course == null ||
              !_hasValidRubric(rubric)) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _allSelected(rubric)
                ? () => _saveAssessment(rubric, course.id!)
                : null,
            tooltip: 'Save Assessment',
            child: const Icon(Icons.save),
          );
        },
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableCreatorGuard: true,
          Consumer2<CourseDesignerState, LibraryState>(
            builder: (context, designerState, libraryState, _) {
              final rubric = designerState.skillRubric;
              final course = libraryState.selectedCourse;
              if (rubric == null || _student == null || course == null) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!_hasValidRubric(rubric)) {
                return _buildNoRubricMessage(context);
              }

              final currentDimensions = rubric.dimensions
                  .map((d) => SkillAssessmentDimension(
                        id: d.id,
                        name: d.name,
                        degree: _selectedDegrees[d.id] ?? 0,
                        maxDegrees: d.degrees.length,
                      ))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillAssessmentHeaderCard(
                    student: _student!,
                    latestAssessment: _latestAssessment,
                    currentDimensions: currentDimensions,
                    notesController: _notesController,
                  ),
                  const SizedBox(height: 8),
                  ...rubric.dimensions.map((dim) {
                    return SkillDimensionCard(
                      dimension: dim,
                      selectedDegree: _selectedDegrees[dim.id],
                      previousDegree: _previousDegrees[dim.id],
                      onDegreeSelected: (degree) {
                        setState(() {
                          _selectedDegrees[dim.id] = degree;
                        });
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _allSelected(SkillRubric rubric) {
    return rubric.dimensions.every((d) => _selectedDegrees[d.id] != null);
  }

  bool _hasValidRubric(SkillRubric? rubric) {
    return rubric != null &&
        rubric.dimensions.isNotEmpty &&
        rubric.dimensions.any((d) => d.degrees.isNotEmpty);
  }

  Widget _buildNoRubricMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 16),
          const Text(
            'You have to define a skill rubric first.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              NavigationEnum.courseDesignerSkillRubric.navigate(context);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Create Skill Rubric'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssessment(SkillRubric rubric, String courseId) async {
    final instructorUid = context.read<ApplicationState>().currentUser?.uid;
    if (instructorUid == null || _student == null) return;

    final dimensions = rubric.dimensions
        .map((d) => SkillAssessmentDimension(
              id: d.id,
              name: d.name,
              degree: _selectedDegrees[d.id] ?? 0,
              maxDegrees: d.degrees.length,
            ))
        .toList();

    final assessment = await SkillAssessmentFunctions.create(
      courseId: courseId,
      studentUid: _student!.uid,
      instructorUid: instructorUid,
      notes: _notesController.text,
      dimensions: dimensions,
    );

    if (assessment != null) {
      await UserFunctions.updateCourseSkillAssessment(
        user: _student!,
        courseId: courseId,
        dimensions: dimensions,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          NavigationEnum.instructorClipboard.route,
          arguments: InstructorClipboardArgument(_student!.id, _student!.uid),
        );
      }
    }
  }
}
