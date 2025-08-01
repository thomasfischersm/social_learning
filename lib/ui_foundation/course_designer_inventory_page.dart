import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_data_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_drag_helper.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_intro_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_tag_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';

class CourseDesignerInventoryPage extends StatefulWidget {
  const CourseDesignerInventoryPage({super.key});

  @override
  State<StatefulWidget> createState() => CourseDesignerInventoryState();
}

class CourseDesignerInventoryState extends State<CourseDesignerInventoryPage> {
  InventoryDataContext? _context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryState = Provider.of<LibraryState>(context, listen: false);
      if (libraryState.selectedCourse?.id != null) {
        _loadContext(libraryState.selectedCourse!.id!, libraryState.selectedCourse);
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
    final selectedCourse = libraryState.selectedCourse;

    if (selectedCourse?.id != null) {
      libraryState.removeListener(_libraryStateListener);
      _loadContext(selectedCourse!.id!, selectedCourse);
    }
  }

  void _loadContext(String courseId, Course? course) {
    final ctx = InventoryDataContext.create(
      courseId: courseId,
      course: course,
      refresh: () => setState(() {}),
    );
    if (mounted) {
      setState(() {
        _context = ctx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final dataContext = _context;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
          title: const Text('Learning Lab'),
          leading: CourseDesignerDrawer.hamburger(scaffoldKey),
          actions: InstructorNavActions.createActions(context)),
      drawer: CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          dataContext == null || dataContext.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(child: InventoryIntroCard()),
                    SliverToBoxAdapter(
                      child: InventoryTagCard(
                        tags: dataContext.getTags(),
                        courseId: dataContext.courseId,
                      ),
                    ),
                  ],
                  body: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: dataContext.inventoryEntries.length,
                    onReorder: (oldIndex, newIndex) async {
                      await InventoryDragHelper.handleReorder(
                        context: dataContext,
                        inventoryEntries: dataContext.inventoryEntries,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      );
                      dataContext.loadInventoryData();
                    },
                    itemBuilder: (context, index) {
                      final entry = dataContext.inventoryEntries[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(entry),
                        index: index,
                        child: entry.buildWidget(
                          context,
                          () => setState(() {}),
                          dataContext,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

}
