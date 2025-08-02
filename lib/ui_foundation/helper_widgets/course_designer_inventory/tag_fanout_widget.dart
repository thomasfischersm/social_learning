import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class TagFanoutWidget extends StatefulWidget {
  final List<TeachableItemTag> availableTags;
  final Function(TeachableItemTag tag) onTagSelected;

  const TagFanoutWidget({
    super.key,
    required this.availableTags,
    required this.onTagSelected,
  });

  @override
  State<TagFanoutWidget> createState() => _TagFanoutWidgetState();
}

class _TagFanoutWidgetState extends State<TagFanoutWidget> {
  bool showOverlay = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleOverlay() {
    if (showOverlay) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => showOverlay = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => showOverlay = false);
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy + size.height + 4,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: Offset(0, size.height + 4),
                showWhenUnlinked: false,
                child: Material(
                  elevation: 6,
                  borderRadius:
                      BorderRadius.circular(CourseDesignerTheme.cardBorderRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          CourseDesignerTheme.cardBorderRadius),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.availableTags.map((tag) {
                        return InkWell(
                          onTap: () {
                            _removeOverlay();
                            widget.onTagSelected(tag);
                          },
                          borderRadius: BorderRadius.circular(
                              CourseDesignerTheme.tagPillBorderRadius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: TagPill(
                              label: tag.name,
                              color: _tryParseColor(tag.color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(CourseDesignerTheme.tagPillBorderRadius),
        onTap: _toggleOverlay,
        child: TagPill(
          label: '+',
          color: Colors.grey.shade300,
        ),
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
