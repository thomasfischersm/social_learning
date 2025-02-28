import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final Widget child;

  const CustomCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section with a fixed style using your subHeadline.
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Text(
              title,
              style: CustomTextStyles.subHeadline.copyWith(color: Colors.white),
            ),
          ),
          // Content section.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ],
      ),
    );
  }
}