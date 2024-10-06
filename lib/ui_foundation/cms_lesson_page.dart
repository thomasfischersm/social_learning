import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/ui_foundation/helper_widgets/upload_lesson_cover_widget.dart';

class CmsLessonDetailArgument {
  String? levelId;
  String? lessonId;

  CmsLessonDetailArgument(this.levelId, this.lessonId);
}

class CmsLessonPage extends StatefulWidget {
  const CmsLessonPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CmsLessonState();
  }
}

class CmsLessonState extends State<CmsLessonPage> {
  final _titleController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _recapVideoController = TextEditingController();
  final _lessonVideoController = TextEditingController();
  final _practiceVideoController = TextEditingController();
  final _graduationRequirementsController = [TextEditingController()];
  final _instructionsController = TextEditingController();
  DocumentReference? _levelDocRef;
  Lesson? _lesson;
  bool _isAdd = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    CmsLessonDetailArgument? argument =
        ModalRoute.of(context)!.settings.arguments as CmsLessonDetailArgument?;
    if (argument != null) {
      String? levelId = argument.levelId;
      if (levelId != null) {
        _levelDocRef =
            FirebaseFirestore.instance.collection('levels').doc(levelId);
      }

      String? lessonId = argument.lessonId;
      if (lessonId != null) {
        _isAdd = false;

        var libraryState = Provider.of<LibraryState>(context, listen: false);
        _lesson = libraryState.findLesson(lessonId);
        var lesson = _lesson;

        if (lesson != null) {
          _titleController.text = lesson.title;
          _synopsisController.text = lesson.synopsis ?? '';
          _recapVideoController.text = lesson.recapVideo ?? '';
          _lessonVideoController.text = lesson.lessonVideo ?? '';
          _practiceVideoController.text = lesson.practiceVideo ?? '';
          _graduationRequirementsController.clear();
          _graduationRequirementsController.addAll(lesson.graduationRequirements
                  ?.map((requirementText) =>
                      TextEditingController(text: requirementText)) ??
              []);
          _instructionsController.text = lesson.instructions;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(
                Text('Create Lesson', style: CustomTextStyles.headline)),
            Consumer<LibraryState>(
              builder: (context, libraryState, child) {
                return Consumer<ApplicationState>(
                    builder: (context, applicationState, child) {
                  return Table(columnWidths: const <int, TableColumnWidth>{
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  }, children: <TableRow>[
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(const Text('Title:')),
                      TextField(controller: _titleController),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(const Text('Synopsis:')),
                      TextField(
                        controller: _synopsisController,
                        minLines: 3,
                        maxLines: null,
                      ),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Cover photo:')),
                      UploadLessonCoverWidget(_lesson),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Recap video:')),
                      TextField(
                        controller: _recapVideoController,
                        decoration:
                            const InputDecoration(hintText: 'YouTube link'),
                      ),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Lesson video:')),
                      TextField(
                        controller: _lessonVideoController,
                        decoration:
                            const InputDecoration(hintText: 'YouTube link'),
                      ),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Practice video:')),
                      TextField(
                        controller: _practiceVideoController,
                        decoration:
                            const InputDecoration(hintText: 'YouTube link'),
                      ),
                    ]),
                    _generateGraduationRequirementRows(),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Instructions:')),
                      TextField(
                        controller: _instructionsController,
                        maxLines: null,
                        minLines: 5,
                      ),
                    ]),
                  ]);
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      _createUpdateLesson(context);
                    },
                    child: Text(_isAdd ? 'Create' : 'Update')),
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.cmsSyllabus.route),
                    child: const Text('Cancel'))
              ],
            )
          ],
        ))));
  }

  void _createCourse(BuildContext context, String courseName,
      String invitationCode, String description) {
    print('Attempting to create course $courseName');

    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    var libraryState = Provider.of<LibraryState>(context, listen: false);

    libraryState
        .createPrivateCourse(courseName, invitationCode, description,
            applicationState, libraryState)
        .then((course) {
      Navigator.pushNamed(context, NavigationEnum.cmsSyllabus.route);
    });
  }

  _generateGraduationRequirementRows() {
    return TableRow(children: <Widget>[
      CustomUiConstants.getTextPadding(const Text('Graduation requirements:')),
      Column(children: [
        for (var controller in _graduationRequirementsController)
          Row(
            children: [
              Expanded(
                  child: TextField(
                controller: controller,
              )),
              InkWell(
                  onTap: () {
                    _deleteGraduationRequirement(context, controller);
                  },
                  child: Text(' delete',
                      style: CustomTextStyles.getLinkNoUnderline(context))),
            ],
          ),
        InkWell(
            onTap: () {
              _addGraduationRequirement(context);
            },
            child: Text('Add',
                style: CustomTextStyles.getLinkNoUnderline(context))),
      ])
    ]);
  }

  void _deleteGraduationRequirement(
      BuildContext context, TextEditingController controller) async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          String abbreviation = controller.text.length > 7
              ? controller.text.substring(0, 7) + '...'
              : controller.text;

          return AlertDialog(
            title: Text('Delete graduation requirement: $abbreviation'),
            content: const Text('Are you sure you want to delete this?'),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Delete')),
            ],
          );
        });

    if (confirmed == true) {
      setState(() {
        _graduationRequirementsController.remove(controller);
      });
    }
  }

  void _addGraduationRequirement(BuildContext context) {
    setState(() {
      _graduationRequirementsController.add(TextEditingController());
    });
  }

  void _createUpdateLesson(BuildContext context) async {
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    StudentState studentState =
        Provider.of<StudentState>(context, listen: false);

    if (_isAdd) {
      libraryState.createLesson(
          _levelDocRef,
          _titleController.text,
          _synopsisController.text,
          _instructionsController.text,
          _recapVideoController.text,
          _lessonVideoController.text,
          _practiceVideoController.text,
          _graduationRequirementsController.map((e) => e.text).toList().removeBlankStrings(),
          studentState);
    } else {
      var lesson = _lesson;

      if (lesson != null) {
        lesson.title = _titleController.text;
        lesson.synopsis = _synopsisController.text;
        lesson.recapVideo = _recapVideoController.text;
        lesson.lessonVideo = _lessonVideoController.text;
        lesson.practiceVideo = _practiceVideoController.text;
        lesson.graduationRequirements =
            _graduationRequirementsController.map((e) => e.text).toList().removeBlankStrings();
        lesson.instructions = _instructionsController.text;

        libraryState.updateLesson(lesson);
      }
    }

    Navigator.pushNamed(context, NavigationEnum.cmsSyllabus.route);
  }
}

extension on List<String> {
  List<String>? removeBlankStrings() {
    return where((element) => element.trim().isNotEmpty).toList();
  }
}
