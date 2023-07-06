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
    return Consumer<ApplicationState>(
        builder: (context, applicationState, child) {
      return Consumer<StudentState>(builder: (context, studentState, child) {
        return Consumer<LibraryState>(builder: (context, libraryState, child) {
          LessonDetailArgument? argument = ModalRoute.of(context)!
              .settings
              .arguments as LessonDetailArgument?;
          if (argument != null) {
            String lessonId = argument.lessonId;
            Lesson? lesson = libraryState.findLesson(lessonId);
            Level? level = (lesson != null)
                ? libraryState.findLevelByDocRef(lesson.levelId!)
                : null;
            int levelPosition = libraryState.findLevelPosition(level);

            if ((lesson != null) && (level != null)) {
              var counts = studentState.getCountsForLesson(lesson);

              return Scaffold(
                  appBar: AppBar(title: Text('Lesson: ${lesson.title}')),
                  bottomNavigationBar: const BottomBar(),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showDialog(context, lesson, counts, applicationState);
                      });
                    },
                    child: const Text('Record'),
                  ),
                  body: Center(
                      child: Container(
                          constraints: const BoxConstraints(
                              maxWidth: 310, maxHeight: 350),
                          padding: const EdgeInsets.all(5.0 * 3.1),
                          child: SingleChildScrollView(
                              child: IntrinsicHeight(
                                  child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lesson.cover != null)
                                Expanded(
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(lesson.synopsis ?? '',
                                          style: CustomTextStyles.getBody(
                                              context)),
                                      Text(
                                        _generateLessonStatus(
                                            studentState, counts),
                                        style:
                                            CustomTextStyles.getBody(context),
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
                          ))))));
            }
          }
          return Scaffold(
              appBar: AppBar(title: const Text('Nothing loaded')),
              bottomNavigationBar: const BottomBar(),
              body: const Spacer());
        });
      });
    });
  }

  String _generateLessonStatus(StudentState studentState, LessonCount counts) {
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
      child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(children: [
            const Icon(
              Icons.ondemand_video,
              size: 36,
            ),
            //Icons.video_library_outlined
            Text(label, style: CustomTextStyles.getBody(context))
          ])),
      onTap: () {
        launchUrl(Uri.parse(videoUrl));
      },
    );
  }

  void _showDialog(BuildContext context, Lesson lesson, LessonCount counts,
      ApplicationState applicationState) {
    if (counts.isGraduated ||
        (applicationState.currentUser?.isAdmin ?? false)) {
      _showRecordDialog(context, lesson);
    } else {
      _showDisabledDialog(context);
    }
  }

  void _showDisabledDialog(BuildContext context) {
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
                child: const Text("OK"),
              ),
            ],
            content: const DisabledDialogContent(),
          );
        });
  }

  void _showRecordDialog(BuildContext context, Lesson currentLesson) {
    User? selectedLearner;
    bool isReady = false;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Record Lesson"),
            actions: [
              TextButton(
                  onPressed: () {
                    User? localLearner = selectedLearner;
                    if (localLearner != null) {
                      setState(() {
                        Provider.of<StudentState>(context, listen: false)
                            .recordTeachingWithCheck(
                                currentLesson, localLearner, isReady, context);
                        Navigator.pop(context);
                      });
                    }
                  },
                  child: const Text('Record')),
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
            content: RecordDialogContent(currentLesson,
                (User? student, bool isReadyToGraduate) {
              selectedLearner = student;
              isReady = isReadyToGraduate;
            }),
          );
        });
  }
}

class DisabledDialogContent extends StatefulWidget {
  const DisabledDialogContent({super.key});

  @override
  State<StatefulWidget> createState() {
    return DisabledDialogState();
  }
}

class DisabledDialogState extends State<DisabledDialogContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Once you\'ve mastered this lesson, you will be able to record '
            'that you taught someone here.\n\n'
            'For now, find an instructor or '
            'student to practice this lesson with. They will be able to record '
            'it for you.\n',
            style: CustomTextStyles.getBodyEmphasized(context)),
        Text(
            'Note: There is a difference between having done something once '
            'and being actually proficient at it. Take riding a bicycle '
            'for example. Once you\'ve been able to push off for a couple '
            'yards, you\'ve been riding your bicycle but you are not '
            'proficient yet. Similarly, having done this lesson once is '
            'not the same as having fully learned it.\n\n'
            'Having to graduate a lesson may feel like being held back when '
            'one wants to storm forward. However, a solid foundation is going '
            'to serve you better in the long run. Plus, it\'ll ensure '
            'quality for students learning from other students.\n'
            'However, being held back from graduating shouldn\'t be an '
            'eternal "not yet." Your instructor or mentoring student '
            'should give you specific feedback on what you need to do to '
            'master it.',
            style: CustomTextStyles.getBodyNote(context)),
      ],
    );
  }
}

class RecordDialogContent extends StatefulWidget {
  Lesson lesson;
  Function onUserSelected;

  RecordDialogContent(this.lesson, this.onUserSelected, {super.key});

  @override
  State<StatefulWidget> createState() {
    return RecordDialogState(lesson);
  }
}

class RecordDialogState extends State<RecordDialogContent> {
  Lesson lesson;
  List<User>? _students;
  bool _isReadyToGraduate = false;
  TextEditingController textFieldController = TextEditingController();

  RecordDialogState(this.lesson);

  @override
  Widget build(BuildContext context) {
    if (_students?.length == 1) {
      widget.onUserSelected(_students![0], _isReadyToGraduate);
    } else {
      widget.onUserSelected(null, _isReadyToGraduate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Records that you taught a lesson.'),
        Table(columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth()
        }, children: [
          const TableRow(children: [
            Padding(padding: EdgeInsets.fromLTRB(0,4,4,4), child: Text('Mentor:')),
            Padding(padding: EdgeInsets.all(4), child: Text('You')),
          ]),
          TableRow(children: [
            const Padding(padding: EdgeInsets.fromLTRB(0,4,4,4), child: Text('Learner:')),
            Padding(
                padding: EdgeInsets.all(4),
                child: Column(children: [
                  TextField(
                    onChanged: (value) async {
                      var students =
                          await UserFunctions.findUsersByPartialDisplayName(
                              value, 10);
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
                          return InkWell(
                              onTap: () {
                                setState(() {
                                  _students = [_students![index]];
                                });
                              },
                              child: Row(
                                children: [
                                  if (profileFireStoragePath != null)
                                    Expanded(
                                        child: ProfileImageWidget(
                                            _students![index]
                                                .profileFireStoragePath)),
                                  Text(_students![index].displayName)
                                ],
                              ));
                        },
                      ))
                ])),
          ]),
        ]),
        Row(
          children: [
            Checkbox(
              value: _isReadyToGraduate,
              onChanged: (value) {
                setState(() {
                  _isReadyToGraduate = value ?? false;
                });
              },
            ),
            const Text('The learner is ready to teach this lesson.'),
          ],
        )
      ],
    );
  }
}
