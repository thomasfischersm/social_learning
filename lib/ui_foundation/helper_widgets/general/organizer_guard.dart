import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class OrganizerGuard extends StatefulWidget {
  final Widget child;

  const OrganizerGuard({super.key, required this.child});

  @override
  State<OrganizerGuard> createState() => _OrganizerGuardState();
}

class _OrganizerGuardState extends State<OrganizerGuard> {
  bool _navigationScheduled = false;

  @override
  Widget build(BuildContext context) {
    final organizerSessionState = Provider.of<OrganizerSessionState>(context);
    final libraryState = Provider.of<LibraryState>(context);
    final applicationState = Provider.of<ApplicationState>(context);

    final session = organizerSessionState.currentSession;
    final selectedCourse = libraryState.selectedCourse;
    final currentUser = applicationState.currentUser;

    final isReadyToEvaluate =
        organizerSessionState.isInitialized && selectedCourse != null;

    final isOrganizerForActiveSession = session != null &&
        session.isActive &&
        selectedCourse?.id == session.courseId.id &&
        currentUser?.uid == session.organizerUid;

    if (isReadyToEvaluate && !isOrganizerForActiveSession) {
      _scheduleRedirect();
      return const SizedBox.shrink();
    }

    if (!isReadyToEvaluate) {
      return const Center(child: CircularProgressIndicator());
    }

    return widget.child;
  }

  void _scheduleRedirect() {
    if (_navigationScheduled) {
      return;
    }

    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NavigationEnum.sessionHome.navigateClean(context);
      }
    });
  }
}
