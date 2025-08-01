import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_tag_editor_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class InventoryTagCard extends StatefulWidget {
  const InventoryTagCard({super.key});

  @override
  State<InventoryTagCard> createState() => _InventoryTagCardState();
}

class _InventoryTagCardState extends State<InventoryTagCard> {
  late List<TeachableItemTag> _localTags;

  @override
  void initState() {
    super.initState();
    final state = context.read<CourseDesignerState>();
    _localTags = [...state.tags];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: CourseDesignerTheme.cardMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CourseDesignerTheme.cardBorderColor),
        borderRadius:
            BorderRadius.circular(CourseDesignerTheme.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildTagList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CourseDesignerTheme.cardHeaderBackgroundColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          Text("Tags", style: CustomTextStyles.subHeadline),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () async {
                  final state = context.read<CourseDesignerState>();
                  final courseId = state.course?.id;
                  if (courseId == null) return;
                  await showDialog(
                    context: context,
                    builder: (_) => InventoryTagEditorDialog(
                      initialTags: _localTags,
                      courseId: courseId,
                    ),
                  );
                  final updated = await TeachableItemTagFunctions.getTagsForCourse(courseId);
                  setState(() => _localTags = updated);
                },
                child: const Icon(Icons.edit, size: 14, color: Colors.grey),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: _localTags.isEmpty
          ? const Text(
        'No tags yet. Create tags like "easy", "hard", or "optional" to categorize your items.',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      )
          : Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _localTags.map((tag) {
          final color = _tryParseColor(tag.color);
          return TagPill(label: tag.name, color: color);
        }).toList(),
      ),
    );
  }

  Color _tryParseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
