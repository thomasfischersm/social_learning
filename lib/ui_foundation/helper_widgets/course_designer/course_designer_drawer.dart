import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart'; // Adjust path

class CourseDesignerDrawer extends StatelessWidget {
  const CourseDesignerDrawer({super.key});

  static IconButton hamburger(GlobalKey<ScaffoldState> scaffoldKey) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
      tooltip: 'Open curriculum designer drawer',
    );
  }

  static const List<_CurriculumStep> steps = [
    _CurriculumStep('Intro', NavigationEnum.courseDesignerIntro),
    _CurriculumStep('Profile', NavigationEnum.courseDesignerProfile),
    _CurriculumStep('Inventory', NavigationEnum.courseDesignerInventory),
    // _CurriculumStep('Dependencies', NavigationEnum.cmsSyllabus),
    // _CurriculumStep('Scoping', NavigationEnum.courseGenerationReview),
    // _CurriculumStep('Skill Dimensions', NavigationEnum.cmsLesson),
    // _CurriculumStep('Learning Outcomes', NavigationEnum.instructorClipboard),
    // _CurriculumStep('Lesson Plan', NavigationEnum.instructorDashBoard),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Course Designer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final step in steps)
            ListTile(
              title: Text(step.title),
              selected: currentRoute == step.nav.route,
              leading: Icon(
                currentRoute == step.nav.route
                    ? Icons.arrow_right
                    : Icons.check_circle_outline,
                color:
                currentRoute == step.nav.route ? Colors.blue : Colors.grey,
              ),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                if (currentRoute != step.nav.route) {
                  step.nav.navigateCleanDelayed(context);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _CurriculumStep {
  final String title;
  final NavigationEnum nav;

  const _CurriculumStep(this.title, this.nav);
}
