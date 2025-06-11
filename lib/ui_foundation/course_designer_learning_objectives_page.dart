import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_list_view.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_overview_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/focused_teachable_item_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_scope/scope_items_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_scope/scope_overview_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryState = Provider.of<LibraryState>(context, listen: false);
      if (libraryState.selectedCourse?.id != null) {
        _loadContext();
      } else {
        libraryState.addListener(_libraryStateListener);
      }
    });
  }

  @override
  void dispose() {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    libraryState.removeListener(_libraryStateListener);
    super.dispose();
  }

  void _libraryStateListener() {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    if (libraryState.selectedCourse?.id != null) {
      libraryState.removeListener(_libraryStateListener);
      _loadContext();
    }
  }

  Future<void> _loadContext() async {
    if (mounted) {
      final libraryState = Provider.of<LibraryState>(context, listen: false);
      var courseId = libraryState.selectedCourse?.id;
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
      appBar: AppBar(
        title: const Text('Learning Objectives'),
        leading: CourseDesignerDrawer.hamburger(scaffoldKey),
        actions: InstructorNavActions.createActions(context),
      ),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the next page.
          // NavigationEnum.courseDesignerProfile.navigateCleanDelayed(context);
        },
        tooltip: 'Next Page',
        child: Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
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
    return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  LearningObjectivesOverviewCard(),
                  const SizedBox(height: 24),
                  DecomposedCourseDesignerCard.buildHeader(
                      'Edit Learning Objectives'),
                ],
              ),
            ),
          ];
        },
        body: LearningObjectivesListView(objectivesContext: _objectivesContext!));
  }
}
