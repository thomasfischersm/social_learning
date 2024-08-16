import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/level_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.pushNamed(context, NavigationEnum.home.route);
      });
    }

    return Scaffold(
        appBar: AppBar(title:
            Consumer<LibraryState>(builder: (context, libraryState, child) {
          return Text('${libraryState.selectedCourse?.title} Curriculum');
        })),
        bottomNavigationBar: const BottomBar(),
        body: Center(
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
                        generateLevelList(context, libraryState),
                        InkWell(
                            onTap: () {
                              _addLevel(context, libraryState);
                            },
                            child: Text('Add level',
                                style: CustomTextStyles.getLinkNoUnderline(
                                    context))),
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
      children.add(Row(children: [
        InkWell(
            onTap: () {
              _editLevelTitle(level, libraryState);
            },
            child: Text(
              levelText,
              style: CustomTextStyles.subHeadline,
            )),
        InkWell(
            onTap: () {
              _deleteLevel(level, context, libraryState);
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

  _editLevelTitle(Level level, LibraryState libraryState) async {
    TextEditingController controller = TextEditingController(text: level.title);

    String? newLevelTitle = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit Level Title'),
            content: TextField(controller: controller),
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
                child: const Text('Save'),
              ),
            ],
          );
        });

    if ((newLevelTitle != null) && (newLevelTitle.isNotEmpty)) {
      level.title = newLevelTitle;
      libraryState.updateLevel(level);
    }
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
}
