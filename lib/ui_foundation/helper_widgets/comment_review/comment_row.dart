import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';

class CommentRow extends StatelessWidget {
  final LessonComment _comment;
  final User? _user;

  const CommentRow(this._comment, this._user, {super.key});

  @override
  Widget build(BuildContext context) {
    bool isSelf = _user?.id == context.read<ApplicationState>().currentUser?.id;

    return DecomposedCourseDesignerCard.buildBody(Container(
        padding: EdgeInsets.only(top: 8),
        child: Row(children: [
          if (_user != null)
            SizedBox(
                width: 50,
                height: 50,
                child: ProfileImageWidgetV2.fromUser(
                  _user!,
                  linkToOtherProfile: true,
                )),
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12.0)),
            child: RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: _user?.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(text: _comment.text),
              if (_comment.createdAt != null)
                const WidgetSpan(child: SizedBox(width: 16)),
              TextSpan(
                text: LessonDetailState.formatCommentTimestamp(
                    _comment.createdAt?.toLocal()),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ])),
          )),
          if (isSelf)
            IconButton(
                onPressed: () {
                  LessonDetailState.deleteComment(context, _comment);
                },
                icon: Icon(Icons.close, color: Colors.grey)),
        ])));
  }
}
