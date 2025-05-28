import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerIntroPage extends StatefulWidget {
  const CourseDesignerIntroPage({super.key});

  @override
  State<CourseDesignerIntroPage> createState() =>
      _CourseDesignerIntroPageState();
}

class _CourseDesignerIntroPageState extends State<CourseDesignerIntroPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Learning Lab'),
        leading: CourseDesignerDrawer.hamburger(scaffoldKey),
        actions: InstructorNavActions.createActions(context),
      ),
      drawer: const CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationEnum.courseDesignerProfile.navigateCleanDelayed(context);
        }, // or Icons.navigate_next
        tooltip: 'Next Page',
        child: Icon(Icons.arrow_forward),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: true,
          enableCreatorGuard: true,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              CourseDesignerCard(
                title: 'What you’ll do',
                body: _StepsBody(),
              ),
              CourseDesignerCard(
                title: 'Key terms',
                body: _KeyTermsBody(),
              ),
              CourseDesignerCard(
                title: 'Information and ability',
                body: _InfoVsAbilityBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepsBody extends StatelessWidget {
  const _StepsBody();

  @override
  Widget build(BuildContext context) {
    final base = CustomTextStyles.getBody(context);
    final bold = CustomTextStyles.getBodyEmphasized(context);

    Widget row(String label, String text) {
      return RichText(
        text: TextSpan(
          style: base,
          children: [
            TextSpan(text: '• ', style: base),
            TextSpan(text: '$label – ', style: bold),
            TextSpan(text: text, style: base),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blank pages are intimidating. This flow offers bite‑size prompts so you can plan faster and with less guess‑work.',
          style: base,
        ),
        const SizedBox(height: 12),
        row('Inventory', 'brain dump teachable elements'),
        row('Prerequisites', 'sequence the learning'),
        row('Scope', 'flip items on/off to fit the time constraints'),
        row('Skill dimensions',
            'develop a rubric and plan for developing student abilities'),
        row('Learning outcomes',
            'start with the result and work back to lessons'),
        row('Session outline',
            'drag lessons, breaks, and warm‑ups into a teaching agenda'),
        const SizedBox(height: 8),
        Text(
          '(Jump between steps anytime from the left‑menu.)',
          style: CustomTextStyles.getBodyNote(context),
        ),
      ],
    );
  }
}

class _KeyTermsBody extends StatelessWidget {
  const _KeyTermsBody();

  @override
  Widget build(BuildContext context) {
    final labelStyle = CustomTextStyles.getBodyEmphasized(context);
    final valueStyle = CustomTextStyles.getBody(context);
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(children: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('Teachable item', style: labelStyle)),
          Text('Smallest concept or skill unit', style: valueStyle),
        ]),
        TableRow(children: [
          Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: Text('Mini‑lesson', style: labelStyle)),
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('A method for teaching one item', style: valueStyle)),
        ]),
        TableRow(children: [
          Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: Text('Session outline', style: labelStyle)),
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Agenda for a class period', style: valueStyle)),
        ]),
      ],
    );
  }
}

class _InfoVsAbilityBody extends StatelessWidget {
  const _InfoVsAbilityBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      'A lot of courses are designed around transmitting information. '
      'What\'s often left out is how to develop the student\'s ability. '
      'For example, knowing about a dance figure and being a great dancer are two separate things. '
      'By structuring a curriculum around skill dimensions, students become great practitioners.',
      style: CustomTextStyles.getBody(context),
    );
  }
}
