import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_roster_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_summary_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => InstructorDashboardState();
}

class InstructorDashboardState extends State<InstructorDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InstructorDashboardAppBar(
        currentNav: NavigationEnum.instructorDashBoard,
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          enableCourseLoadingGuard: true,
          Consumer<LibraryState>(
            builder: (context, libraryState, child) {
              final course = libraryState.selectedCourse;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  final slivers = <Widget>[];
                  if (course != null) {
                    slivers.add(
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'Dashboard: ${course.title}',
                            style: CustomTextStyles.subHeadline,
                          ),
                        ),
                      ),
                    );
                  }
                  slivers.add(
                    SliverToBoxAdapter(
                      child: InstructorDashboardSummaryWidget(
                        course: course,
                      ),
                    ),
                  );
                  return slivers;
                },
                body: InstructorDashboardRosterWidget(course: course),
              );
            },
          ),
        ),
      ),
    );
  }
}
