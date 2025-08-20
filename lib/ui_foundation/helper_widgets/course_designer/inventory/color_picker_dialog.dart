import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final void Function(Color color) onColorSelected;

  const ColorPickerDialog({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return AlertDialog(
      title: const Text('Pick a color'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260), // ✨ golden-ratio width
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                onColorSelected(color);
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
