import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/add_prerequisite_fanout_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';

class PrerequisiteItemEntry extends StatelessWidget {
  final PrerequisiteContext context;
  final TeachableItem item;
  final TeachableItem? parentItem;
  final int parentDepth;
  final bool showAddButton;

  const PrerequisiteItemEntry({
    super.key,
    required this.context,
    required this.item,
    required this.parentItem,
    required this.parentDepth,
    this.showAddButton = true,
  });

  Future<void> _toggle() async {
    if (parentItem == null) return;
    await context.toggleDependency(
      target: parentItem!,
      dependency: item,
    );
  }

  Future<void> _remove(BuildContext context) async {
    if (parentItem == null) return;
    await DialogUtils.showConfirmationDialog(
      context,
      'Remove Dependency',
      'Are you sure you want to remove this dependency?',
      () async {
        await this.context.removeDependency(
              target: parentItem!,
              dependency: item,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building prerequisite item entry for ${item.name}');
    final isRoot = parentItem == null;

    final isRequired =
        parentItem?.requiredPrerequisiteIds?.any((ref) => ref.id == item.id) ??
            false;

    final isRecommended = parentItem?.recommendedPrerequisiteIds
            ?.any((ref) => ref.id == item.id) ??
        false;

    final tagWidgets = this
        .context
        .getTagsForItem(item)
        .map(
          (tag) => Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: TagPill(
              label: tag.name,
              color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))),
            ),
          ),
        )
        .toList();

    return DecomposedCourseDesignerCard.buildBody(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: parentDepth * 16.0),
          if (!isRoot)
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  isRequired
                      ? Icons.check_circle
                      : isRecommended
                          ? Icons.star
                          : Icons.radio_button_unchecked,
                  color: isRequired
                      ? Colors.green
                      : isRecommended
                          ? Colors.amber
                          : Colors.grey,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(width: 4),
          Text(
            item.name ?? '(Untitled)',
            style:
                isRoot ? CustomTextStyles.getBodyEmphasized(context) : null,
          ),
          ...tagWidgets,
          const SizedBox(width: 4),
          if (showAddButton)
            AddPrerequisiteFanoutWidget(
              context: this.context,
              targetItem: item,
              onDependencySelected: (selected) async {
                await this.context.addDependency(
                      target: item,
                      dependency: selected,
                      required: true,
                    );
              },
            ),
          if (!isRoot) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _remove(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.remove_circle_outline),
              ),
            ),
          ],
        ],
      ),
    ));
  }
}
