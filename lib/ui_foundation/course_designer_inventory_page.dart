import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_drag_helper.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_intro_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_tag_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_category_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_item_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_item_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_category_entry.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class CourseDesignerInventoryPage extends StatefulWidget {
  const CourseDesignerInventoryPage({super.key});

  @override
  State<StatefulWidget> createState() => CourseDesignerInventoryState();
}

class CourseDesignerInventoryState extends State<CourseDesignerInventoryPage> {
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseDesignerState>().getItemsWithDependencies();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Consumer<CourseDesignerState>(
      builder: (context, state, _) {
        final entries = _buildEntries(state);
        return Scaffold(
          key: scaffoldKey,
          appBar: CourseDesignerAppBar(
              title: 'Learning Lab', scaffoldKey: scaffoldKey),
          drawer: CourseDesignerDrawer(),
          bottomNavigationBar: BottomBarV2.build(context),
          body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(
              enableScrolling: false,
              enableCreatorGuard: true,
              state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    )
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        const SliverToBoxAdapter(child: InventoryIntroCard()),
                        const SliverToBoxAdapter(
                          child: InventoryTagCard(),
                        ),
                      ],
                      body: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: entries.length,
                        onReorder: (oldIndex, newIndex) async {
                          await InventoryDragHelper.handleReorder(
                            context: state,
                            inventoryEntries: entries,
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          );
                          setState(() {});
                        },
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(entry),
                            index: index,
                            child: entry.buildWidget(
                              context,
                              () {
                                if (entry is InventoryCategoryEntry) {
                                  _expanded[entry.category.id!] = entry.isExpanded;
                                }
                                setState(() {});
                              },
                              state,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  List<InventoryEntry> _buildEntries(CourseDesignerState state) {
    final entries = <InventoryEntry>[];
    final categories = state.categories;
    for (final category in categories) {
      final expanded = _expanded[category.id!] ?? true;
      final catEntry = InventoryCategoryEntry(
        category,
        isExpanded: expanded,
        onDelete: (cat) async => await state.deleteCategory(cat),
        state: state,
      );
      entries.add(catEntry);
      if (expanded) {
        final items = state.getItemsForCategory(category.id!);
        for (final item in items) {
          entries.add(
            InventoryItemEntry(
              item,
              onDelete: (itm) async => await state.deleteItem(itm),
            ),
          );
        }
        entries.add(
          AddNewItemEntry(
            category: category,
            onAdd: (cat, name) => state.addNewItem(cat, name),
            state: state,
          ),
        );
      }
    }
    entries.add(
      AddNewCategoryEntry(
        onAdd: (name) => state.addNewCategory(name),
        onGenerate: () => state.generateInventory(),
        state: state,
      ),
    );
    return entries;
  }

}
