import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class CodeOfConductPage extends StatelessWidget {
  const CodeOfConductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code of Conduct'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Code of Conduct',
                        style: CustomTextStyles.subHeadline,
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: CustomTextStyles.getBody(context),
                          // default style for the content
                          children: [
                            TextSpan(
                              text: '1. Respect and Empathy:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'Treat every participant with dignity. Harassment, bullying, or any form of discriminatory language is strictly prohibited.\n\n',
                            ),
                            TextSpan(
                              text: '2. Stay Focused on the Curriculum:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'Keep discussions centered on the agreed-upon lesson topics. Mentors should stick to the teaching points and avoid sharing unverified opinions. If unsure, say "I don\'t know."\n\n',
                            ),
                            TextSpan(
                              text: '3. No Spam or Unsolicited Promotion:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'The platform is dedicated to learning. Advertising, selling products, or spamming during sessions is not allowed.\n\n',
                            ),
                            TextSpan(
                              text: '4. Constructive Disagreements:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'Engage in healthy debate and listen actively. Disagreements should be respectful and fact-based, avoiding personal attacks.\n\n',
                            ),
                            TextSpan(
                              text: '5. Reciprocity in Learning:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'Those who benefit from sessions are encouraged to eventually give back by teaching others. Balance and mutual support are key.\n\n',
                            ),
                            TextSpan(
                              text: '6. Accountability and Integrity:\n',
                              style: CustomTextStyles.getBodyEmphasized(context),
                            ),
                            TextSpan(
                              text:
                                  'Everyone is responsible for their words and actions. Misbehavior may lead to warnings, suspension, or removal from the session.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Okay'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
