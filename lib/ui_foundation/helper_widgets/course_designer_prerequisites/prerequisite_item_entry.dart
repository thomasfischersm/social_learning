import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';

class PrerequisiteItemEntry extends StatefulWidget {
  final TeachableItem item;
  final TeachableItem parentItem;
  final int dependencyDepth;
  final PrerequisiteContext context;

  const PrerequisiteItemEntry({
    super.key,
    required this.item,
    required this.parentItem,
    required this.dependencyDepth,
    required this.context,
  });

  @override
  State<PrerequisiteItemEntry> createState() => _PrerequisiteItemEntryState();
}

class _PrerequisiteItemEntryState extends State<PrerequisiteItemEntry> {
  late bool isRequired;
  late bool isRecommended;

  @override
  void initState() {
    super.initState();
    _computeState();
  }

  void _computeState() {
    isRequired = widget.parentItem.requiredPrerequisiteIds
        ?.any((ref) => ref.id == widget.item.id) ??
        false;

    isRecommended = widget.parentItem.recommendedPrerequisiteIds
        ?.any((ref) => ref.id == widget.item.id) ??
        false;
  }

  void _handleToggleDependency() async {
    await widget.context.toggleDependency(
      target: widget.parentItem,
      dependency: widget.item,
    );
    setState(() {
      _computeState();
    });
  }

  void _handleRemoveDependency() {
    DialogUtils.showConfirmationDialog(
      context,
      'Remove Dependency',
      'Are you sure you want to remove this dependency?',
          () async {
        await widget.context.removeDependency(
          target: widget.parentItem,
          dependency: widget.item,
        );
        // refresh already called inside context
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final indentWidth = widget.dependencyDepth * 16.0;
    final tagWidgets = (widget.item.tags ?? <TeachableItemTag>[])
        .map((tag) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: TagPill(
        label: tag.label ?? '',
        color: tag.color ?? Colors.grey,
      ),
    ))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: indentWidth),

          // Icon toggle (required/recommended)
          InkWell(
            onTap: _handleToggleDependency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Item name and tags
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.item.name ?? '(Untitled)',
                  style: const TextStyle(fontSize: 14),
                ),
                ...tagWidgets,
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove Dependency',
                onPressed: _handleRemoveDependency,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Sub-Dependency',
                onPressed: () {
                  // You can wire this up to open a dropdown later
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
