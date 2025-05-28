import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/focused_teachable_item_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';

class CourseDesignerPrerequisitesPage extends StatefulWidget {
  const CourseDesignerPrerequisitesPage({super.key});

  @override
  State<CourseDesignerPrerequisitesPage> createState() =>
      _CourseDesignerPrerequisitesPageState();
}

class _CourseDesignerPrerequisitesPageState
    extends State<CourseDesignerPrerequisitesPage> {
  String? _courseId;
  PrerequisiteContext? _prerequisiteContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryState = Provider.of<LibraryState>(context, listen: false);
      if (libraryState.selectedCourse?.id != null) {
        _courseId = libraryState.selectedCourse!.id!;
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
      _courseId = libraryState.selectedCourse!.id!;
      libraryState.removeListener(_libraryStateListener);
      _loadContext();
    }
  }

  Future<void> _loadContext() async {
    if (_courseId == null) return;
    final context = await PrerequisiteContext.create(
      courseId: _courseId!,
      refresh: () => setState(() {}),
    );
    setState(() {
      _prerequisiteContext = context;
    });
  }

  void _handleFocusItemSelected(String? itemId) {
    // For now, just print or keep the state
    print('Selected focus item: $itemId');
  }

  void _handleShowItemsWithPrerequisites() {
    // For now, just print or show a dialog
    print('Requested items with prerequisites');
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Set Prerequisites'),
        leading: CourseDesignerDrawer.hamburger(scaffoldKey),
        actions: InstructorNavActions.createActions(context),
      ),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: true,
          enableCreatorGuard: true,
          _prerequisiteContext == null
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FocusedTeachableItemCard(
          context: _prerequisiteContext!,
          onSelectItem: _handleFocusItemSelected,
          onShowItemsWithPrerequisites: _handleShowItemsWithPrerequisites,
        ),
      ],
    );
  }
}
