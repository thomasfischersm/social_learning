import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/lesson_comment_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/comment_review/comment_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/comment_review/lesson_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/comment_review/new_comment_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CommentReviewPage extends StatelessWidget {
  const CommentReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InstructorDashboardAppBar(
        currentNav: NavigationEnum.commentReview,
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comments Review', style: CustomTextStyles.subHeadline),
              SizedBox(height: 8),
              Consumer2<LibraryState, CourseAnalyticsState>(builder:
                  (context, libraryState, courseAnalyticsState, child) {
                Course course = libraryState.selectedCourse!;
                return StreamBuilder<List<LessonComment>>(
                    stream: LessonCommentFunctions.getLessonCommentsForCourse(
                        course),
                    builder: (context, commentSnapshot) {
                      if (commentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (commentSnapshot.hasError) {
                        print(commentSnapshot.error);
                        return Text('Error: ${commentSnapshot.error}');
                      } else {
                        return FutureBuilder<List<User>>(
                            future: courseAnalyticsState.getCourseUsers(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (userSnapshot.hasError) {
                                return Text('Error: ${userSnapshot.error}');
                              } else {
                                return Expanded(
                                  child: _buildListView(
                                      context,
                                      commentSnapshot,
                                      userSnapshot,
                                      libraryState),
                                );
                              }
                            });
                      }
                    });
              })
            ],
          ),
          enableScrolling: false,
          enableCourseLoadingGuard: true,
          enableCreatorGuard: true,
        ),
      ),
    );
  }

  Widget _buildListView(
      BuildContext context,
      AsyncSnapshot<List<LessonComment>>? commentSnapshot,
      AsyncSnapshot<List<User>>? userSnapshot,
      LibraryState libraryState) {
    if (commentSnapshot == null || commentSnapshot.data!.isEmpty) {
      return _buildEmptyCommentsView(context);
    }

    Map<String, List<LessonComment>> lessonCommentsByLessonId = groupBy(
        commentSnapshot.data ?? [],
        (LessonComment comment) => comment.lessonId.id);

    List<User> users = userSnapshot?.data ?? [];
    Map<String, User> usersById = {for (var user in users) user.id: user};

    List<Widget> rows = [];

    for (Lesson lesson in libraryState.lessons ?? []) {
      List<LessonComment>? comments = lessonCommentsByLessonId[lesson.id];
      if (comments == null || comments.isEmpty) {
        continue;
      }

      rows.add(LessonRow(lesson, comments));

      comments.sort((LessonComment a, LessonComment b) =>
          (a.createdAt == null || b.createdAt == null)
              ? 0
              : b.createdAt!.compareTo(a.createdAt!));

      for (LessonComment comment in comments) {
        User? creator = usersById[comment.creatorId.id];
        rows.add(CommentRow(comment, creator));
      }

      rows.add(NewCommentRow(lesson));
      rows.add(DecomposedCourseDesignerCard.buildFooter(bottomMargin: 8));
    }

    return ListView(children: rows);
  }

  Widget _buildEmptyCommentsView(BuildContext context) {
    return Text(
      'No comments have been made in this course.',
      style: CustomTextStyles.getBody(context),
    );
  }
}
