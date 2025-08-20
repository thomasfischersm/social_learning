import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/learning_objectives/learning_objectives_list_view.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/learning_objectives/learning_objectives_overview_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/prerequisites/focused_teachable_item_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/prerequisites/prerequisite_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_items_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_overview_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerLearningObjectivesPage extends StatefulWidget {
  const CourseDesignerLearningObjectivesPage({super.key});

  @override
  State<CourseDesignerLearningObjectivesPage> createState() =>
      _CourseDesignerLearningObjectivesPageState();
}

class _CourseDesignerLearningObjectivesPageState
    extends State<CourseDesignerLearningObjectivesPage> {
  LearningObjectivesContext? _objectivesContext;
  late LibraryState _libraryState;

  @override
  void initState() {
    super.initState();
    _libraryState = context.read<LibraryState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_libraryState.selectedCourse?.id != null) {
        _loadContext();
      } else {
        _libraryState.addListener(_libraryStateListener);
      }
    });
  }

  @override
  void dispose() {
    _libraryState.removeListener(_libraryStateListener);
    super.dispose();
  }

  void _libraryStateListener() {
    if (_libraryState.selectedCourse?.id != null) {
      _libraryState.removeListener(_libraryStateListener);
      _loadContext();
    }
  }

  Future<void> _loadContext() async {
    if (mounted) {
      var courseId = _libraryState.selectedCourse?.id;
      if (courseId == null) {
        return;
      }
      final dataContext = await LearningObjectivesContext.create(
        courseId: courseId,
        refresh: () => setState(() {
          // Weirdest bug ever!
          // TODO:
        }),
      );
      setState(() {
        _objectivesContext = dataContext;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: CourseDesignerAppBar(
          title: 'Learning Objectives',
          scaffoldKey: scaffoldKey,
          currentNav: NavigationEnum.courseDesignerLearningObjectives),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.courseDesignerSessionPlan
              .navigateCleanDelayed(context);
        },
        tooltip: 'Next Page',
        child: const Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          enableCourseLoadingGuard: true,
          _objectivesContext == null
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )
              : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<LibraryState>(
        builder: (context, libraryState, child) => NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      LearningObjectivesOverviewCard(),
                      const SizedBox(height: 24),
                      // DecomposedCourseDesignerCard.buildHeader(
                      //     'Edit Learning Objectives'),
                    ],
                  ),
                ),
              ];
            },
            body: LearningObjectivesListView(
                objectivesContext: _objectivesContext!)));
  }
}
