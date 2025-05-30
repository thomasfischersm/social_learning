import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';

class AddPrerequisiteFanoutWidget extends StatefulWidget {
  final PrerequisiteContext context;
  final TeachableItem targetItem;
  final void Function(TeachableItem item) onDependencySelected;

  const AddPrerequisiteFanoutWidget({
    super.key,
    required this.context,
    required this.targetItem,
    required this.onDependencySelected,
  });

  @override
  State<AddPrerequisiteFanoutWidget> createState() => _AddPrerequisiteFanoutWidgetState();
}

class _AddPrerequisiteFanoutWidgetState extends State<AddPrerequisiteFanoutWidget> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;

  void _toggleOverlay() {
    if (_isVisible) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isVisible = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isVisible = false);
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final List<Widget> menuItems = [];

    final sortedCategories = widget.context.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final category in sortedCategories) {
      final items = widget.context.itemsGroupedByCategory[category.id] ?? [];

      final visibleItems = items
          .where((i) => i.id != widget.targetItem.id) // prevent self-dependency
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (visibleItems.isEmpty) continue;

      menuItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          child: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );

      for (final item in visibleItems) {
        menuItems.add(
          InkWell(
            onTap: () {
              _removeOverlay();
              widget.onDependencySelected(item);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(item.name ?? '(Untitled)'),
            ),
          ),
        );
      }
    }

    return OverlayEntry(
      builder: (_) => GestureDetector(
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300, minWidth: 180),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: menuItems),
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
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleOverlay,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(Icons.add_circle_outline),
        ),
      ),
    );
  }
}
