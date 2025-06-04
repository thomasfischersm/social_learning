import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_scope/scope_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class ScopeCategoryEntry extends StatelessWidget {
  final TeachableItemCategory category;
  final ScopeContext scopeContext;

  const ScopeCategoryEntry(
      {super.key, required this.category, required this.scopeContext});

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            // Category name
            Text(
              category.name,
              style: CustomTextStyles.subHeadline,
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
