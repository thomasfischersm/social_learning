import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CmsStartPage extends StatelessWidget {
  const CmsStartPage({super.key});

  void _openQuickStart(BuildContext context) {
    NavigationEnum.cmsSyllabus.navigateClean(context);
  }

  void _openGuidedFlow(BuildContext context) {
    NavigationEnum.courseDesignerIntro.navigateClean(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Center(
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CmsStartCard(
                        title: 'Quick Start!',
                        description:
                            'Jump directly to creating lessons and levels.',
                        onTap: () => _openQuickStart(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CmsStartCard(
                        title: 'Guided Flow',
                        description:
                            'Follow a step-by-step process to create a course.',
                        onTap: () => _openGuidedFlow(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CmsStartCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CmsStartCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = CustomTextStyles.subHeadline;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final linkStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(decorationColor: Colors.blue);

    return SizedBox.expand(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: bodyStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Open', style: linkStyle),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
