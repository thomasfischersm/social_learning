import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/progress_video_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/youtube_video_widget.dart';
import 'package:social_learning/util/string_util.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonDetailArgument {
  String lessonId;

  LessonDetailArgument(this.lessonId);
}

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LessonDetailState();
  }
}

class LessonDetailState extends State<LessonDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _youtubeUploadUrlController =
      TextEditingController();
  String? _youtubeUploadEror = null;

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
        builder: (context, applicationState, child) {
      return Consumer<StudentState>(builder: (context, studentState, child) {
        return Consumer<LibraryState>(builder: (context, libraryState, child) {
          LessonDetailArgument? argument = ModalRoute.of(context)!
              .settings
              .arguments as LessonDetailArgument?;
          if (argument != null) {
            String lessonId = argument.lessonId;
            Lesson? lesson = libraryState.findLesson(lessonId);
            int? levelPosition = _findLevelPosition(lesson, libraryState);

            if (lesson != null) {
              var counts = studentState.getCountsForLesson(lesson);

              return Scaffold(
                  appBar: AppBar(title: Text('Lesson: ${lesson.title}')),
                  bottomNavigationBar: const BottomBar(),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showDialog(context, lesson, counts, applicationState);
                      });
                    },
                    child: const Text('Record'),
                  ),
                  body: Center(
                      child: CustomUiConstants.framePage(
                          enableScrolling: false,
                          DefaultTabController(
                            length: 4, // Number of tabs
                            child: NestedScrollView(
                              headerSliverBuilder: (BuildContext context,
                                  bool innerBoxIsScrolled) {
                                return <Widget>[
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ..._generateLessonHeader(
                                            lesson,
                                            levelPosition,
                                            counts,
                                            context,
                                            studentState)
                                      ],
                                    ),
                                  ),
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _SliverAppBarDelegate(
                                      const TabBar(
                                        labelColor: Colors.black,
                                        tabs: [
                                          Tab(text: 'Learn'),
                                          Tab(text: 'Discuss'),
                                          Tab(text: 'Showcase'),
                                          Tab(text: 'Connect')
                                        ],
                                      ),
                                    ),
                                  ),
                                ];
                              },
                              body: Column(
                                children: [
                                  Expanded(
                                    child: TabBarView(
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          child: /*IntrinsicHeight(child:*/
                                              Column(
                                            children: <Widget>[
                                              _generateInstructionText(
                                                  lesson, context)
                                            ],
                                          ),
                                        ),
                                        /*),*/
                                        _createCommentsView(
                                            lesson, context, libraryState),
                                        SingleChildScrollView(
                                          child: Column(
                                            children: <Widget>[
                                              _createShowcaseView(context,
                                                  lesson, applicationState),
                                            ],
                                          ),
                                        ),
                                        SingleChildScrollView(
                                          child: Column(
                                            children: <Widget>[
                                              Text("Content for Tab 4"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CustomUiConstants.getGeneralFooter(context),
                                ],
                              ),
                            ),
                          ))));
            }
          }

          return Scaffold(
              appBar: AppBar(title: const Text('Nothing loaded')),
              bottomNavigationBar: const BottomBar(),
              body: const SizedBox.shrink());
        });
      });
    });
  }

  int? _findLevelPosition(Lesson? lesson, LibraryState libraryState) {
    var levelId = lesson?.levelId;
    Level? level =
        (levelId != null) ? libraryState.findLevelByDocRef(levelId) : null;
    int? levelPosition =
        (level != null) ? libraryState.findLevelPosition(level) : null;
    return levelPosition;
  }

  Iterable<Widget> _generateLessonHeader(Lesson lesson, int? levelPosition,
      LessonCount counts, BuildContext context, StudentState studentState) {
    return [
      if (lesson.coverFireStoragePath != null)
        /* Expanded(
                            child:*/
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LessonCoverImageWidget(lesson.coverFireStoragePath)),
      if (levelPosition != null)
        Text('Level ${levelPosition + 1}',
            style: CustomTextStyles.getBody(context))
      else
        Text('Flex Lessons', style: CustomTextStyles.getBody(context)),
      Text('Lesson: ${lesson.title}', style: CustomTextStyles.subHeadline),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.synopsis ?? '',
                    style: CustomTextStyles.getBody(context)),
                Text(
                  _generateLessonStatus(studentState, counts),
                  style: CustomTextStyles.getBody(context),
                ),
              ],
            )),
            if (StringUtil.isNotEmpty(lesson.recapVideo))
              _addVideoIcon(lesson.recapVideo!, 'Recap', context),
            if (StringUtil.isNotEmpty(lesson.lessonVideo))
              _addVideoIcon(lesson.lessonVideo!, 'Lesson', context),
            if (StringUtil.isNotEmpty(lesson.practiceVideo))
              _addVideoIcon(lesson.practiceVideo!, 'Practice', context),
          ],
        ),
      ),
      /*CustomUiConstants.getDivider()*/
    ];
  }

  String _generateLessonStatus(StudentState studentState, LessonCount counts) {
    String str = '';

    if (counts.practiceCount > 0) {
      str += 'Practiced: ${counts.practiceCount}';
    }

    if ((counts.practiceCount > 0) && (counts.teachCount > 0)) {
      str += ', ';
    }

    if (counts.teachCount > 0) {
      str += 'Taught: ${counts.teachCount}';
    }

    if (str.isNotEmpty) {
      str = '\n$str';
    }

    return str;
  }

  Widget _generateInstructionText(Lesson lesson, BuildContext context) {
    List<TextSpan> textSpans = [];

    List<String> instructions =
        lesson.instructions.replaceAll('\r', '').split('\n');

    for (String str in instructions) {
      str = str.trim();
      if (str.endsWith('---')) {
        str = str.substring(0, str.length - 3);
        textSpans
            .add(TextSpan(text: '$str\n', style: CustomTextStyles.subHeadline));
      } else {
        textSpans.add(
            TextSpan(text: '$str\n', style: CustomTextStyles.getBody(context)));
      }
    }

    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SelectableText.rich(TextSpan(
            text: 'Instructions\n',
            style: CustomTextStyles.subHeadline,
            children: textSpans)));
  }

  Widget _addVideoIcon(String videoUrl, String label, BuildContext context) {
    return InkWell(
      child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(children: [
            const Icon(
              Icons.ondemand_video,
              size: 36,
            ),
            //Icons.video_library_outlined
            Text(label, style: CustomTextStyles.getBody(context))
          ])),
      onTap: () {
        launchUrl(Uri.parse(videoUrl));
      },
    );
  }

  void _showDialog(BuildContext context, Lesson lesson, LessonCount counts,
      ApplicationState applicationState) {
    if (counts.isGraduated ||
        (applicationState.currentUser?.isAdmin ?? false)) {
      _showRecordDialog(context, lesson);
    } else {
      _showDisabledDialog(context);
    }
  }

  void _showDisabledDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Graduate student"),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text("OK"),
              ),
            ],
            content: const DisabledDialogContent(),
          );
        });
  }

  void _showRecordDialog(BuildContext context, Lesson currentLesson) {
    User? selectedLearner;
    bool isReady = false;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Record Lesson"),
            actions: [
              TextButton(
                  onPressed: () {
                    User? localLearner = selectedLearner;
                    if (localLearner != null) {
                      setState(() {
                        Provider.of<StudentState>(context, listen: false)
                            .recordTeachingWithCheck(
                                currentLesson, localLearner, isReady, context);
                        Navigator.pop(context);
                      });
                    }
                  },
                  child: const Text('Record')),
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
            content: RecordDialogContent(currentLesson,
                (User? student, bool isReadyToGraduate) {
              selectedLearner = student;
              isReady = isReadyToGraduate;
            }),
          );
        });
  }

  Widget _createCommentsView(
      Lesson lesson, BuildContext context, LibraryState libraryState) {
    DocumentReference lessonId =
        FirebaseFirestore.instance.doc('/lessons/${lesson.id}');
    print('Querying for comments for lesson: $lessonId');
    Widget commentColumn = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lessonComments')
            .where('lessonId', isEqualTo: lessonId)
            // .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print(
              'StreamBuilder came back with ${snapshot.connectionState} and ${snapshot.data} and ${snapshot.data?.docs.length}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Text('No comments yet.');
          }

          List<LessonComment> comments = snapshot.data!.docs
              .map((snapshot) => LessonComment.fromQuerySnapshot(snapshot))
              .toList();
          comments.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return -1;
            if (b.createdAt == null) return 1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          var userIds =
              comments.map((comment) => comment.creatorId.id).toSet().toList();
          print('UserIds: $userIds');

          return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: userIds)
                  .get(),
              builder: (context, userSnapshot) {
                print(
                    'FutureBuilder is called with userSnapshot $userSnapshot');
                if (userSnapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<String, User> userMap = userSnapshot.data!.docs
                    .map((e) => User.fromSnapshot(e))
                    .fold({}, (map, user) {
                  map[user.id] = user;
                  return map;
                });

                List<Widget> commentWidgets = [];
                for (LessonComment comment in comments) {
                  User? commenter = userMap[comment.creatorId.id];
                  commentWidgets.add(Container(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(children: [
                        if (commenter != null)
                          SizedBox(
                              width: 50,
                              height: 50,
                              child: ProfileImageWidget(
                                  commenter.profileFireStoragePath)),
                        Expanded(
                            child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0)),
                          child: RichText(
                              text: TextSpan(children: [
                            TextSpan(
                                text: commenter?.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const WidgetSpan(child: SizedBox(width: 8)),
                            TextSpan(text: comment.text),
                            if (comment.createdAt != null)
                              const WidgetSpan(child: SizedBox(width: 16)),
                            TextSpan(
                              text: _formatCommentTimestamp(
                                  comment.createdAt?.toLocal()),
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ])),
                        ))
                      ])));
                }

                return Column(children: commentWidgets);
              });
        });

    // Add row to leave a new comment.
    Row sendRow = Row(
      children: [
        Expanded(
            child: TextField(
          onSubmitted: (_) => _sendComment(lesson, libraryState),
          controller: _commentController,
          decoration: const InputDecoration(
              hintText: 'Leave a comment...',
              contentPadding: EdgeInsets.all(8.0)),
        )),
        IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendComment(lesson, libraryState))
      ],
    );

    return Column(children: [
      Expanded(child: SingleChildScrollView(child: commentColumn)),
      sendRow
    ]);
  }

  void _sendComment(Lesson lesson, LibraryState libraryState) {
    // Send the comment
    print('send clicked');
    if (_commentController.text.isNotEmpty) {
      String comment = _commentController.text;
      _commentController.clear();

      print('attempting to create comment');
      libraryState.addLessonComment(lesson, comment);
    }
  }

  String _formatCommentTimestamp(DateTime? date) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (now.year == date.year) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  Widget _createShowcaseView(
      BuildContext context, Lesson lesson, ApplicationState applicationState) {
    return Column(
      children: [
        ..._createShowcaseUploadView(lesson, applicationState),
        _createMyShowcaseView(lesson),
        _createShowcaseFeed()
      ],
    );
  }

  List<Widget> _createShowcaseUploadView(
      Lesson lesson, ApplicationState applicationState) {
    return [
      Text('Upload a video of today\'s progress.',
          style: CustomTextStyles.subHeadline),
      RichText(
        text: TextSpan(
          style: CustomTextStyles.getBodyNote(context), // Base style for the text
          children: [
            TextSpan(
              text: 'Upload on YouTube',
              style: const TextStyle(
                color: Colors.blue,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  Uri url = Uri.parse('https://www.youtube.com/upload');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url); // Launch the YouTube upload page
                  } else {
                    throw 'Could not launch $url';
                  }
                },
            ),
            const TextSpan(
              text: ' and copy the URL here.',
            ),
          ],
        ),
      ),
      Row(children: [
        Expanded(child: TextField(controller: _youtubeUploadUrlController)),
        TextButton(
            onPressed: () =>
                _submitYoutubeUrl(context, lesson, applicationState),
            child: const Text('Submit'))
      ]),
      if (_youtubeUploadEror != null)
        Text(_youtubeUploadEror!,
            style:
                CustomTextStyles.getBody(context)?.copyWith(color: Colors.red))
    ];
  }

  Widget _createMyShowcaseView(Lesson lesson) {
    return ProgressVideoFunctions.createProgressVideosForLessonStream(
        lesson.id!, (context, progressVideos) {
      if (progressVideos.isEmpty) {
        return SizedBox.shrink();
      }
      return Column(children: [
        Text(
          'My Progress',
          style: CustomTextStyles.subHeadline,
        ),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3),
          itemCount: progressVideos.length,
          itemBuilder: (context, index) {
            var progressVideo = progressVideos[index];
            final String? timeDiff;
            if (progressVideo.timestamp != null) {
              timeDiff = DateTime.now()
                  .difference(progressVideo.timestamp!.toDate())
                  .inDays
                  .toString();
            } else {
              timeDiff = null;
            }

            return Column(
              children: [
                if (progressVideo.youtubeVideoId != null)
                  YouTubeVideoWidget(videoId: progressVideo.youtubeVideoId!),
                if (timeDiff != null)
                  Align(
                      alignment: Alignment.center,
                      child: Text('$timeDiff days ago')),
              ],
            );
          },
        ),
      ]);
    });
  }

  Widget _createShowcaseFeed() {return Text('todo');}

  _submitYoutubeUrl(
      BuildContext context, Lesson lesson, ApplicationState applicationState) {
    var youtubeUrl = _youtubeUploadUrlController.text;
    if (youtubeUrl.trim().isEmpty) {
      _youtubeUploadEror = 'Please enter a URL.';
    }

    if (!ProgressVideoFunctions.isValidYouTubeUrl(youtubeUrl)) {
      _youtubeUploadEror = 'Invalid Youtube URL.';
    }

    ProgressVideoFunctions.createProgressVideo(
        lesson.id!, applicationState.currentUser!, youtubeUrl);
    setState(() {
      _youtubeUploadEror = null;
      _youtubeUploadUrlController.text = '';
    });
  }
}

class DisabledDialogContent extends StatefulWidget {
  const DisabledDialogContent({super.key});

  @override
  State<StatefulWidget> createState() {
    return DisabledDialogState();
  }
}

class DisabledDialogState extends State<DisabledDialogContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Once you\'ve mastered this lesson, you will be able to record '
            'that you taught someone here.\n\n'
            'For now, find an instructor or '
            'student to practice this lesson with. They will be able to record '
            'it for you.\n',
            style: CustomTextStyles.getBodyEmphasized(context)),
        Text(
            'Note: There is a difference between having done something once '
            'and being actually proficient at it. Take riding a bicycle '
            'for example. Once you\'ve been able to push off for a couple '
            'yards, you\'ve been riding your bicycle but you are not '
            'proficient yet. Similarly, having done this lesson once is '
            'not the same as having fully learned it.\n\n'
            'Having to graduate a lesson may feel like being held back when '
            'one wants to storm forward. However, a solid foundation is going '
            'to serve you better in the long run. Plus, it\'ll ensure '
            'quality for students learning from other students.\n'
            'However, being held back from graduating shouldn\'t be an '
            'eternal "not yet." Your instructor or mentoring student '
            'should give you specific feedback on what you need to do to '
            'master it.',
            style: CustomTextStyles.getBodyNote(context)),
      ],
    );
  }
}

class RecordDialogContent extends StatefulWidget {
  Lesson lesson;
  Function onUserSelected;

  RecordDialogContent(this.lesson, this.onUserSelected, {super.key});

  @override
  State<StatefulWidget> createState() {
    return RecordDialogState(lesson);
  }
}

class RecordDialogState extends State<RecordDialogContent> {
  Lesson lesson;
  List<User>? _students;
  bool _isReadyToGraduate = false;
  List<bool> _graduationRequirements = [];
  TextEditingController textFieldController = TextEditingController();

  RecordDialogState(this.lesson) {
    if (lesson.graduationRequirements != null) {
      _graduationRequirements =
          List.filled(lesson.graduationRequirements!.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_students?.length == 1) {
      widget.onUserSelected(
          _students![0], _isReadyToGraduate && _checkGraduationRequirements());
    } else {
      widget.onUserSelected(
          null, _isReadyToGraduate && _checkGraduationRequirements());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomUiConstants.getTextPadding(Text(
            'Records that you taught a lesson.',
            style: CustomTextStyles.getBody(context))),
        Table(columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth()
        }, children: [
          TableRow(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child:
                    Text('Mentor:', style: CustomTextStyles.getBody(context))),
            const Padding(padding: EdgeInsets.all(4), child: Text('You')),
          ]),
          TableRow(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child:
                    Text('Learner:', style: CustomTextStyles.getBody(context))),
            Padding(
                padding: const EdgeInsets.all(4),
                child: Column(children: [
                  TextField(
                    style: CustomTextStyles.getBody(context),
                    onChanged: (value) async {
                      var students =
                          await UserFunctions.findUsersByPartialDisplayName(
                              value, 10);
                      setState(() {
                        _students = students;
                      });
                    },
                    controller: textFieldController,
                    decoration: const InputDecoration(
                        hintText: 'Start typing the name.'),
                  ),
                  SizedBox(
                      width: 200,
                      height: 200,
                      child: ListView.builder(
                        itemCount: _students?.length ?? 0,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var profileFireStoragePath =
                              _students![index].profileFireStoragePath;
                          return InkWell(
                              onTap: () {
                                setState(() {
                                  _students = [_students![index]];
                                });
                              },
                              child: Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 2, top: 2),
                                  child: Row(
                                    children: [
                                      if (profileFireStoragePath != null)
                                        Expanded(
                                            flex: 1,
                                            child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: AspectRatio(
                                                    aspectRatio: 1,
                                                    child: ProfileImageWidget(
                                                        _students![index]
                                                            .profileFireStoragePath)))),
                                      Expanded(
                                          flex: 3,
                                          child: Text(
                                              _students![index].displayName,
                                              style: CustomTextStyles.getBody(
                                                  context))),
                                    ],
                                  )));
                        },
                      ))
                ])),
          ]),
        ]),
        Column(
          children: _generateGraduationRequirementsChecks(),
        ),
        Row(
          children: [
            Checkbox(
              value: _isReadyToGraduate,
              onChanged: (value) {
                setState(() {
                  _isReadyToGraduate = value ?? false;
                });
              },
            ),
            Flexible(
                child: Text('The learner is ready to teach this lesson.',
                    style: CustomTextStyles.getBodyEmphasized(context))),
          ],
        )
      ],
    );
  }

  List<Row> _generateGraduationRequirementsChecks() {
    List<Row> rows = [];
    var graduationRequirements = lesson.graduationRequirements;
    if (graduationRequirements == null) {
      return rows;
    }

    for (String requirement in graduationRequirements) {
      var index = rows.length;
      rows.add(Row(
        children: [
          Checkbox(
              value: index < _graduationRequirements.length
                  ? _graduationRequirements[index]
                  : false,
              onChanged: (value) {
                setState(() {
                  _graduationRequirements[index] = value ?? false;
                });
              }),
          Flexible(
              child:
                  Text(requirement, style: CustomTextStyles.getBody(context)))
        ],
      ));
    }
    return rows;
  }

  bool _checkGraduationRequirements() {
    for (bool requirement in _graduationRequirements) {
      if (!requirement) {
        return false;
      }
    }
    return true;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

/*

        /*IntrinsicHeight(
                          child: */DefaultTabController(
        length: 4,
        child:NestedScrollView(headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text("Lesson Page"),
              pinned: true,
              floating: true,
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Learn'),
                  Tab(text: 'Discuss'),
                  Tab(text: 'Showcase'),
                  Tab(text: 'Connect'),
                ],
              ),
            ),
          ];
        }, body: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._generateLessonHeader(
                lesson, levelPosition, counts, context, studentState),
            /*DefaultTabController(
                          length: 4,
                          child: Column(
                            children: [
                              const TabBar(tabs: [
                                Tab(text: 'Learn'),
                                Tab(text: 'Discuss'),
                                Tab(text: 'Showcase'),
                                Tab(text: 'Connect')
                              ]),*/
            TabBarView(
              children: [
                /*_generateInstructionText(lesson, context)*/Text('dsfdsf'),
                Text('Placeholder 2'),
                Text('Placeholder 3'),
                Text('Placeholder 4')
              ],
            ),
            // )),
            CustomUiConstants.getGeneralFooter(context),
          ],
        ))))));
  }
}*/
