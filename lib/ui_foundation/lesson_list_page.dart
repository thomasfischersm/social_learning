import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';

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
                      return Text(
                          libraryState.lessons?[index].title ?? 'error');
                    });
              }))),
    );
  }
}
