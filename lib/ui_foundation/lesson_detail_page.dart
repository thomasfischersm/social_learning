import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/graduation_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';
import 'package:social_learning/ui_foundation/profile_image_widget.dart';
import 'package:url_launcher/url_launcher.dart';

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
        Lesson? lesson = libraryState.findLesson(lessonId);
        Level? level = (lesson != null)
            ? libraryState.findLevelByDocRef(lesson.levelId!)
            : null;
        int levelPosition = libraryState.findLevelPosition(level);

        if ((lesson != null) && (level != null)) {
          return Scaffold(
            appBar: AppBar(title: Text('Lesson: ${lesson.title}')),
            bottomNavigationBar: const BottomBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  showGraduationDialog(context, lesson);
                });
              },
              child: const Text('Record'),
            ),
            body: Center(
                child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 310, maxHeight: 350),
                    padding: const EdgeInsets.all(5.0 * 3.1),
                    child: SingleChildScrollView(child: Consumer<LibraryState>(
                        builder: (context, libraryState, child) {
                      return Consumer<StudentState>(
                          builder: (context, studentState, child) {
                        return IntrinsicHeight(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (lesson.cover != null)
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Image(
                                          image: AssetImage(lesson.cover!),
                                          fit: BoxFit.contain))),
                            Text('Level ${levelPosition + 1}',
                                style: CustomTextStyles.getBody(context)),
                            Text('Lesson: ${lesson.title}',
                                style: CustomTextStyles.subHeadline),
                            Row(
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lesson.synopsis ?? '',
                                        style:
                                            CustomTextStyles.getBody(context)),
                                    Text(
                                      _generateLessonStatus(
                                          studentState, lesson),
                                      style: CustomTextStyles.getBody(context),
                                    ),
                                  ],
                                )),
                                if (lesson.recapVideo != null)
                                  _addVideoIcon(
                                      lesson.recapVideo!, 'Recap', context),
                                if (lesson.lessonVideo != null)
                                  _addVideoIcon(
                                      lesson.lessonVideo!, 'Lesson', context),
                                if (lesson.practiceVideo != null)
                                  _addVideoIcon(lesson.practiceVideo!,
                                      'Practice', context),
                              ],
                            ),
                            CustomUiConstants.getDivider(),
                            _generateInstructionText(lesson, context)
                          ],
                        ));
                      });
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

  String _generateLessonStatus(StudentState studentState, Lesson lesson) {
    var counts = studentState.getCountsForLesson(lesson);
    String str = '';

    if (counts.practiceCount > 0) {
      str += 'Practiced: ${counts.practiceCount}';
    }

    if ((counts.practiceCount > 0) && (counts.teachCount > 0)) {
      str += ', ';
    }

    if (counts.teachCount > 0) {
      str += 'Taught: ${counts.teachCount}';
    }

    if (str.isNotEmpty) {
      str = '\n$str';
    }

    return str;
  }

  Widget _generateInstructionText(Lesson lesson, BuildContext context) {
    List<TextSpan> textSpans = [];

    List<String> instructions =
        lesson.instructions.replaceAll('\r', '').split('\n');
    print('\\n at ${lesson.instructions.indexOf('\n')} ${instructions.length}');

    for (String str in instructions) {
      str = str.trim();
      if (str.endsWith('---')) {
        str = str.substring(0, str.length - 3);
        textSpans
            .add(TextSpan(text: '$str\n', style: CustomTextStyles.subHeadline));
      } else {
        textSpans.add(
            TextSpan(text: '$str\n', style: CustomTextStyles.getBody(context)));
      }
    }

    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: RichText(
            text: TextSpan(
                text: 'Instructions\n',
                style: CustomTextStyles.subHeadline,
                children: textSpans)));
  }

  Widget _addVideoIcon(String videoUrl, String label, BuildContext context) {
    return InkWell(
      child: Padding(padding: const EdgeInsets.all(4), child: Column(children: [
        const Icon(Icons.ondemand_video, size: 36,), //Icons.video_library_outlined
        Text(label, style: CustomTextStyles.getBody(context))
      ])),
      onTap: () {
        launchUrl(Uri.parse(videoUrl));
      },
    );
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
