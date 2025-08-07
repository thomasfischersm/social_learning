import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/json_models/generated_course.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/course_plan.dart';
import 'package:social_learning/data/data_helpers/course_plan_functions.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class CourseGenerationReviewPage extends StatefulWidget {
  const CourseGenerationReviewPage({super.key});

  @override
  State<CourseGenerationReviewPage> createState() =>
      _CourseGenerationReviewPageState();
}

class _CourseGenerationReviewPageState
    extends State<CourseGenerationReviewPage> {
  CoursePlan? _coursePlan;
  GeneratedCourse? _generatedCourse;

  Future<void> _loadPlan(String courseId) async {
    final plan = await CoursePlanFunctions.getCoursePlanByCourse(
        docRef('courses', courseId));
    if (!mounted || plan == null) return;

    setState(() {
      _coursePlan = plan;
      try {
        print('Parsing generatedJson: ${plan.generatedJson}');
        _generatedCourse =
            GeneratedCourse.fromJsonString(plan.generatedJson ?? '');
        print('Parsed generatedJson successfully: $_generatedCourse');
      } catch (e, stackTrace) {
        debugPrint('Failed to parse generatedJson: $e\n$stackTrace');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(title: 'Generated Course Review'),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          enableCourseLoadingGuard: true,
          Consumer<LibraryState>(
            builder: (context, libraryState, _) {
              print(
                  'Building page: LibraryState: ${libraryState.selectedCourse} _coursePlan: $_coursePlan, _generatedCourse: $_generatedCourse}');

              final course = libraryState.selectedCourse;

              if (course == null) return const Text('Loading course...');

              if (_coursePlan == null) {
                _loadPlan(course.id!);
                return const Center(child: CircularProgressIndicator());
              }

              if (_generatedCourse == null) {
                print('No generated course found for course ID: ${course.id}');
                return const Text('No generated plan available.');
              }

              print('About to build listview builder ${_generatedCourse!.levels.length}');
              return ListView.builder(
                itemCount: _generatedCourse!.levels.length,
                itemBuilder: (context, i) {
                  print('Level count: ${_generatedCourse!.levels.length}');
                  final level = _generatedCourse!.levels[i];
                  return _CustomExpansionTile(
                    title: Text(level.title),
                    subtitle: Text(level.description),
                    children: level.lessons.map((lesson) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _CustomExpansionTile(
                          title: Text(lesson.title),
                          subtitle: Text(lesson.synopsis),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(lesson.instructions),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: _CustomExpansionTile(
                                title: const Text('Graduation Requirements'),
                                children: lesson.graduationRequirements
                                    .map((req) => ListTile(title: Text(req)))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;

  const _CustomExpansionTile({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<_CustomExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: IconButton(
            icon: Icon(_expanded ? Icons.remove : Icons.add),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(children: widget.children),
          ),
      ],
    );
  }
}
