import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';

class PrerequisiteItemEntry extends StatefulWidget {
  final PrerequisiteContext context;
  final TeachableItem item;
  final TeachableItem parentItem;
  final int parentDepth;

  const PrerequisiteItemEntry({
    super.key,
    required this.context,
    required this.item,
    required this.parentItem,
    required this.parentDepth,
  });

  @override
  State<PrerequisiteItemEntry> createState() => _PrerequisiteItemEntryState();
}

class _PrerequisiteItemEntryState extends State<PrerequisiteItemEntry> {
  late final bool isRequired;
  late final bool isRecommended;

  @override
  void initState() {
    super.initState();
    isRequired = widget.parentItem.requiredPrerequisiteIds?.any((ref) => ref.id == widget.item.id) ?? false;
    isRecommended = widget.parentItem.recommendedPrerequisiteIds?.any((ref) => ref.id == widget.item.id) ?? false;
  }

  Future<void> _toggle() async {
    await widget.context.toggleDependency(
      target: widget.parentItem,
      dependency: widget.item,
    );
  }

  Future<void> _remove() async {
    await DialogUtils.showConfirmationDialog(
      context,
      'Remove Dependency',
      'Are you sure you want to remove this dependency?',
          () async {
        await widget.context.removeDependency(
          target: widget.parentItem,
          dependency: widget.item,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagWidgets = widget.context
        .getTagsForItem(widget.item)
        .map((tag) => Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TagPill(
        label: tag.name,
        color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))),
      ),
    ))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: widget.parentDepth * 16.0),
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
          ),
          const SizedBox(width: 4),
          Text(widget.item.name ?? '(Untitled)'),
          ...tagWidgets,
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove',
            onPressed: _remove,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add dependency',
            onPressed: () {
              // To be implemented later.
            },
          ),
        ],
      ),
    );
  }
}
