import 'dart:js_interop';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/cms_lesson_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/edit_level_title_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/level_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CmsSyllabusPage extends StatefulWidget {
  const CmsSyllabusPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CmsSyllabusState();
  }
}

class CmsSyllabusState extends State<CmsSyllabusPage> {
  @override
  Widget build(BuildContext context) {
    if (Provider.of<LibraryState>(context, listen: false).selectedCourse ==
        null) {
      print('No course selected. Redirecting to home page.');
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.pushNamed(context, NavigationEnum.home.route);
      });
    }

    return Scaffold(
        appBar: AppBar(title:
            Consumer<LibraryState>(builder: (context, libraryState, child) {
          return Text('${libraryState.selectedCourse?.title} Curriculum');
        })),
        bottomNavigationBar: BottomBarV2.build(context),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              Navigator.pushNamed(context, NavigationEnum.cmsLesson.route);
            });
          },
          child: const Text(
            'Add lesson',
            textAlign: TextAlign.center,
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(Consumer<LibraryState>(
              builder: (context, libraryState, child) => Consumer<StudentState>(
                      builder: (context, studentState, child) {
                    return SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomUiConstants.getTextPadding(Text(
                          '${libraryState.selectedCourse?.title} Curriculum',
                          style: CustomTextStyles.headline,
                        )),
                        if (libraryState.selectedCourse?.invitationCode != null)
                          CustomUiConstants.getTextPadding(Text(
                              'Invitation code: ${libraryState.selectedCourse?.invitationCode}',
                              style: CustomTextStyles.getBody(context))),
                        generateLevelList(context, libraryState),
                        InkWell(
                            onTap: () {
                              _addLevel(context, libraryState);
                            },
                            child: Text('Add level',
                                style: CustomTextStyles.getLinkNoUnderline(
                                    context))),
                        _generateUnattachedLessons(context, libraryState),
                        CustomUiConstants.getGeneralFooter(context)
                      ],
                    ));
                  }))),
        ));
  }

  Widget generateLevelList(BuildContext context, LibraryState libraryState) {
    var levels = libraryState.levels ?? [];
    List<Widget> children = [];
    for (int i = 0; i < levels.length; i++) {
      Level level = levels[i];
      String levelText = 'Level ${i + 1}: ${level.title}';
      children.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Flexible(
                child: InkWell(
                    onTap: () {
                      // _editLevelTitle(level, libraryState);
                      showDialog(
                          context: context,
                          builder: (context) {
                            return EditLevelTitleDialog(level);
                          });
                    },
                    child: Text(
                      levelText,
                      style: CustomTextStyles.subHeadline,
                      maxLines: null,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ))),
            InkWell(
                onTap: () {
                  _deleteLevel(level, context, libraryState);
                },
                child: Text(' delete',
                    style: CustomTextStyles.getLinkNoUnderline(context)))
          ])));

      children.addAll(_generateLessonList(context, level, libraryState));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Iterable<Widget> _generateLessonList(
      BuildContext context, Level? level, LibraryState libraryState) {
    List<Widget> children = [];

    Iterable<Lesson> lessons;
    var levelId = level?.id;
    if (levelId != null) {
      lessons = libraryState.getLessonsByLevel(levelId);
    } else {
      lessons = libraryState.getUnattachedLessons();
    }

    for (Lesson lesson in lessons) {
      if (level != null) {
        children.add(InkWell(
            onTap: () {
              _insertLesson(level, lesson.sortOrder, context, libraryState);
            },
            child: CustomUiConstants.getIndentationTextPadding(Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.blue,
                size:
                    Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0))));
      }

      children.add(Row(children: [
        Flexible(
            child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, NavigationEnum.cmsLesson.route,
                      arguments: CmsLessonDetailArgument(levelId, lesson.id));
                },
                child: CustomUiConstants.getIndentationTextPadding(Text(
                  overflow: TextOverflow.ellipsis,
                  lesson.title,
                  style: CustomTextStyles.getBody(context),
                )))),
        InkWell(
            onTap: () {
              _detachLesson(lesson, context, libraryState);
            },
            child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.blue,
                    size: Theme.of(context).textTheme.bodyLarge?.fontSize ??
                        16.0)))
      ]));
    }

    if (level != null) {
      children.add(InkWell(
          onTap: () {
            int sortOrder = lessons.isNotEmpty
                ? lessons.last.sortOrder + 1
                : libraryState.findSortLessonOrderForEmptyLevel(level);
            _insertLesson(level, sortOrder, context, libraryState);
          },
          child: CustomUiConstants.getIndentationTextPadding(Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.blue,
              size: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0))));
    }

    return children;
  }

  Column _generateUnattachedLessons(
      BuildContext context, LibraryState libraryState) {
    List<Widget> children = [];

    children.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Flex Lessons',
          style: CustomTextStyles.subHeadline,
        )));

    Iterable<Lesson> lessons = libraryState.getUnattachedLessons();
    for (Lesson lesson in lessons) {
      children.add(Row(children: [
        Flexible(
            child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, NavigationEnum.cmsLesson.route,
                      arguments: CmsLessonDetailArgument(null, lesson.id));
                },
                child: CustomUiConstants.getIndentationTextPadding(Text(
                  lesson.title,
                  style: CustomTextStyles.getBody(context),
                  overflow: TextOverflow.ellipsis,
                )))),
        InkWell(
            onTap: () {
              _deleteLesson(lesson, context, libraryState);
            },
            child: Text(' delete',
                style: CustomTextStyles.getLinkNoUnderline(context)))
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  _deleteLevel(
      Level level, BuildContext context, LibraryState libraryState) async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete Level: ${level.title}'),
            content: const Text('Are you sure you want to delete this level?'),
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
      libraryState.deleteLevel(level);
    }
  }

  _addLevel(BuildContext context, LibraryState libraryState) async {
    TextEditingController controller = TextEditingController();
    String? newLevelTitle = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Level'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '<new level title>'),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, controller.text);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });

    if ((newLevelTitle != null) && (newLevelTitle.isNotEmpty)) {
      libraryState.addLevel(newLevelTitle, '');
    }
  }

  void _detachLesson(
      Lesson lesson, BuildContext context, LibraryState libraryState) async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          String abbreviatedTitle = (lesson.title.length > 7)
              ? lesson.title.substring(0, 7) + '...'
              : lesson.title;
          return AlertDialog(
            title: Text('Lesson: $abbreviatedTitle'),
            content: const Text('Are you sure you want to detach this lesson?'),
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
                  child: const Text('Detach')),
            ],
          );
        });

    if (confirmed == true) {
      libraryState.detachLesson(lesson);
    }
  }

  void _insertLesson(Level level, int sortOrder, BuildContext context,
      LibraryState libraryState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LessonSelectionDialog(
            possibleLessons: libraryState.getUnattachedLessons());
      },
    ).then((selectedLesson) {
      // Handle the selected ID here
      if (selectedLesson != null) {
        libraryState.attachLesson(level, selectedLesson, sortOrder);
      }
    });
  }

  void _deleteLesson(
      Lesson lesson, BuildContext context, LibraryState libraryState) async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          String abbreviatedTitle = (lesson.title.length > 7)
              ? '${lesson.title.substring(0, 7)}...'
              : lesson.title;
          return AlertDialog(
            title: Text('Lesson: $abbreviatedTitle'),
            content: const Text('Are you sure you want to delete this lesson?'),
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
                child: const Text('Delete'),
              ),
            ],
          );
        });

    if (confirmed == true) {
      libraryState.deleteLesson(lesson);
    }
  }
}

class LessonSelectionDialog extends StatefulWidget {
  final Iterable<Lesson> possibleLessons;

  const LessonSelectionDialog({super.key, required this.possibleLessons});

  @override
  LessonSelectionDialogState createState() => LessonSelectionDialogState();
}

class LessonSelectionDialogState extends State<LessonSelectionDialog> {
  Lesson? _selectedLesson;

  @override
  void initState() {
    super.initState();
    _selectedLesson =
        widget.possibleLessons.isNotEmpty ? widget.possibleLessons.first : null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.possibleLessons.isEmpty) {
      return AlertDialog(
        title: const Text('No lessons available'),
        content: const Text(
            'Either create a lesson or detach a lesson from a level.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Select a lesson'),
      content: DropdownButton<Lesson>(
        value: _selectedLesson,
        onChanged: (Lesson? newValue) {
          setState(() {
            _selectedLesson = newValue;
          });
        },
        items: widget.possibleLessons.map((Lesson lesson) {
          return DropdownMenuItem<Lesson>(
            value: lesson,
            child: Text(lesson.title),
          );
        }).toList(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop(); // Close the dialog without returning a value
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop(_selectedLesson); // Return the selected value
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
