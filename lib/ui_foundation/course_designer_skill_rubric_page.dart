import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_skill_rubric/skill_rubric_info_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_skill_rubric/skill_rubric_list_view_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerSkillRubricPage extends StatelessWidget {
  const CourseDesignerSkillRubricPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: CourseDesignerAppBar(
        title: 'Skill Rubric',
        scaffoldKey: scaffoldKey,
        currentNav: NavigationEnum.courseDesignerSkillRubric,
      ),
      drawer: const CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.courseDesignerLearningObjectives
              .navigateCleanDelayed(context);
        },
        tooltip: 'Next Page',
        child: const Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              const SliverToBoxAdapter(child: SkillRubricInfoCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            body: const SkillRubricListViewCard(),
          ),
          enableScrolling: false,
          enableCreatorGuard: true,
        ),
      ),
    );
  }
}
