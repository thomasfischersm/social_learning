import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/prerequisites/add_prerequisite_fanout_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';

class ScopeItemEntry extends StatelessWidget {
  final TeachableItem item;
  final ScopeContext scopeContext;

  const ScopeItemEntry({
    super.key,
    required this.item,
    required this.scopeContext,
  });

  @override
  Widget build(BuildContext context) {
    print('Building scope item entry for ${item.name}');

    final tagWidgets = this
        .scopeContext
        .getTagsForItem(item)
        .map(
          (tag) =>
          Padding(
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
          _buildMultiStateCheckbox(),
          const SizedBox(width: 4),
          ..._buildRequiredRecommendedMark(),
          Flexible(child:Text(
            item.name ?? '(Untitled)',
            softWrap: true,
          )),
          ...tagWidgets,
          ..._buildDurationOverride(context),
        ],
      ),
    ));
  }

  Widget _buildMultiStateCheckbox() {
    IconData icon;
    Color color;
    String tooltip;

    switch (item.inclusionStatus) {
      case TeachableItemInclusionStatus.explicitlyIncluded:
        icon = Icons.check_box;
        color = Colors.green;
        tooltip = 'Explicitly included';
        break;
      case TeachableItemInclusionStatus.includedAsPrerequisite:
        icon = Icons.indeterminate_check_box;
        color = Colors.grey;
        tooltip = 'Included as a prerequisite';
        break;
      case TeachableItemInclusionStatus.explicitlyExcluded:
        icon = Icons.check_box_outline_blank;
        color = Colors.red;
        tooltip = 'Explicitly excluded';
        break;
      case TeachableItemInclusionStatus.excluded:
      default:
        icon = Icons.check_box_outline_blank;
        color = Colors.grey;
        tooltip = 'Excluded';
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: _handleInclusionStatusChange,
      ),
    );
  }

  List<Widget> _buildRequiredRecommendedMark() {
    bool isRequired = scopeContext.requiredItemIds.contains(item.id);
    bool isRecommended = scopeContext.recommendedItemIds.contains(item.id);

    if (!isRequired && !isRecommended) {
      return [];
    }

    return [
      Padding(
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
      const SizedBox(width: 4),
    ];
  }

  void _handleInclusionStatusChange() async {
    await scopeContext.toggleItemInclusionStatus(item);
  }

  List<Widget> _buildDurationOverride(BuildContext context) {
    if (item.durationInMinutes == null || item.durationInMinutes! <= 0) {
      return [
        const SizedBox(width: 8),
        InkWell(onTap: () => _handleOverrideDurationTapped(context),
            child: Icon(Icons.access_time, size: 14, color: Colors.grey))
      ];
    }

    return [
      const SizedBox(width: 8),
      Text(
        '${item.durationInMinutes} min',
      ),
      const SizedBox(width: 4),
      InkWell(onTap: () => _handleOverrideDurationTapped(context),
          child: Icon(Icons.access_time, size: 14, color: Colors.black))
    ];
  }

  void _handleOverrideDurationTapped(BuildContext context) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) =>
            ValueInputDialog(
              'Instruction Duration Override',
              item.durationInMinutes?.toString() ?? '15',
              'You can override the default instructional duration for this item.',
              'Save',
                  (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return null;
                }
                final num = int.tryParse(value ?? '');
                if (num == null) return 'Please enter a valid number';
                if (num < 0 || num > 1000) return 'Must be between 0 and 1000';
                return null;
              },
                  (newValue) {
                final newDurationOverride = int.tryParse(newValue);
                scopeContext.saveItemDurationOverride(
                    item, newDurationOverride);
              },
              instructionText:
              'Note all classroom time can be used for covering new content.\n\n'
                  'Time left is used for warm-ups, breaks, or group sharing.',
            ),
      );
    }
  }
}
