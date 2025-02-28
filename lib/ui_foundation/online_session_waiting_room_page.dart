import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class OnlineSessionWaitingRoomPage extends StatefulWidget {
  const OnlineSessionWaitingRoomPage({super.key});

  @override
  State<StatefulWidget> createState() => OnlineSessionWaitingRoomState();
}

class OnlineSessionWaitingRoomState extends State<OnlineSessionWaitingRoomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Learning'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(Consumer<ApplicationState>(
            builder: (context, applicationState, child) {
          return Text('Fill me in! - waiting room');
        })),
      ),
    );
  }
}
