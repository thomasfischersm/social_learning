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
                  'Social Learning',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  'A learning envirnonment where more more advanced students '
                  'teach you and you teach more beginning students.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Text(
                  'How to get started',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '1. Come to an event.\n'
                  '2. Sign-in to pair up.',
                  style: Theme.of(context).textTheme.bodyLarge,
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
