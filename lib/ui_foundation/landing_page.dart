import 'package:flutter/material.dart';

import 'navigation_enum.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
            child: Column(
              children: [
                Text(
                  'Social Learning',
                  style: Theme.of(context).textTheme.headline3,
                ),
                Text(
                  'A learning envirnonment where more more advanced students '
                  'teach you and you teach more beginning students.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                const Spacer(),
                Text(
                  'How to get started',
                  style: Theme.of(context).textTheme.headline4,
                ),
                Text(
                  '1. Come to an event.\n'
                  '2. Sign-in to pair up.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                const Spacer(),
                const Divider(),
                TextButton(
                    onPressed: () {
                      print('got button');
                      Navigator.of(context)
                          .pushNamed(NavigationEnum.sign_in.route);
                    },
                    child: const Text('Register/sign in')),
              ],
            )));
  }
}
