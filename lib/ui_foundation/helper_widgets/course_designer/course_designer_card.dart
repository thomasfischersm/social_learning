import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseDesignerCard extends StatefulWidget {
  final String title;
  final Widget body;
  final bool dismissible;
  final String? prefsKey;

  const CourseDesignerCard({
    super.key,
    required this.title,
    required this.body,
    this.dismissible = false,
    this.prefsKey,
  });

  @override
  State<CourseDesignerCard> createState() => _CourseDesignerCardState();
}

class _CourseDesignerCardState extends State<CourseDesignerCard> {
  bool _bodyVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.dismissible && widget.prefsKey != null) {
      _loadDismissedState();
    }
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(widget.prefsKey!) ?? false;
    setState(() {
      _bodyVisible = !dismissed;
    });
  }

  Future<void> _dismissBody() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefsKey!, true);
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
          _buildHeader(),
          if (_bodyVisible) _buildBodyWithOptionalDismiss(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: CourseDesignerTheme.cardHeaderPadding,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Text(
        widget.title,
        style: CourseDesignerTheme.cardHeaderTextStyle,
      ),
    );
  }

  Widget _buildBodyWithOptionalDismiss() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.body,
          if (widget.dismissible && widget.prefsKey != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _dismissBody,
                child: const Text('Dismiss'),
              ),
            ),
        ],
      ),
    );
  }
}
