import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class LessonDetailArgument {
  String lessonId;

  LessonDetailArgument(this.lessonId);
}

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return new LessonDetailState();
  }
}

class LessonDetailState extends State<LessonDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryState>(builder: (context, libraryState, child) {
      LessonDetailArgument? argument =
          ModalRoute.of(context)!.settings.arguments as LessonDetailArgument?;
      if (argument != null) {
        String lessonId = argument.lessonId;
        Lesson? selectedLesson = libraryState.findLesson(lessonId);
        Lesson? previousLesson =
            libraryState.findPreviousLesson(selectedLesson);
        Lesson? nextLesson = libraryState.findNextLesson(selectedLesson);

        if (selectedLesson != null) {
          return Scaffold(
            appBar: AppBar(title: Text('Lessons: ${selectedLesson.title}')),
            bottomNavigationBar: const BottomBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  showGraduationDialog(context, selectedLesson);
                });
              },
              child: Text('Graduate'),
            ),
            body: Center(
                child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 310, maxHeight: 350),
                    child: Consumer<LibraryState>(
                        builder: (context, libraryState, child) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                selectedLesson.title,
                                style: Theme.of(context).textTheme.headline3,
                              )),
                              if (previousLesson != null)
                                IconButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context,
                                          NavigationEnum.lesson_detail.route,
                                          arguments: LessonDetailArgument(
                                              previousLesson.id));
                                    },
                                    icon: Icon(Icons.arrow_left)),
                              if (nextLesson != null)
                                IconButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context,
                                          NavigationEnum.lesson_detail.route,
                                          arguments: LessonDetailArgument(
                                              nextLesson.id));
                                    },
                                    icon: Icon(Icons.arrow_right))
                            ],
                          ),
                          Text(
                            selectedLesson.instructions,
                            style: Theme.of(context).textTheme.bodyText1,
                          )
                        ],
                      );
                    }))),
          );
        }
      }

      // Fall through if the route argument is bad.
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.pushNamed(context, NavigationEnum.home.route);
      });
      return const Scaffold();
    });
  }

  void showGraduationDialog(BuildContext context, Lesson currentLesson) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Graduate student"),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: Text("Cancel"),
              ),
            ],
            content: GraduationDialogContent(currentLesson),
          );
        });
  }
}

class GraduationDialogContent extends StatefulWidget {
  Lesson lesson;

  GraduationDialogContent(this.lesson, {super.key});

  @override
  State<StatefulWidget> createState() {
    return GraduationDialogState(lesson);
  }
}

class GraduationDialogState extends State<GraduationDialogContent> {
  Lesson lesson;
  List<User>? _students;
  String _partialName = '';

  GraduationDialogState(this.lesson);

  @override
  Widget build(BuildContext context) {
    TextEditingController textFieldController = TextEditingController(text: _partialName);
    String partialDisplayName;

    return Column(
      children: [
        TextField(
          onChanged: (value) async {
            _partialName = value;
            var students =
                await UserFunctions.findUsersByPartialDisplayName(value);
            setState(() {
              _students = students;
            });
          },
          controller: textFieldController,
          decoration: const InputDecoration(
              hintText:
                  'Start typing the display name of the student whom you want to graduate.'),
        ),
        SizedBox(
          width:200,
            height: 200,
            child:ListView.builder(
          itemCount: _students?.length ?? 0,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Text(_students![index].displayName),
                TextButton(
                    onPressed: () {
                      print(
                          'Graduating ${_students![index].displayName} in ${lesson.title}');
                    },
                    child: Text('Graduate'))
              ],
            );
          },
        ))
      ],
    );
  }
}
