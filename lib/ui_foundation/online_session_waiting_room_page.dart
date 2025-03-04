import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OnlineSessionWaitingRoomPage extends StatefulWidget {
  const OnlineSessionWaitingRoomPage({super.key});

  @override
  State<StatefulWidget> createState() => OnlineSessionWaitingRoomState();
}

class OnlineSessionWaitingRoomState extends State<OnlineSessionWaitingRoomPage> {
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key('MyPage'),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > 0) {
            _startTimers(); // Page is visible, start timers
          } else {
            _cancelTimers(); // Page is hidden, stop timers
          }
        },
        child:  Scaffold(
            appBar: AppBar(
              title: const Text('Social Learning'),
            ),
            bottomNavigationBar: BottomBarV2.build(context),
            body: Align(
              alignment: Alignment.topCenter,
              child: CustomUiConstants.framePage(
                enableScrolling: false,
                Consumer<ApplicationState>(
                    builder: (context, applicationState, child) {
                  return Consumer<OnlineSessionState>(
                      builder: (context, onlineSessionState, child) {
                    String? sessionId = onlineSessionState.waitingSession?.id;
                    if (sessionId == null) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      return StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                          stream: OnlineSessionFunctions.getSessionStream(
                              sessionId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            // Session no longer exists, so navigate away.
                            if (!snapshot.data!.exists) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.pushNamed(
                                    context, NavigationEnum.sessionHome.route);
                              });
                              return Container();
                            }

                            // The session has become active, redirect to the active session page.
                            OnlineSession session =
                                OnlineSession.fromSnapshot(snapshot.data!);
                            if (session.status == OnlineSessionStatus.active) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                OnlineSessionState onlineSessionState =
                                    Provider.of<OnlineSessionState>(context,
                                        listen: false);
                                onlineSessionState.setActiveSession(session);

                                Navigator.pushNamed(context,
                                    NavigationEnum.onlineSessionActive.route);
                              });
                              return Container();
                            }

                            String sessionTypeText = session.isMentorInitiated
                                ? 'Teaching'
                                : 'Learning';
                            return Column(
                              children: [
                                // Header & status.
                                Text(
                                  'You are in the $sessionTypeText waiting room.',
                                  style: CustomTextStyles.headline,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                // Status message.
                                Text(
                                  'Waiting for another student to connect...',
                                  style: CustomTextStyles.subHeadline,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 32),
                                Text(
                                  'Video Call URL:',
                                  style: CustomTextStyles.getBody(context),
                                ),
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _launchVC(session.videoCallUrl),
                                  child: Text(
                                    session.videoCallUrl ?? 'No URL provided',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Spacer(),
                                // Cancel Session button.
                                ElevatedButton.icon(
                                  onPressed: _onCancelPressed,
                                  icon: Icon(Icons.cancel),
                                  label: Text('Cancel Session'),
                                  style: ElevatedButton.styleFrom(
                                    // primary: Colors.red, // Red button for cancellation.
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            );
                          });
                    }
                  });
                }),
              ),
            )));
  }

  Future<void> _launchVC(String? videoCallUrl) async {
    if (videoCallUrl == null) {
      return;
    }

    Uri uri = Uri.parse(videoCallUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error: URL couldn't be launched.
      debugPrint('Could not launch $videoCallUrl');
    }
  }

  Timer? _idleTimer;
  Timer? _promptTimer;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _startTimers();
    print('started waiting room timers');
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _startTimers() {
    _startIdleTimer();
    _startHeartbeatTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer =
        Timer(OnlineSessionFunctions.CONFIRMATION_TIMEOUT, _showIdlePrompt);
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(OnlineSessionFunctions.HEARTBEAT_INTERVAL,
        (timer) async {
      OnlineSessionState onlineSessionState =
          Provider.of<OnlineSessionState>(context, listen: false);
      OnlineSession? session = onlineSessionState.waitingSession;

      if (session != null) {
        await OnlineSessionFunctions.updateHeartbeat(session.id!);
      }
    });
  }

  void _cancelTimers() {
    print('Canceling waiting room timers');
    _idleTimer?.cancel();
    _promptTimer?.cancel();
    _heartbeatTimer?.cancel();
  }

  /// Show a modal prompt asking if the user is still present.
  Future<void> _showIdlePrompt() async {
    // Start a prompt timer that will auto-cancel the session if the user does not respond.
    _promptTimer?.cancel();
    _promptTimer =
        Timer(OnlineSessionFunctions.CONFIRMATION_RESPONSE_TIMEOUT, () {
      _cancelSession(true);
    });

    // Show the prompt dialog.
    bool? stillHere = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you still there?'),
          content: Text(
              'You have been inactive for a while. Please confirm that you are still waiting for another student to connect.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chooses to cancel.
              },
              child: Text('Cancel Session'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // User confirms they are still here.
              },
              child: Text("I'm Here"),
            ),
          ],
        );
      },
    );

    _promptTimer?.cancel();

    if (stillHere == true) {
      // Restart the idle timer if user is still active.
      _startIdleTimer();
    } else {
      // Cancel session if user did not confirm.
      _cancelSession(false);
    }
  }

  Future<void> _cancelSession(bool isCancelledDueToInactivity) async {
    OnlineSessionState onlineSessionState =
        Provider.of<OnlineSessionState>(context, listen: false);
    OnlineSession? session = onlineSessionState.waitingSession;

    // Cancel the session in Firestore if the session document exists.
    if (session != null) {
      await OnlineSessionFunctions.cancelSession(session.id!);
      onlineSessionState.setWaitingSession(null);
    }
    // Notify the user and navigate away (e.g. back to the home screen).
    if (mounted) {
      String cancelMessage = isCancelledDueToInactivity
          ? 'Session cancelled due to inactivity.'
          : 'Session cancelled.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cancelMessage)),
      );
      if (mounted) {
        Navigator.pushNamed(context, NavigationEnum.sessionHome.route);
      }
    }
  }

  void _onCancelPressed() {
    // Cancel manually if the user taps the cancel button.
    _cancelSession(false);
  }
}
