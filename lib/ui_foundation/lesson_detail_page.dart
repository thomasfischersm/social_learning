import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/data_helpers/lesson_comment_functions.dart';
import 'package:social_learning/data/data_helpers/progress_video_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_detail/record_disabled_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_detail/record_practice_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/nearby_mentors_list_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/youtube_video_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/util/string_util.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonDetailArgument {
  String lessonId;

  LessonDetailArgument(this.lessonId);

  static goToLessonDetailPage(BuildContext context, String lessonId) {
    Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
        arguments: LessonDetailArgument(lessonId));
  }
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
  String? _youtubeUploadError;
  List<bool> _isSectionExpanded = [];

  @override
  void initState() {
    print('LessonDetailState.initState');
    super.initState();

    Future.microtask(() {
      setState(() {
        print('LessonDetailState.initState Future.microtask');
        Lesson? lesson = _getLesson(null, context);
        if (lesson != null) {
          setState(() {
            int sectionCount = _countInstructionSections(lesson);
            print(
                'LessonDetailState.initState Future.microtask setState $sectionCount');
            _isSectionExpanded = List.filled(max(1, sectionCount), false);
            _isSectionExpanded[0] = true;
            print('Size of _isSectionExpanded: ${_isSectionExpanded.length}');
          });
        }
      });
    });
  }

  Lesson? _getLesson(LibraryState? libraryState, BuildContext context) {
    libraryState ??= Provider.of<LibraryState>(context, listen: false);

    LessonDetailArgument? argument =
        ModalRoute.of(context)?.settings.arguments as LessonDetailArgument?;

    if (argument != null) {
      String lessonId = argument.lessonId;
      return libraryState.findLesson(lessonId);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ApplicationState, StudentState, LibraryState>(builder:
        (context, applicationState, studentState, libraryState, child) {
      Lesson? lesson = _getLesson(libraryState, context);
      int? levelPosition = _findLevelPosition(lesson, libraryState);

      if (lesson != null) {
        var counts = studentState.getCountsForLesson(lesson);

        return Scaffold(
            appBar: LearningLabAppBar(title: 'Lesson: ${lesson.title}'),
            bottomNavigationBar: BottomBarV2.build(context),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showDialog(context, lesson, counts, applicationState);
                });
              },
              child: const Text('Record'),
            ),
            body: Align(
                alignment: Alignment.topCenter,
                child: CustomUiConstants.framePage(
                    enableScrolling: false,
                    DefaultTabController(
                      length: 4, // Number of tabs
                      child: NestedScrollView(
                        headerSliverBuilder:
                            (BuildContext context, bool innerBoxIsScrolled) {
                          return <Widget>[
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _generateInstructionText(
                                            lesson, context)
                                      ],
                                    ),
                                  ),
                                  /*),*/
                                  _createCommentsView(
                                      lesson, context, applicationState),
                                  SingleChildScrollView(
                                    child: Column(
                                      children: <Widget>[
                                        _createShowcaseView(context, lesson,
                                            applicationState, libraryState),
                                      ],
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    child: Column(
                                      children: <Widget>[
                                        _createConnectView(context, lesson,
                                            applicationState, libraryState),
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

      return Scaffold(
          appBar: const LearningLabAppBar(title: 'Nothing loaded'),
          bottomNavigationBar: BottomBarV2.build(context),
          body: const SizedBox.shrink());
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
    List<InlineSpan> textSpans = [];

    List<String> instructions = _buildInstructionLines(lesson);

    int sectionIndex = -1;
    bool isExpanded =
        _isSectionExpanded.isNotEmpty ? _isSectionExpanded[0] : true;
    for (String str in instructions) {
      str = str.trim();
      final int savedIndex = sectionIndex;

      if (str.endsWith('---')) {
        sectionIndex++;
        isExpanded = _isSectionExpanded.length > sectionIndex
            ? _isSectionExpanded[sectionIndex]
            : false;
        final int savedIndex = sectionIndex;
        print(
            'Size of _isSectionExpanded: ${_isSectionExpanded.length} and sectionIndex: $sectionIndex and savedIndex: $savedIndex and isExpanded: $isExpanded');

        str = str.substring(0, str.length - 3);
        textSpans
          ..add(WidgetSpan(
              child: GestureDetector(
                  onTap: () => _toggleSectionExpanded(savedIndex),
                  child: Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right))))
          ..add(TextSpan(
              text: '$str\n',
              style: CustomTextStyles.subHeadline,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _toggleSectionExpanded(savedIndex)));
      } else {
        if (isExpanded) {
          textSpans.add(_generateTextSpanWithLinks(str));
        }
      }
    }

    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SelectableText.rich(TextSpan(children: textSpans)));
  }

  int _countInstructionSections(Lesson lesson) {
    List<String> instructions = _buildInstructionLines(lesson);
    int sectionCount = 0;
    for (String line in instructions) {
      if (line.trim().endsWith('---')) {
        sectionCount++;
      }
    }
    return sectionCount;
  }

  List<String> _buildInstructionLines(Lesson lesson) {
    List<String> instructions =
        lesson.instructions.replaceAll('\r', '').split('\n');
    if (instructions.isEmpty ||
        !instructions[0].toLowerCase().startsWith('instructions---')) {
      instructions.insert(0, 'Instructions---');
    }

    instructions.add('Graduation requirements---');
    List<String> graduationRequirements =
        lesson.graduationRequirements ?? <String>[];
    List<String> cleanedRequirements = graduationRequirements
        .map((requirement) => requirement.trim())
        .where((requirement) => requirement.isNotEmpty)
        .toList();

    if (cleanedRequirements.isEmpty) {
      instructions.add('None');
    } else {
      for (String requirement in cleanedRequirements) {
        instructions.add('• $requirement');
      }
    }

    return instructions;
  }

  TextSpan _generateTextSpanWithLinks(String paragraph) {
    paragraph += '\n';
    final List<InlineSpan> spans = [];
    final RegExp urlRegExp = RegExp(r'(https?:\/\/\S+)');

    int start = 0;
    for (final Match match in urlRegExp.allMatches(paragraph)) {
      if (match.start > start) {
        spans.add(TextSpan(
            text: paragraph.substring(start, match.start),
            style: CustomTextStyles.getBody(context)));
      }

      final String url = match.group(0)!;
      spans.add(TextSpan(
          text: url,
          style: CustomTextStyles.getLink(context),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri? uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri);
              }
            }));
      start = match.end;
    }

    if (start < paragraph.length) {
      spans.add(TextSpan(
        text: paragraph.substring(start),
        style: CustomTextStyles.getBody(context),
      ));
    }

    return TextSpan(children: spans);
  }

  void _toggleSectionExpanded(int sectionIndex) {
    print('Toggling section $sectionIndex');
    setState(() {
      if (_isSectionExpanded.length > sectionIndex) {
        if (_isSectionExpanded[sectionIndex]) {
          _isSectionExpanded[sectionIndex] = false;
        } else {
          for (int i = 0; i < _isSectionExpanded.length; i++) {
            _isSectionExpanded[i] = (i == sectionIndex);
          }
        }
      } else {
        print('Section index $sectionIndex out of bounds');
      }
    });
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
      RecordPracticeDialog.showRecordDialog(context, lesson);
    } else {
      RecordDisabledDialog.showDisabledDialog(context);
    }
  }

  Widget _createCommentsView(
      Lesson lesson, BuildContext context, ApplicationState applicationState) {
    DocumentReference lessonId = docRef('lessons', lesson.id!);
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
                  bool isSelf =
                      (commenter?.id == applicationState.currentUser?.id);

                  commentWidgets.add(Container(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(children: [
                        if (commenter != null)
                          SizedBox(
                              width: 50,
                              height: 50,
                              child: ProfileImageWidgetV2.fromUser(
                                commenter,
                                linkToOtherProfile: true,
                              )),
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
                              text: formatCommentTimestamp(
                                  comment.createdAt?.toLocal()),
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ])),
                        )),
                        if (isSelf)
                          IconButton(
                              onPressed: () {
                                deleteComment(context, comment);
                              },
                              icon: Icon(Icons.close, color: Colors.grey)),
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
          onSubmitted: (_) => _sendComment(lesson, applicationState),
          controller: _commentController,
          decoration: const InputDecoration(
              hintText: 'Leave a comment...',
              contentPadding: EdgeInsets.all(8.0)),
        )),
        IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendComment(lesson, applicationState))
      ],
    );

    return Column(children: [
      Expanded(child: SingleChildScrollView(child: commentColumn)),
      sendRow
    ]);
  }

  void _sendComment(Lesson lesson, ApplicationState applicationState) {
    // Send the comment
    print('send clicked');
    if (_commentController.text.isNotEmpty) {
      String comment = _commentController.text;
      _commentController.clear();

      print('attempting to create comment');
      LessonCommentFunctions.addLessonComment(
          lesson, comment, applicationState.currentUser!);
    }
  }

  static String formatCommentTimestamp(DateTime? date) {
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

  Widget _createShowcaseView(BuildContext context, Lesson lesson,
      ApplicationState applicationState, LibraryState libraryState) {
    return Column(
      children: [
        ..._createShowcaseUploadView(lesson, applicationState),
        _createMyShowcaseView(lesson, applicationState),
        _createShowcaseFeed(lesson, libraryState),
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
          style: CustomTextStyles.getBodyNote(context),
          // Base style for the text
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
      if (_youtubeUploadError != null)
        Text(_youtubeUploadError!,
            style:
                CustomTextStyles.getBody(context)?.copyWith(color: Colors.red))
    ];
  }

  Widget _createMyShowcaseView(
      Lesson lesson, ApplicationState applicationState) {
    var currentUser = applicationState.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return ProgressVideoFunctions.createMyProgressVideosForLessonStream(
        lesson.id!, currentUser, (context, progressVideos) {
      if (progressVideos.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(children: [
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'My Progress',
              style: CustomTextStyles.subHeadline,
            )),
        LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
              width: constraints.maxWidth,
              child: Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.start,
                  runSpacing: 10,
                  children: progressVideos.map((progressVideo) {
                    final String? timeDiff;
                    if (progressVideo.timestamp != null) {
                      timeDiff = DateTime.now()
                          .difference(progressVideo.timestamp!.toDate())
                          .inDays
                          .toString();
                    } else {
                      timeDiff = null;
                    }

                    return SizedBox(
                        width: (constraints.maxWidth ~/ 3 - 20).toDouble(),
                        child: Column(
                          children: [
                            if (progressVideo.youtubeVideoId != null)
                              YouTubeVideoWidget(
                                  videoId: progressVideo.youtubeVideoId!),
                            if (timeDiff != null)
                              Align(
                                  alignment: Alignment.center,
                                  child: Text('$timeDiff days ago')),
                          ],
                        ));
                  }).toList()));
        })
      ]);
    });
  }

  Widget _createShowcaseFeed(Lesson lesson, LibraryState libraryState) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Student Progress',
            style: CustomTextStyles.subHeadline,
          )),
      ProgressVideoFunctions.createProgressVideosForLessonStream(lesson.id!,
          (context, progressVideos) {
        if (progressVideos.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(children: [
          ...progressVideos.map((progressVideo) => Column(children: [
                YouTubeVideoWidget(videoId: progressVideo.youtubeVideoId!),
                Row(children: [
                  Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 6,
                        right: 4,
                      ),
                      child: SizedBox(
                          width: 50,
                          height: 50,
                          child: ProfileImageWidgetV2.fromUserId(
                              progressVideo.userId,
                              linkToOtherProfile: true))),
                  Text(
                      DateFormat.yMd().format(
                          progressVideo.timestamp?.toDate() ?? DateTime.now()),
                      style: CustomTextStyles.getBody(context))
                ]),
              ]))
        ]);
      })
    ]);
  }

  _submitYoutubeUrl(
      BuildContext context, Lesson lesson, ApplicationState applicationState) {
    var youtubeUrl = _youtubeUploadUrlController.text;
    if (youtubeUrl.trim().isEmpty) {
      _youtubeUploadError = 'Please enter a URL.';
    }

    if (!ProgressVideoFunctions.isValidYouTubeUrl(youtubeUrl)) {
      _youtubeUploadError = 'Invalid Youtube URL.';
    }

    ProgressVideoFunctions.createProgressVideo(
        lesson, applicationState.currentUser!, youtubeUrl);
    setState(() {
      _youtubeUploadError = null;
      _youtubeUploadUrlController.text = '';
    });
  }

  _createConnectView(BuildContext context, Lesson lesson,
      ApplicationState applicationState, LibraryState libraryState) {
    DocumentReference lessonId = docRef('lessons', lesson.id!);
    User? currentUser = applicationState.currentUser;
    GeoPoint? currentLocation = currentUser?.location;

    if (currentUser == null) {
      return const Text('Please sign in to connect with other students.');
    }

    if (!currentUser.isGeoLocationEnabled || currentLocation == null) {
      return Center(
          child: Column(children: [
        InkWell(
            onTap: () => _enableLocation(applicationState),
            child: const Text(
                'Please enable location services to connect with other students.')),
        TextButton(
            onPressed: () => _enableLocation(applicationState),
            child: const Text('Enable location'))
      ]));
    }

    return SingleChildScrollView(
        child: Column(
      children: [
        Text('Find students who can teach you this lesson',
            style: CustomTextStyles.subHeadline),
        NearbyMentorsListWidget(
            lessonId: lessonId, currentLocation: currentLocation),
      ],
    ));
  }

  void _enableLocation(ApplicationState applicationState) {
    UserFunctions.enableGeoLocation(applicationState);
    setState(() {});
  }

  static void deleteComment(BuildContext context, LessonComment comment) {
    // Show a dialog to confirm
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete comment'),
            content:
                const Text('Are you sure you want to delete this comment?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    LessonCommentFunctions.deleteLessonComment(comment);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete'))
            ],
          );
        });
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
