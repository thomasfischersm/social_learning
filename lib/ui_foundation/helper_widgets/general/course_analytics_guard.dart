import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/course_analytics_state.dart';

class CourseAnalyticsGuard extends StatefulWidget {
  final Widget child;

  const CourseAnalyticsGuard({super.key, required this.child});

  @override
  State<CourseAnalyticsGuard> createState() => _CourseAnalyticsGuardState();
}

class _CourseAnalyticsGuardState extends State<CourseAnalyticsGuard> {
  static const Duration _spinnerDelay = Duration(milliseconds: 500);

  bool _showSpinner = false;
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _spinnerTimer = Timer(_spinnerDelay, () {
      if (mounted) {
        setState(() {
          _showSpinner = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAnalyticsState = Provider.of<CourseAnalyticsState>(context);

    return FutureBuilder<void>(
      future: courseAnalyticsState.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.child;
        }

        if (snapshot.hasError) {
          return widget.child;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showSpinner
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

