import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryIntroCard extends StatelessWidget {
  const InventoryIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Text("Step 2: Inventory the Building Blocks", style: CustomTextStyles.subHeadline),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Text(
        "Brainstorm all the small, teachable pieces of your subject. "
            "You're not creating lessons yet — just listing the core concepts and skills.\n\n"
            "🎯 Example (chess):\n"
            "• Movement → Bishop, Pawn, Knight\n"
            "• Tactics → Fork, Pin\n"
            "• Rules → Castling, En Passant",
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }
}
