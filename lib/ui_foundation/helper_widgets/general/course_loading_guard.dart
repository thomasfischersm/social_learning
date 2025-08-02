import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseLoadingGuard extends StatefulWidget {
  final Widget child;
  const CourseLoadingGuard({super.key, required this.child});

  @override
  State<CourseLoadingGuard> createState() => _CourseLoadingGuardState();
}

class _CourseLoadingGuardState extends State<CourseLoadingGuard> {
  bool _showSpinner = false;
  bool _navigationScheduled = false;
  late Future<void> _loadFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSpinner = true;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture =
        Provider.of<LibraryState>(context, listen: false).initialized;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = Provider.of<LibraryState>(context);
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (libraryState.selectedCourse != null) {
            return widget.child;
          }
          if (!_navigationScheduled) {
            _navigationScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NavigationEnum.home.navigateClean(context);
            });
          }
          return const SizedBox.shrink();
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
