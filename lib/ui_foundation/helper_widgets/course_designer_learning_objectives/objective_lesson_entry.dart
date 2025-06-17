import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_lesson_fanout_widget.dart';

import '../../ui_constants/custom_text_styles.dart';

class ObjectiveLessonEntry extends StatefulWidget {
  final TeachableItem item;
  final Lesson lesson;
  final LearningObjectivesContext objectivesContext;

  const ObjectiveLessonEntry({
    super.key,
    required this.item,
    required this.lesson,
    required this.objectivesContext,
  });

  @override
  State<ObjectiveLessonEntry> createState() => _ObjectiveLessonEntryState();
}

class _ObjectiveLessonEntryState extends State<ObjectiveLessonEntry> {
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    // Optionally show level name as a pill
    final library = Provider.of<LibraryState>(context, listen: false);
    final level = widget.lesson.levelId != null
        ? library.findLevel(widget.lesson.levelId!.id)
        : null;

    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Lesson title
            // Expanded(
            const SizedBox(width: 16),
              Text(
                widget.lesson.title,
                // style: CustomTextStyles.getBody(context),
              ),
            // ),

            // Level pill
            // if (level != null)
            //   Padding(
            //     padding: const EdgeInsets.only(left: 4.0),
            //     child: TagPill(
            //       label: level.title,
            //       color: Colors.grey.shade300,
            //     ),
            //   ),

            const SizedBox(width: 8),

            // ✏️ Edit (replace) icon
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  AddLessonFanoutWidget.show(
                    context: context,
                    link: _layerLink,
                    item: widget.item,
                    currentLesson: widget.lesson,
                    objectivesContext: widget.objectivesContext,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🗑️ Remove (unlink) icon
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                widget.objectivesContext.removeLessonFromTeachableItem(
                  item: widget.item,
                  lesson: widget.lesson,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
