import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';

import 'navigation_enum.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text('Social Learning'),
      ),
      bottomNavigationBar: BottomBar(),
      body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              child: Column(
                children: [
                  Text(
                    'How it works',
                    style: Theme.of(context).textTheme.headline3,
                  ),
                  Text(
                    '1. Show up.\n'
                    '2. Find a more advanced partner. Learn a lesson.\n'
                    '3. Find a more beginning partner. Teach a lesson.',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  const Spacer(),
                  const Divider(),
                  Text(
                    'Pick a course',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  Consumer<LibraryState>(
                    builder: (context, libraryState, child) {
                      return DropdownButton<Course>(
                          icon: const Icon(Icons.arrow_downward),
                          value: libraryState.selectedCourse,
                          items: libraryState.availableCourses
                              .map<DropdownMenuItem<Course>>((Course value) {
                            return DropdownMenuItem<Course>(
                                value: value, child: Text(value.title));
                          }).toList(),
                          onChanged: (Course? value) {
                            libraryState.selectedCourse = value;
                          });
                    },
                  ),
                  Consumer<LibraryState>(
                    builder: (context, libraryState, child) {
                      if (libraryState.isCourseSelected) {
                        return TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, NavigationEnum.lesson_list.route),
                          child: const Text('View Lessons'),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                  const Text('(C) 2023 Thomas Fischer')
                ],
              ))),
    );
  }
}
