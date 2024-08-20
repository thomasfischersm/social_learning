import 'dart:math';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/docs/v1.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data_support/google_doc_export.dart';
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
                        style: Theme.of(context).textTheme.headlineSmall),
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
                    TextButton(
                        child: const Text('Test Google docs'),
                        onPressed: () {
                          _testGoogleDocs();
                        }),
                    TextButton(
                      child: const Text('Export to Google docs'),
                      onPressed: () {
                        GoogleDocExport.export();
                      },
                    ),
                  ],
                );
              }))),
    );
  }

  void _testGoogleDocs() async {
    var googleSignIn = GoogleSignIn(
        clientId:
            '518330283384-41akqio9j5lhuqp5pb4e0jp29qo30ttp.apps.googleusercontent.com',
        scopes: <String>[
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/documents.readonly'
        ]);
    print('Start Google sign in');
    var account = await googleSignIn.signIn();
    print('finished Google sign in: ${account?.displayName}');

    if (account == null) {
      print('failed to login');
      return;
    }

    final authHeaders = account.authHeaders;
    var authClient = await googleSignIn.authenticatedClient();

    var docsApi = DocsApi(authClient!);
    var createDoc =
        await docsApi.documents.create(Document(title: 'Test from app'));
    print('finished creating doc');

    var readDoc = await docsApi.documents
        .get('1z4osfIJKwevtErY8G3girYhe25Qvbn77DEU4sRXwDbw');
    var json = readDoc.body!.toJson();
    print('json from doc is $json');

    // Reading document.
    for (StructuralElement structuralElement in readDoc.body!.content!) {
      print(
          '- Structural element\'s paragraph: ${structuralElement.paragraph}');

      if (structuralElement.paragraph != null) {
        for (ParagraphElement paragraphElement
            in structuralElement.paragraph!.elements!) {
          print('-- ${paragraphElement.textRun!.content}');
        }
      }
    }

    var now = DateTime.now();
    var index = createDoc.body!.content![0].endIndex;
    print('create doc endIndex is $index');
    await docsApi.documents.batchUpdate(
        BatchUpdateDocumentRequest(requests: [
          Request(
              insertText: InsertTextRequest(
                  location: Location(index: index),
                  text: 'The current time is ${now.hour} : ${now.minute}.'))
        ], writeControl: WriteControl(targetRevisionId: createDoc.revisionId)),
        createDoc.documentId!);
    print('wrote timestamp to the Google doc');

    _testUpdateGoogleDoc(docsApi);
  }
}

void _testUpdateGoogleDoc(DocsApi docsApi) async {
  print('Reading magic doc...');
  var magicDoc = await docsApi.documents
      .get('1Ox6pnbfx08knYUSZqgbPT9jJpF52vQa1QOCkprHjZno');
  print('...Read magic doc');

  var updateRequests = <Request>[];

  var body = magicDoc.body;
  var deltaIndex = 0;
  if (body != null) {
    var bodyContent = body.content;
    if (bodyContent != null) {
      for (StructuralElement structuralElement in bodyContent) {
        var paragraph = structuralElement.paragraph;
        if (paragraph != null) {
          print('- Paragraph:');
          var paragraphElements = paragraph.elements;
          if (paragraphElements != null) {
            for (ParagraphElement paragraphElement in paragraphElements) {
              print(
                  '-- element ${paragraphElement.startIndex}-${paragraphElement.endIndex}: ${paragraphElement.textRun!.content}');

              var content = paragraphElement.textRun?.content;
              if (content != null) {
                var regExp = RegExp('(\\d+)\\+(\\d+)=(\\d+)?');
                var match = regExp.firstMatch(content);

                if (match != null) {
                  print(
                      '--- matched regex ${match.group(1)} ${match.group(2)}');
                  var a = int.tryParse(match.group(1) ?? '');
                  var b = int.tryParse(match.group(2) ?? '');

                  if ((a != null) && (b != null)) {
                    print(
                        '--- matched two numbers and ${match.groupCount} groups');
                    var sum = a + b;

                    var updateStartIndex = (paragraphElement.startIndex ?? 0) +
                        match.group(1)!.length +
                        match.group(2)!.length +
                        2;
                    updateStartIndex =
                        min(updateStartIndex, paragraphElement.endIndex! - 1);

                    if ((match.group(3) != null) &&
                        match.group(3)!.isNotEmpty) {
                      // Delete the old sum.
                      var deleteEndIndex =
                          updateStartIndex + match.group(3)!.length;
                      print(
                          "delete text: startIndex: ${paragraphElement.startIndex}, endIndex: ${paragraphElement.endIndex}, updateIndex: $updateStartIndex, deleteEndIndex: $deleteEndIndex");
                      updateRequests.add(Request(
                          deleteContentRange: DeleteContentRangeRequest(
                              range: Range(
                                  startIndex: updateStartIndex - deltaIndex,
                                  endIndex: deleteEndIndex - deltaIndex))));
                      // deltaIndex += deleteEndIndex - updateStartIndex;
                    }

                    // Add the new sum.
                    print(
                        'insert text: updateStartIndex: $updateStartIndex, paragraphElement.endIndex: ${paragraphElement.endIndex}');
                    updateRequests.add(Request(
                        insertText: InsertTextRequest(
                            location: Location(
                                index: (updateStartIndex + 0) - deltaIndex),
                            text: '$sum')));
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  if (updateRequests.isNotEmpty) {
    await docsApi.documents.batchUpdate(
        BatchUpdateDocumentRequest(
            requests: updateRequests,
            writeControl: WriteControl(targetRevisionId: magicDoc.revisionId)),
        magicDoc.documentId!);
    print('wrote sums to the Google magicDoc');
  } else {
    print('no updates to make!');
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
            child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  child: Text(widget.lesson.title,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.lesson.isLevel == true)
                          ? Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : Theme.of(context).textTheme.bodyLarge),
                  onPressed: () {
                    Navigator.pushNamed(context, NavigationEnum.cmsLesson.route,
                        arguments: LessonDetailArgument(widget.lesson.id!));
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
