import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_overview_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_block_list_view.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerSessionPlanPage extends StatefulWidget {
  const CourseDesignerSessionPlanPage({super.key});

  @override
  State<CourseDesignerSessionPlanPage> createState() =>
      _CourseDesignerSessionPlanPageState();
}

class _CourseDesignerSessionPlanPageState
    extends State<CourseDesignerSessionPlanPage> {
  SessionPlanContext? _sessionPlanContext;
  LibraryState? _libraryState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _libraryState = Provider.of<LibraryState>(context, listen: false);
      if (_libraryState?.selectedCourse?.id != null) {
        _loadContext();
      } else {
        _libraryState!.addListener(_libraryStateListener);
      }
    });
  }

  @override
  void dispose() {
    final libraryState = _libraryState;
    if (libraryState != null) {
      libraryState.removeListener(_libraryStateListener);
      super.dispose();
    }
  }

  void _libraryStateListener() {
    final libraryState = _libraryState;
    if (_libraryState?.selectedCourse?.id != null) {
      libraryState!.removeListener(_libraryStateListener);
      _loadContext();
    }
  }

  Future<void> _loadContext() async {
    if (mounted) {
      final libraryState = _libraryState;
      if (libraryState == null) return;

      final courseId = libraryState.selectedCourse?.id;
      if (courseId == null) return;

      final dataContext = await SessionPlanContext.create(
        courseId: courseId,
        libraryState: libraryState,
        refresh: () => setState(() {}),
      );

      setState(() {
        _sessionPlanContext = dataContext;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: CourseDesignerAppBar(
          title: 'Session Plan',
          scaffoldKey: scaffoldKey,
          currentNav: NavigationEnum.courseDesignerSessionPlan),
      drawer: const CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.cmsSyllabus.navigateCleanDelayed(context);
        },
        tooltip: 'Syllabus',
        child: const Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          enableCourseLoadingGuard: true,
          _sessionPlanContext == null
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
                  SessionPlanOverviewCard(context: _sessionPlanContext!),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ];
        },
        body: SessionBlocksListView(
          sessionPlanContext: _sessionPlanContext!,
        ),
      ),
    );
  }
}
