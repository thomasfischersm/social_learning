import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/focused_teachable_item_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerPrerequisitesPage extends StatefulWidget {
  const CourseDesignerPrerequisitesPage({super.key});

  @override
  State<CourseDesignerPrerequisitesPage> createState() =>
      _CourseDesignerPrerequisitesPageState();
}

class _CourseDesignerPrerequisitesPageState
    extends State<CourseDesignerPrerequisitesPage> {
  String? _courseId;
  TeachableItem? _focusedItem;
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
    // TODO: There is a bug where the cotnext seems to have gone already.
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
      refresh: () => setState(() {
        // Weirdest bug ever!
        _handleFocusItemSelected(_focusedItem?.id);
      }),
    );
    setState(() {
      _prerequisiteContext = context;
    });
  }

  void _handleFocusItemSelected(String? itemId) {
    print('handleFocusItemSelected: $itemId start');
    final newFocus =
        itemId == null ? null : _prerequisiteContext?.itemById[itemId];
    setState(() {
      _focusedItem = newFocus;
    });
    print('handleFocusItemSelected: new focus: $_focusedItem done');
  }

  void _handleShowItemsWithPrerequisites() {
    // Optional: you could open a dialog or redirect
    print('Requested items with prerequisites');
    setState(() {
      _focusedItem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Prerequisites'),
        leading: CourseDesignerDrawer.hamburger(scaffoldKey),
        actions: InstructorNavActions.createActions(context),
      ),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.courseDesignerScope.navigateCleanDelayed(context);
        }, // or Icons.navigate_next
        tooltip: 'Next Page',
        child: Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
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
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  FocusedTeachableItemCard(
                    dataContext: _prerequisiteContext!,
                    focusedItem: _focusedItem,
                    onSelectItem: _handleFocusItemSelected,
                    onShowItemsWithPrerequisites:
                        _handleShowItemsWithPrerequisites,
                  ),
                  const SizedBox(height: CourseDesignerTheme.kCourseDesignerSpacingLarge),
                  DecomposedCourseDesignerCard.buildHeader('Dependency Tree'),
                ],
              ),
            ),
          ];
        },body:
PrerequisitesCard(
            context: _prerequisiteContext!,
            focusedItem: _focusedItem,
          ),
        );

  }
}
