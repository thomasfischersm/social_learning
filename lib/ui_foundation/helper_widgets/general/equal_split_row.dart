import 'package:flutter/widgets.dart';

/// A widget that displays two children side by side, each taking up half of the
/// available width. The height of both children is constrained to match the
/// natural height of the taller child.
class EqualSplitRow extends StatelessWidget {
  final Widget leftChild;
  final Widget rightChild;

  const EqualSplitRow({
    super.key,
    required this.leftChild,
    required this.rightChild,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: leftChild),
          Expanded(child: rightChild),
        ],
      ),
    );
  }
}
