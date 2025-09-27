import 'package:flutter/material.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final List<_PlaygroundRow> _rows = <_PlaygroundRow>[
    const _PlaygroundRow.input(_PlaygroundRowType.greenInput),
    const _PlaygroundRow.input(_PlaygroundRowType.redInput),
  ];
  final TextEditingController _greenTextController = TextEditingController();
  final TextEditingController _redTextController = TextEditingController();
  final FocusNode _greenFocusNode = FocusNode();
  final FocusNode _redFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _greenInputKey = GlobalKey();
  final GlobalKey _redInputKey = GlobalKey();
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _greenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _greenTextController.dispose();
    _redTextController.dispose();
    _greenFocusNode.dispose();
    _redFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit({
    required TextEditingController controller,
    required FocusNode focusNode,
    required GlobalKey inputKey,
    required _PlaygroundCircleColor color,
  }) {
    final String rawValue = controller.text;
    final String value = rawValue.trim();
    controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });

    if (value.isEmpty) {
      _ensureInputVisible(inputKey);
      return;
    }

    setState(() {
      final _PlaygroundRow newRow = _PlaygroundRow.entry(
        id: _nextId++,
        text: value,
        color: color,
      );
      final _PlaygroundRowType inputType =
          color == _PlaygroundCircleColor.green
              ? _PlaygroundRowType.greenInput
              : _PlaygroundRowType.redInput;
      final int inputIndex =
          _rows.indexWhere((row) => row.type == inputType);
      final int insertIndex = inputIndex >= 0 ? inputIndex : _rows.length;
      _rows.insert(insertIndex, newRow);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInputVisible(inputKey);
    });
  }

  void _ensureInputVisible(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context == null) {
      return;
    }

    if (_scrollController.hasClients) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playground'),
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _rows.length,
        onReorder: _handleReorder,
        scrollController: _scrollController,
        itemBuilder: (BuildContext context, int index) {
          final _PlaygroundRow row = _rows[index];
          if (row.isEntry) {
            return _PlaygroundEntry(
              key: ValueKey<int>(row.id!),
              text: row.text!,
              circleColor: row.color!.asColor,
              dragHandle: ReorderableDragStartListener(
                index: index,
                child: const _PlaygroundDragHandle(),
              ),
            );
          }

          if (row.type == _PlaygroundRowType.greenInput) {
            return _PlaygroundInputRow(
              key: _greenInputKey,
              controller: _greenTextController,
              focusNode: _greenFocusNode,
              labelText: 'Add a green circle',
              onSubmitted: () => _handleSubmit(
                controller: _greenTextController,
                focusNode: _greenFocusNode,
                inputKey: _greenInputKey,
                color: _PlaygroundCircleColor.green,
              ),
            );
          }

          return _PlaygroundInputRow(
            key: _redInputKey,
            controller: _redTextController,
            focusNode: _redFocusNode,
            labelText: 'Add a red circle',
            onSubmitted: () => _handleSubmit(
              controller: _redTextController,
              focusNode: _redFocusNode,
              inputKey: _redInputKey,
              color: _PlaygroundCircleColor.red,
            ),
          );
        },
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    final _PlaygroundRow movingRow = _rows[oldIndex];
    if (!movingRow.isEntry) {
      return;
    }

    int targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    if (targetIndex < 0) {
      targetIndex = 0;
    } else if (targetIndex > _rows.length) {
      targetIndex = _rows.length;
    }

    setState(() {
      _rows.removeAt(oldIndex);
      if (targetIndex > _rows.length) {
        targetIndex = _rows.length;
      }
      _rows.insert(targetIndex, movingRow);
    });
  }
}

class _PlaygroundEntry extends StatelessWidget {
  const _PlaygroundEntry({
    super.key,
    required this.text,
    required this.circleColor,
    required this.dragHandle,
  });

  final String text;
  final Color circleColor;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          dragHandle,
        ],
      ),
    );
  }
}

class _PlaygroundDragHandle extends StatelessWidget {
  const _PlaygroundDragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.drag_handle,
        color: Colors.grey[600],
      ),
    );
  }
}

enum _PlaygroundCircleColor { green, red }

extension _PlaygroundCircleColorX on _PlaygroundCircleColor {
  Color get asColor {
    switch (this) {
      case _PlaygroundCircleColor.green:
        return Colors.green;
      case _PlaygroundCircleColor.red:
        return Colors.red;
    }
  }
}

class _PlaygroundRow {
  const _PlaygroundRow.entry({
    required this.id,
    required this.text,
    required this.color,
  }) : type = _PlaygroundRowType.entry;

  const _PlaygroundRow.input(this.type)
      : id = null,
        text = null,
        color = null;

  final int? id;
  final String? text;
  final _PlaygroundCircleColor? color;
  final _PlaygroundRowType type;

  bool get isEntry => type == _PlaygroundRowType.entry;
}

enum _PlaygroundRowType { entry, greenInput, redInput }

class _PlaygroundInputRow extends StatelessWidget {
  const _PlaygroundInputRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.labelText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 60, height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onSubmitted(),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: labelText,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
