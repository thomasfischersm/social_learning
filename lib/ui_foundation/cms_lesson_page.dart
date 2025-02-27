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
  String? _titleError = null;
  String? _synopsisError = null;
  String? _instructionsError = null;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

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
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              _createUpdateLesson(context);
            },
            child: const Icon(Icons.done)),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomUiConstants.getTextPadding(
                    Text('Create Lesson', style: CustomTextStyles.headline)),
                Consumer<LibraryState>(
                  builder: (context, libraryState, child) {
                    return Consumer<ApplicationState>(
                        builder: (context, applicationState, child) {
                      return Column(
                        children: [
                          _createCoreCard(context),
                          SizedBox(height: 8),
                          _createGraduationRequirementsCard(context),
                          SizedBox(height: 8),
                          _createVideoCard(context)
                        ],
                      );
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // TextButton(
                        // onPressed: () {
                        //   _createUpdateLesson(context);
                        // },
                        // child: Text(_isAdd ? 'Create' : 'Update')),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, NavigationEnum.cmsSyllabus.route),
                        child: const Text('Cancel'))
                  ],
                )
              ],
            ))));
  }

  Widget _createCoreCard(BuildContext context) {
    return Card(
        child: Column(children: [
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Text(
            'Essentials',
            style: CustomTextStyles.subHeadline,
          )),
      SizedBox(height: 8),
      Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Column(children: [
            TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Lesson title',
                  errorText: _titleError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
            SizedBox(height: 8),
            TextField(
                controller: _synopsisController,
                minLines: 3,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Synopsis',
                  errorText: _synopsisError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
            SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                labelText: 'Instructions',
                errorText: _instructionsError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 8),
            UploadLessonCoverWidget(_lesson),
            SizedBox(height: 8,),
          ]))
    ]));
  }

  Widget _createGraduationRequirementsCard(BuildContext context) {
    return Card(
        child: Column(children: [
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Text(
            'Graduation requirements',
            style: CustomTextStyles.subHeadline,
          )),
      SizedBox(height: 8),
      Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Column(children: [
            for (var controller in _graduationRequirementsController)
              Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      )),
                      InkWell(
                          onTap: () {
                            _deleteGraduationRequirement(context, controller);
                          },
                          child: Text(' delete',
                              style: CustomTextStyles.getLinkNoUnderline(
                                  context))),
                    ],
                  )),
            InkWell(
                onTap: () {
                  _addGraduationRequirement(context);
                },
                child: Text('Add',
                    style: CustomTextStyles.getLinkNoUnderline(context))),
          ]))
    ]));
  }

  _createVideoCard(BuildContext context) {
    return Card(
        child: Column(children: [
      Container(
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Text(
            'Videos',
            style: CustomTextStyles.subHeadline,
          )),
      SizedBox(height: 8),
      Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Column(children: [
            TextField(
                controller: _recapVideoController,
                decoration: InputDecoration(
                  labelText: 'Recap video (YouTube URL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
            SizedBox(height: 8),
            TextField(
                controller: _lessonVideoController,
                decoration: InputDecoration(
                  labelText: 'Lesson video (YouTube URL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
            SizedBox(height: 8),
            TextField(
                controller: _practiceVideoController,
                decoration: InputDecoration(
                  labelText: 'Practice video (YouTube URL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
            SizedBox(height: 8),
          ]))
    ]));
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
              TextField(
                controller: _instructionsController,
                maxLines: null,
                minLines: 5,
              ),
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
              ElevatedButton(
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
    if (!_validateInput()) {
      return;
    }

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
          _graduationRequirementsController
              .map((e) => e.text)
              .toList()
              .removeBlankStrings(),
          studentState);
    } else {
      var lesson = _lesson;

      if (lesson != null) {
        lesson.title = _titleController.text;
        lesson.synopsis = _synopsisController.text;
        lesson.recapVideo = _recapVideoController.text;
        lesson.lessonVideo = _lessonVideoController.text;
        lesson.practiceVideo = _practiceVideoController.text;
        lesson.graduationRequirements = _graduationRequirementsController
            .map((e) => e.text)
            .toList()
            .removeBlankStrings();
        lesson.instructions = _instructionsController.text;

        libraryState.updateLesson(lesson);
      }
    }

    Navigator.pushNamed(context, NavigationEnum.cmsSyllabus.route);
  }

  bool _validateInput() {
    _titleError = null;
    _synopsisError = null;
    _instructionsError = null;

    if (_titleController.text.trim().length < 3) {
      _titleError = 'Too short';
    }

    if (_synopsisController.text.trim().length < 3) {
      _synopsisError = 'Too short';
    }

    if (_instructionsController.text.trim().length < 3) {
      _instructionsError = 'Too short';
    }

    setState(() {});

    if (_titleError != null || _synopsisError != null ||
        _instructionsError != null) {
      return false;
    } else {
      return true;
    }
  }
}

extension on List<String> {
  List<String>? removeBlankStrings() {
    return where((element) => element.trim().isNotEmpty).toList();
  }
}
