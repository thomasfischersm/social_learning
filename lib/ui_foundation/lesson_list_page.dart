import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/graduation_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class LessonListPage extends StatefulWidget {
  const LessonListPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LessonListState();
  }
}

class LessonListState extends State<LessonListPage> {
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
        return Text('Lessons: ${libraryState.selectedCourse?.title}');
      })),
      bottomNavigationBar: const BottomBar(),
      body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              child: Consumer<LibraryState>(
                  builder: (context, libraryState, child) {
                return ListView.builder(
                    itemCount: libraryState.lessons?.length ?? 0,
                    itemBuilder: (context, index) {
                      return InkWell(onTap: () {
                        Lesson? lesson = libraryState.lessons?[index];
                        if ((lesson != null) && (!lesson.isLevel)) {
                          Navigator.pushNamed(
                              context, NavigationEnum.lessonDetail.route,
                              arguments: LessonDetailArgument(lesson.id!));
                        }
                      }, child: Consumer<GraduationState>(
                          builder: (context, graduationState, child) {
                        return (libraryState.lessons?[index].isLevel ?? false)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                    'Level ${_getLevelNumber(libraryState.lessons, index)}: ${libraryState.lessons?[index].title}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge))
                            : Text(
                                libraryState.lessons?[index].title ?? 'error',
                                style: TextStyle(
                                    color: (graduationState.hasGraduated(
                                            libraryState.lessons?[index]))
                                        ? Colors.green
                                        : Colors.black),
                              );
                      }));
                    });
              }))),
    );
  }

  int _getLevelNumber(List<Lesson>? lessons, index) {
    if (lessons == null) {
      return -1;
    }

    int currentLevel = 1;
    for (int i = 0; i < min(index, lessons.length); i++) {
      if (lessons[i].isLevel) {
        currentLevel++;
      }
    }

    return currentLevel;
  }
}
