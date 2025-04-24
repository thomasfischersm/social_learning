import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard_summary_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => InstructorDashboardState();
}

class InstructorDashboardState extends State<InstructorDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Consumer<LibraryState>(
                builder: (context, libraryState, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InstructorDashboardSummaryWidget(
                            course: libraryState.selectedCourse),
                      ],
                    )))));
  }
}
