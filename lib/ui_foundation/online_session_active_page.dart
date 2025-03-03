import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/session_widgets/active_online_session_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class OnlineSessionActivePage extends StatefulWidget {
  const OnlineSessionActivePage({super.key});

  @override
  State<StatefulWidget> createState() => OnlineSessionActiveState();
}

class OnlineSessionActiveState extends State<OnlineSessionActivePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Learning'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _endSession(context),
        child:  Icon(Icons.call_end),
      ),
      body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(Consumer<ApplicationState>(
              builder: (context, applicationState, child) {
                return Consumer<OnlineSessionState>(
                    builder: (context, onlineSessionState, child) {
                      String? sessionId = onlineSessionState.waitingSession?.id;
                      if (sessionId == null) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        return StreamBuilder<DocumentSnapshot<Map<
                            String,
                            dynamic>>>(
                            stream: OnlineSessionFunctions.getSessionStream(
                                sessionId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              // Session no longer exists, so navigate away.
                              if (!snapshot.data!.exists) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                    _) {
                                  Navigator.pushNamed(
                                      context,
                                      NavigationEnum.sessionHome.route);
                                });
                                return Container();
                              }

                              LibraryState libraryState = Provider.of<
                                  LibraryState>(context);

                              OnlineSession session = OnlineSession
                                  .fromSnapshot(snapshot.data!);
                              Lesson? lesson = libraryState.findLesson(
                                  session.lessonId!.id);

                              String? otherUserUid = session.mentorUid ==
                                  applicationState.currentUser!.uid
                                  ? session.learnerUid
                                  : session.mentorUid;
                              return FutureBuilder(
                                  future: UserFunctions.getUserByUid(
                                      otherUserUid!),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    } else {
                                      return ActiveOnlineSessionCard(
                                          session: session,
                                          currentUser: applicationState
                                              .currentUser!,
                                          partner: userSnapshot.data!,
                                          lesson: lesson!);
                                    }
                                  });
                            });
                      }
                    });
              }))),
    );
  }

  _endSession(BuildContext context) {
    OnlineSessionState onlineSessionState = Provider.of<OnlineSessionState>(
        context, listen: false);
    OnlineSession? session = onlineSessionState.activeSession;
    
    if (session != null) {
      OnlineSessionFunctions.endSession(session.id!);
    }

    // TODO: Re-direct to get a rating.
    Navigator.pushNamed(context, NavigationEnum.sessionHome.route);
  }
}
