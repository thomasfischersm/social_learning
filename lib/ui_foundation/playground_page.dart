import 'package:flutter/material.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final List<_PlaygroundItem> _greenEntries = <_PlaygroundItem>[];
  final List<_PlaygroundItem> _redEntries = <_PlaygroundItem>[];
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
    required List<_PlaygroundItem> targetList,
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
      targetList.add(_PlaygroundItem(id: _nextId++, text: value, color: color));
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
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _greenEntries.length + _redEntries.length + 2,
        itemBuilder: (BuildContext context, int index) {
          if (index < _greenEntries.length) {
            final _PlaygroundItem item = _greenEntries[index];
            return _PlaygroundEntry(
              key: ValueKey<int>(item.id),
              text: item.text,
              circleColor: item.color.asColor,
            );
          }

          if (index == _greenEntries.length) {
            return _PlaygroundInputRow(
              key: _greenInputKey,
              controller: _greenTextController,
              focusNode: _greenFocusNode,
              labelText: 'Add a green circle',
              onSubmitted: () => _handleSubmit(
                controller: _greenTextController,
                focusNode: _greenFocusNode,
                targetList: _greenEntries,
                inputKey: _greenInputKey,
                color: _PlaygroundCircleColor.green,
              ),
            );
          }

          final int redSectionStart = _greenEntries.length + 1;
          final int redEntriesEnd = redSectionStart + _redEntries.length;
          if (index < redEntriesEnd) {
            final _PlaygroundItem item =
                _redEntries[index - redSectionStart];
            return _PlaygroundEntry(
              key: ValueKey<int>(item.id),
              text: item.text,
              circleColor: item.color.asColor,
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
              targetList: _redEntries,
              inputKey: _redInputKey,
              color: _PlaygroundCircleColor.red,
            ),
          );
        },
      ),
    );
  }
}

class _PlaygroundEntry extends StatelessWidget {
  const _PlaygroundEntry({
    super.key,
    required this.text,
    required this.circleColor,
  });

  final String text;
  final Color circleColor;

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
        ],
      ),
    );
  }
}

class _PlaygroundItem {
  const _PlaygroundItem({
    required this.id,
    required this.text,
    required this.color,
  });

  final int id;
  final String text;
  final _PlaygroundCircleColor color;
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
