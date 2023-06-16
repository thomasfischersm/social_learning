import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/graduation_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';
import 'package:social_learning/ui_foundation/profile_image_widget.dart';

class LessonDetailArgument {
  String lessonId;

  LessonDetailArgument(this.lessonId);
}

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LessonDetailState();
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
              child: const Text('Graduate'),
            ),
            body: Center(
                child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 310, maxHeight: 350),
                    child: SingleChildScrollView(child: Consumer<LibraryState>(
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
                                          NavigationEnum.lessonDetail.route,
                                          arguments: LessonDetailArgument(
                                              previousLesson.id!));
                                    },
                                    icon: Icon(Icons.arrow_left)),
                              if (nextLesson != null)
                                IconButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context,
                                          NavigationEnum.lessonDetail.route,
                                          arguments: LessonDetailArgument(
                                              nextLesson.id!));
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
                    })))),
          );
        }
      }

      return Scaffold(
          appBar: AppBar(title: const Text('Nothing loaded')),
          bottomNavigationBar: const BottomBar(),
          body: const Spacer());
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
  TextEditingController textFieldController = TextEditingController();

  GraduationDialogState(this.lesson);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: (value) async {
            var students =
                await UserFunctions.findUsersByPartialDisplayName(value, 10);
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
            width: 200,
            height: 200,
            child: ListView.builder(
              itemCount: _students?.length ?? 0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                var profileFireStoragePath =
                    _students![index].profileFireStoragePath;
                return Row(
                  children: [
                    if (profileFireStoragePath != null)
                      Expanded(
                          child: ProfileImageWidget(
                              _students![index].profileFireStoragePath)),
                    Text(_students![index].displayName),
                    TextButton(
                        onPressed: () {
                          Provider.of<GraduationState>(context, listen: false)
                              .graduate(lesson, _students![index]);
                          Navigator.pop(context);
                        },
                        child: const Text('Graduate'))
                  ],
                );
              },
            ))
      ],
    );
  }
}
