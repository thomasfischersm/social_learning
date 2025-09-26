import 'package:flutter/material.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final List<String> _entries = <String>[];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

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
      _entries.add(value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playground'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        itemCount: _entries.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index < _entries.length) {
            return _PlaygroundEntry(text: _entries[index]);
          }

          return Padding(
            padding: const EdgeInsets.only(top: 12),
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
          );
        },
      ),
    );
  }
}

class _PlaygroundEntry extends StatelessWidget {
  const _PlaygroundEntry({required this.text});

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
        ],
      ),
    );
  }
}
