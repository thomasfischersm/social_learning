import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_category_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_item_entry.dart';

class ScopeItemsCard extends StatelessWidget {
  final ScopeContext scopeContext;

  const ScopeItemsCard({
    super.key,
    required this.scopeContext,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> entries = [];

    for (final category in scopeContext.categories) {
      entries.add(
          ScopeCategoryEntry(category: category, scopeContext: scopeContext));

      final items = scopeContext.getItemsForCategory(category.id!);
      if (items.isEmpty) continue;

      for (final item in items) {
        entries.add(
          ScopeItemEntry(item: item, scopeContext: scopeContext),
        );
      }
    }

    entries.add(DecomposedCourseDesignerCard.buildFooter());

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return entries[index];
      },
    );
  }
}
