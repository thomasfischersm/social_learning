import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';

class FocusedTeachableItemCard extends StatelessWidget {
  final PrerequisiteContext dataContext;
  final TeachableItem? focusedItem;
  final void Function(String? selectedItemId) onSelectItem;
  final VoidCallback onShowItemsWithPrerequisites;

  const FocusedTeachableItemCard({
    super.key,
    required this.dataContext,
    required this.focusedItem,
    required this.onSelectItem,
    required this.onShowItemsWithPrerequisites,
  });

  @override
  Widget build(BuildContext context) {
    return CourseDesignerCard(
      title: 'Prerequisites',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect what comes before what. We’ll untangle this later into a plan.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: focusedItem?.id,
                    underline: const SizedBox(),
                    hint: const Text('Select focus item'),
                    onChanged: (value) {
                      if (value != null) {
                        onSelectItem(value);
                      }
                    },
                    items: [
                      for (final category in this.dataContext.categories) ...[
                        DropdownMenuItem<String>(
                          value: '__CATEGORY__${category.id}',
                          enabled: false,
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        for (final item in this
                                .dataContext
                                .itemsGroupedByCategory[category.id] ??
                            [])
                          DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name ?? '(Untitled)'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onShowItemsWithPrerequisites,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Required'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('Recommended'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.swap_horiz, size: 16),
                  SizedBox(width: 4),
                  Text('Click to toggle'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
