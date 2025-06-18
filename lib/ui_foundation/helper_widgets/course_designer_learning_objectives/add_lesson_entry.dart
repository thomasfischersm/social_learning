import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/cms_lesson_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_lesson_fanout_widget.dart';

import '../../ui_constants/navigation_enum.dart';

/// Row that lets an instructor attach a new **Lesson** (the *how*)
/// to the current **Teachable Item** (the *what*).
class AddLessonEntry extends StatefulWidget {
  final TeachableItem item;
  final LearningObjectivesContext objectivesContext;

  const AddLessonEntry({
    super.key,
    required this.item,
    required this.objectivesContext,
  });

  @override
  State<AddLessonEntry> createState() => _AddLessonEntryState();
}

class _AddLessonEntryState extends State<AddLessonEntry> {
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // const Expanded(child: SizedBox()),

            SizedBox(width: 16),

            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  AddLessonFanoutWidget.show(
                    context: context,
                    link: _layerLink,
                    item: widget.item,
                    currentLesson: null,
                    // means “add”, not “replace”
                    objectivesContext: widget.objectivesContext,
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline,
                          size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Add lesson'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _createLessonTapped(context),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Create lesson')))
          ],
        ),
      ),
    );
  }

  void _createLessonTapped(BuildContext context) {
    Navigator.pushNamed(context, NavigationEnum.cmsLesson.route,
        arguments: CmsLessonDetailArgument.forNewLessonToAttachToTeachableItem(
            widget.item.id!));
  }
}
