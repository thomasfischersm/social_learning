import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class CmsHomePage extends StatefulWidget {
  const CmsHomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CmsHomePageState();
  }
}

class CmsHomePageState extends State<CmsHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Learning'),
      ),
      bottomNavigationBar: const BottomBar(),
      body: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 310, maxHeight: 350),
              child: Consumer<LibraryState>(
                  builder: (context, libraryState, child) {
                return Column(
                  children: [
                    Text('Content Management',
                        style: Theme.of(context).textTheme.headline5),
                    Expanded(
                        child: ListView.builder(
                            itemCount: libraryState.lessons?.length ?? 0,
                            // shrinkWrap: true,
                            itemBuilder: (context, index) {
                              var lesson = libraryState.lessons?[index];
                              return (lesson != null)
                                  ? EditLessonRow(lesson)
                                  // ? Text(lesson.title)
                                  : const ListTile();
                            })),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, NavigationEnum.cmsLesson.route);
                        },
                        child: const Text('Create new lesson')),
                  ],
                );
              }))),
    );
  }
}

class EditLessonRow extends StatefulWidget {
  final Lesson lesson;

  const EditLessonRow(this.lesson, {super.key});

  @override
  State<StatefulWidget> createState() {
    return EditLessonRowState();
  }
}

class EditLessonRowState extends State<EditLessonRow> {
  late TextEditingController textEditingController;
  int? oldSortOrder;

  @override
  void initState() {
    super.initState();

    textEditingController =
        TextEditingController(text: '${widget.lesson.sortOrder}');
  }

  @override
  Widget build(BuildContext context) {
    if (oldSortOrder != widget.lesson.sortOrder) {
      oldSortOrder = widget.lesson.sortOrder;
      textEditingController.text = oldSortOrder.toString();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
            flex: 1,
            child: TextField(
              controller: textEditingController,
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                int? newSortOrder = int.tryParse(value);
                if (newSortOrder != null) {
                  var libraryState =
                      Provider.of<LibraryState>(context, listen: false);
                  libraryState.updateSortOrder(widget.lesson, newSortOrder);
                } else {
                  textEditingController.text =
                      widget.lesson.sortOrder.toString();
                }
              },
            )),
        Expanded(
            flex: 5,
            child: Align(alignment: Alignment.centerLeft,child: TextButton(
              child: Text(widget.lesson.title,
                  overflow: TextOverflow.ellipsis,
                  style: (widget.lesson.isLevel)
                      ? Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontWeight: FontWeight.bold)
                      : Theme.of(context).textTheme.bodyText1),
              onPressed: () {
                Navigator.pushNamed(context, NavigationEnum.cmsLesson.route,
                    arguments: LessonDetailArgument(widget.lesson.id));
              },
            ))),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            _showDeleteConfirmationDialog(context, widget.lesson);
          },
        )
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Lesson lesson) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm to delete'),
            content: Text(
                'Are you sure that you want to delete the lesson ${lesson.title}?'),
            actions: [
              TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              TextButton(
                child: const Text('Delete'),
                onPressed: () {
                  var libraryState =
                      Provider.of<LibraryState>(context, listen: false);
                  libraryState.deleteLesson(lesson);

                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }
}
