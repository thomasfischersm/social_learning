import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';

class CmsDetailPage extends StatefulWidget {
  const CmsDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CmsDetailPageState();
  }
}

class CmsDetailPageState extends State<CmsDetailPage> {
  String? _lessonId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLevel = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();


  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      _isInitialized = true;

      LessonDetailArgument? argument =
      ModalRoute
          .of(context)!
          .settings
          .arguments as LessonDetailArgument?;
      if (argument != null) {
        String lessonId = argument.lessonId;
        var libraryState = Provider.of<LibraryState>(context, listen: false);
        Lesson? selectedLesson = libraryState.findLesson(lessonId);
        if (selectedLesson != null) {
          _lessonId = _lessonId;
          _titleController.text = selectedLesson.title;
          _instructionsController.text = selectedLesson.instructions;
        }
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Social Learning'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Center(
            child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 310, maxHeight: 350),
                child: Consumer<LibraryState>(
                    builder: (context, libraryState, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _titleController,
                          )),
                      const Spacer(),
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Expanded(
                          flex: 5,
                          child: TextField(
                            maxLines: null,
                            controller: _instructionsController,
                          )),
                      Row(
                        children: [
                          Text(
                            'Is Level?',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Checkbox(
                            value: _isLevel,
                            onChanged: (value) {
                              setState(() {
                                _isLevel = value ?? false;
                              });
                            },
                          )
                        ],
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () {
                                var libraryState = Provider.of<LibraryState>(
                                    context,
                                    listen: false);

                                if (_lessonId == null) {
                                  libraryState.createLessonLegacy(
                                      libraryState.selectedCourse!.id!,
                                      _titleController.text,
                                      _instructionsController.text,
                                      _isLevel);
                                } else {
                                  libraryState.updateLessonLegacy(
                                      _lessonId!,
                                      _titleController.text,
                                      _instructionsController.text,
                                      _isLevel);
                                }

                                Navigator.pop(context);
                              },
                              child: const Text('Save'))
                        ],
                      ),
                    ],
                  );
                }))));
  }
}
