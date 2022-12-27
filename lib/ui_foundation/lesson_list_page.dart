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
      bottomNavigationBar: BottomBar(),
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
                        if (lesson != null) {
                          Navigator.pushNamed(
                              context, NavigationEnum.lesson_detail.route,
                              arguments: LessonDetailArgument(lesson.id));
                        }
                      }, child: Consumer<GraduationState>(
                          builder: (context, graduationState, child) {
                        return Text(
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
}
