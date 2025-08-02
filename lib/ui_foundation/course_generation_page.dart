import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/cloud_functions/cloud_functions.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/course_plan.dart';
import 'package:social_learning/data/data_helpers/course_plan_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseGenerationPage extends StatefulWidget {
  const CourseGenerationPage({super.key});

  @override
  State<CourseGenerationPage> createState() => CourseGenerationPageState();
}

class CourseGenerationPageState extends State<CourseGenerationPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  CoursePlan? _coursePlan;
  String _lastSavedText = '';
  bool _isGenerating = false;
  bool _hasLoadedPlan = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _persistPlanJson();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedPlan) {
      final course = Provider.of<LibraryState>(context).selectedCourse;
      if (course != null) {
        _loadInitialPlanJson(course);
        _hasLoadedPlan = true;
      }
    }
  }

  Future<void> _loadInitialPlanJson(Course course) async {
    final courseRef = docRef('courses', course.id!);
    final plan = await CoursePlanFunctions.getCoursePlanByCourse(courseRef);

    if (mounted) {
      setState(() {
        _coursePlan = plan;
        _controller.text = plan?.planJson ?? '';
        _lastSavedText = plan?.planJson ?? '';
      });
    }
  }

  Future<void> _persistPlanJson() async {
    final newText = _controller.text.trim();
    if (_coursePlan == null || newText == _lastSavedText) return;

    await CoursePlanFunctions.updatePlanJson(_coursePlan!.id!, newText);
    _lastSavedText = newText;
  }

  @override
  void dispose() {
    _persistPlanJson(); // final save before exit
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curriculum Generator')),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableCreatorGuard: true,
          enableCourseLoadingGuard: true,
          Consumer<LibraryState>(
            builder: (context, libraryState, _) {
              final course = libraryState.selectedCourse;

              if (course == null) return const Text('Loading course...');

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course: ${course.title}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Describe your direction for the curriculum. What should students learn, what should the tone or focus be, and what kind of structure do you envision?',
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: 10,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., A beginner tango course focused on musicality and improvisation...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: _isGenerating
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.auto_fix_high),
                                label: Text(_isGenerating
                                    ? 'Generating...'
                                    : 'Generate Curriculum'),
                                onPressed: _isGenerating
                                    ? null
                                    : () => _onGenerateTapped(course),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onGenerateTapped(Course course) async {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    if (applicationState.currentUser?.isAdmin != true) {
      await DialogUtils.showInfoDialog(context, 'Generate curriculum',
          'Please, contact thomas@learninglab.fans to get early access to this feature.',
          () {
        /* Nothing todo */
      });
    } else {
      await DialogUtils.showConfirmationDialog(
        context,
        'Replace existing curriculum?',
        'Generating a new curriculum will permanently replace your current one. This process uses AI and costs real money to run — please only proceed if you really intend to regenerate.',
        () async {
          setState(() => _isGenerating = true);
          final direction = _controller.text.trim();

          final courseRef = docRef('courses', course.id!);
          CoursePlan? plan =
              await CoursePlanFunctions.getCoursePlanByCourse(courseRef);

          if (plan == null) {
            final newId = await CoursePlanFunctions.createCoursePlan(
                courseRef, direction);
            plan = await CoursePlanFunctions.getCoursePlanById(newId);
          } else {
            await CoursePlanFunctions.updatePlanJson(plan.id!, direction);
          }

          await CloudFunctions.generateCourseFromPlan(plan!.id!);

          setState(() => _isGenerating = false);

          if (mounted) {
            NavigationEnum.courseGenerationReview.navigateClean(context);
          }
        },
      );
    }
  }
}
