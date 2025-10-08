import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/lesson_comment_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';

class NewCommentRow extends StatefulWidget {
  final Lesson _lesson;

  const NewCommentRow(this._lesson, {super.key});

  @override
  State<StatefulWidget> createState() => NewCommentRowState();
}

class NewCommentRowState extends State<NewCommentRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(Container(
        padding: EdgeInsets.only(top: 8),
        child: Row(children: [
          Expanded(
              child: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Add a comment'),
          )),
          SizedBox(width: 4),
          ElevatedButton(onPressed: _addComment, child: Icon(Icons.send))
        ])));
  }

  void _addComment() {
    String comment = _controller.text.trim();
    User? user = context.read<ApplicationState>().currentUser;

    if (user != null && !comment.isEmpty) {
      LessonCommentFunctions.addLessonComment(widget._lesson, comment, user);
    }
  }
}
