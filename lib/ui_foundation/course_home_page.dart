import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_home/progress_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_home/next_lesson_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_home/progress_video_feed.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

import '../data/course.dart';

class CourseHomePage extends StatefulWidget {
  const CourseHomePage({super.key});

  @override
  State<CourseHomePage> createState() => _CourseHomePageState();
}

class _CourseHomePageState extends State<CourseHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(title: 'Home'),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(enableCourseLoadingGuard: true,
              Consumer<LibraryState>(builder: (context, libraryState, child) {
            Course? course = libraryState.selectedCourse;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course != null) ...[
                  Row(
                    children: [
                      Expanded(
                          child: Text(course.title,
                              style: CustomTextStyles.headline)),
                      IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) => Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(course.description ?? ''),
                                    ));
                          },
                          icon: const Icon(Icons.info_outline))
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(child: ProgressCard()),
                      SizedBox(width: 8, height: double.infinity),
                      Expanded(child: NextLessonCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Community activity', style: CustomTextStyles.subHeadline),
                const SizedBox(height: 8),
                const ProgressVideoFeed(),
              ],
            );
          }))),
    );
  }
}
