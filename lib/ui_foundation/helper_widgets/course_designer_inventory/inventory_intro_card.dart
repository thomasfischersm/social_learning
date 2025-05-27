import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryIntroCard extends StatefulWidget {
  const InventoryIntroCard({super.key});

  @override
  State<InventoryIntroCard> createState() => _InventoryIntroCardState();
}

class _InventoryIntroCardState extends State<InventoryIntroCard> {
  bool _bodyVisible = true;

  static const String _prefsKey = 'inventory_intro_card_dismissed';

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_prefsKey) ?? false;
    setState(() {
      _bodyVisible = !dismissed;
    });
  }

  Future<void> _dismissCardBody() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    setState(() {
      _bodyVisible = false;
    });
  }

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
          if (_bodyVisible) _buildBodyWithDismiss(),
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

  Widget _buildBodyWithDismiss() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Brainstorm all the small, teachable pieces of your subject. "
                "You're not creating lessons yet — just listing the core concepts and skills.\n\n"
                "🎯 Example (chess):\n"
                "• Movement → Bishop, Pawn, Knight\n"
                "• Tactics → Fork, Pin\n"
                "• Rules → Castling, En Passant",
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _dismissCardBody,
              child: const Text("Dismiss", style: TextStyle(fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }
}
