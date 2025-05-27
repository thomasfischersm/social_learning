import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_tag_editor_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryTagCard extends StatefulWidget {
  final List<TeachableItemTag> tags;
  final String courseId;

  const InventoryTagCard({
    super.key,
    required this.tags,
    required this.courseId,
  });

  @override
  State<InventoryTagCard> createState() => _InventoryTagCardState();
}

class _InventoryTagCardState extends State<InventoryTagCard> {
  late List<TeachableItemTag> _localTags;

  @override
  void initState() {
    super.initState();
    _localTags = [...widget.tags];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                  await showDialog(
                    context: context,
                    builder: (_) => InventoryTagEditorDialog(
                      initialTags: _localTags,
                      courseId: widget.courseId,
                    ),
                  );
                  final updated = await TeachableItemTagFunctions.getTagsForCourse(widget.courseId);
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
