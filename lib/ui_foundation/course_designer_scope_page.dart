import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_items_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_overview_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerScopePage extends StatefulWidget {
  const CourseDesignerScopePage({super.key});

  @override
  State<CourseDesignerScopePage> createState() =>
      _CourseDesignerScopePageState();
}

class _CourseDesignerScopePageState extends State<CourseDesignerScopePage> {
  ScopeContext? _scopeContext;
  late LibraryState _libraryState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _libraryState = Provider.of<LibraryState>(context, listen: false);
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
      final dataContext = await ScopeContext.create(
        courseId: courseId,
        refresh: () => setState(() {
          // Weirdest bug ever!
          // TODO:
        }),
      );
      setState(() {
        _scopeContext = dataContext;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: CourseDesignerAppBar(
          title: 'Scoping',
          scaffoldKey: scaffoldKey,
          currentNav: NavigationEnum.courseDesignerScope),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.courseDesignerSkillRubric
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
          _scopeContext == null
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
    if (_scopeContext == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ScopeOverviewCard(scopeContext: _scopeContext!),
                  const SizedBox(height: 24),
                  DecomposedCourseDesignerCard.buildHeader(
                      'Select teachable items'),
                ],
              ),
            ),
          ];
        },
        body: ScopeItemsCard(scopeContext: _scopeContext!));
  }
}
