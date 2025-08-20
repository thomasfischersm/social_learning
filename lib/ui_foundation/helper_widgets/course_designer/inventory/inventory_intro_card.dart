import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

/// Introductory card for the inventory step of the course designer.
class InventoryIntroCard extends StatelessWidget {
  const InventoryIntroCard({super.key});

  /// Key for persisting dismissal state in [SharedPreferences].
  static const String prefsKey = 'inventory_intro_card_dismissed';

  @override
  Widget build(BuildContext context) {
    return const CourseDesignerCard(
      title: 'Step 2: Inventory the Building Blocks',
      dismissible: true,
      prefsKey: prefsKey,
      body: Text(
        "Brainstorm all the small, teachable pieces of your subject. "
        "You're not creating lessons yet — just listing the core concepts and skills.\n\n"
        "🎯 Example (chess):\n"
        "• Movement → Bishop, Pawn, Knight\n"
        "• Tactics → Fork, Pin\n"
        "• Rules → Castling, En Passant",
        style: TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }
}
