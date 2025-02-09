import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/auto_sign_in_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

import 'ui_constants/navigation_enum.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: CustomUiConstants.framePage(
            Column(
              children: [
                AutoSignInWidget(),
                Text(
                  'Learning Lab',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Spacer(),
                Text(
                  'How it works',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Learning Lab = \nLearn a lesson → Master it → Teach a peer',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Text(
                  'Benefits:',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('• Learn from a peer. Ask questions. Get guidance.\n'
                    '• Skip the isolation/frustration of learning alone.\n'
                    '• Deepen your mastery by teaching.',
                    // '\n'
                    // 'Available for in-person and online!',
                  style: Theme.of(context).textTheme.bodyLarge,),
                const Spacer(),
                Text(
                  'The Learning Revolution is here!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  // 'You learn everything from a mentor. Your mentor answers your questions and gets you unstuck. Your mentor doesn''t have to know everything. They only have to have mastered the lesson at hand. The intelligence of the curriculum guides you through learning the whole subject one piece at a time.',
                  'Learn each lesson with a mentor who’s there to answer your questions and help you get unstuck. Your mentor only needs to master the specific lesson—not the entire subject—so you get clear, focused guidance. An expert-designed curriculum then connects these bite-sized lessons into a complete, effective learning journey.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Text(
                  'How to get started',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Come to an in-person event\n'
                  'or\n'
                  'connect with an online mentor',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                const Divider(),
                TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(NavigationEnum.signIn.route);
                    },
                    child: const Text('Register/sign in')),
              ],
            ),
            enableScrolling: false));
  }
}
