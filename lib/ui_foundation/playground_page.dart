import 'package:flutter/material.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final List<_PlaygroundItem> _entries = <_PlaygroundItem>[];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _nextId = 0;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit(String rawValue) {
    final String value = rawValue.trim();
    if (value.isEmpty) {
      _textController.clear();
      _textFocusNode.requestFocus();
      return;
    }

    setState(() {
      _entries.add(_PlaygroundItem(id: _nextId++, text: value));
    });

    _textController.clear();
    _textFocusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _PlaygroundItem movedEntry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, movedEntry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playground'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              buildDefaultDragHandles: false,
              itemCount: _entries.length,
              onReorder: _handleReorder,
              itemBuilder: (BuildContext context, int index) {
                final _PlaygroundItem item = _entries[index];
                return _PlaygroundEntry(
                  key: ValueKey<int>(item.id),
                  index: index,
                  text: item.text,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    onSubmitted: _handleSubmit,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Add an entry',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaygroundEntry extends StatelessWidget {
  const _PlaygroundEntry({super.key, required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
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
          const SizedBox(width: 12),
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.drag_handle,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaygroundItem {
  const _PlaygroundItem({required this.id, required this.text});

  final int id;
  final String text;
}
