import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';

class CourseDurationEditDialog extends StatefulWidget {
  final ScopeContext scopeContext;

  const CourseDurationEditDialog({super.key, required this.scopeContext});

  @override
  State<CourseDurationEditDialog> createState() =>
      _CourseDurationEditDialogState();
}

class _CourseDurationEditDialogState extends State<CourseDurationEditDialog> {
  late TextEditingController _sessionCountController;
  late TextEditingController _sessionDurationController;
  late TextEditingController _totalMinutesController;

  @override
  void initState() {
    super.initState();
    final profile = widget.scopeContext.courseProfile;
    final sessionCount = profile?.sessionCount;
    final sessionDuration = profile?.sessionDurationInMinutes;
    final totalMinutes = profile?.totalCourseDurationInMinutes ?? 0;

    _sessionCountController =
        TextEditingController(text: sessionCount?.toString() ?? '');
    _sessionDurationController =
        TextEditingController(text: sessionDuration?.toString() ?? '');
    _totalMinutesController =
        TextEditingController(text: totalMinutes.toString());

    _sessionCountController.addListener(_recalculateTotal);
    _sessionDurationController.addListener(_recalculateTotal);
  }

  void _recalculateTotal() {
    final sessionCount = int.tryParse(_sessionCountController.text);
    final sessionDuration = int.tryParse(_sessionDurationController.text);

    if (sessionCount == null || sessionDuration == null) {
      return;
    }

    int totalMinutes = sessionCount * sessionDuration;
    setState(() {
      _totalMinutesController.text = totalMinutes.toString();
    });
  }

  @override
  void dispose() {
    _sessionCountController.dispose();
    _sessionDurationController.dispose();
    _totalMinutesController.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    final sessionCount = int.tryParse(_sessionCountController.text);
    final sessionDuration = int.tryParse(_sessionDurationController.text);
    final totalMinutes = int.tryParse(_totalMinutesController.text);

    await widget.scopeContext
        .saveSessionDuration(sessionCount, sessionDuration, totalMinutes);
    Navigator.of(context).pop();
  }

  void _clearSessionCountAndDuration() {
    print('Clearing session count and duration');
    if (_totalMinutesController.text.isEmpty) return;

    _sessionCountController.clear();
    _sessionDurationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Course Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sessionCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Number of Sessions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sessionDurationController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Duration per Session (minutes)',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 24),
          TextField(
            controller: _totalMinutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Total Duration (minutes)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _clearSessionCountAndDuration(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
