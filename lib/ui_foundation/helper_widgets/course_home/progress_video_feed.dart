import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/progress_video_functions.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_by_user_id_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/youtube_video_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';

class ProgressVideoFeed extends StatefulWidget {
  const ProgressVideoFeed({super.key});

  @override
  State<ProgressVideoFeed> createState() => _ProgressVideoFeedState();
}

class _ProgressVideoFeedState extends State<ProgressVideoFeed> {
  static const int _pageSize = 5;

  final List<ProgressVideo> _streamVideos = [];
  final List<ProgressVideo> _moreVideos = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    String? courseId = libraryState.selectedCourse?.id;
    if (courseId == null) {
      return;
    }
    _subscription = ProgressVideoFunctions.streamCourseVideos(courseId,
            limit: _pageSize)
        .listen((snapshot) {
      setState(() {
        _streamVideos.clear();
        _streamVideos.addAll(
            ProgressVideoFunctions.convertSnapshotToSortedProgressVideos(
                snapshot));
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
        } else {
          _lastDocument = null;
          _hasMore = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    String? courseId = libraryState.selectedCourse?.id;
    if (courseId == null) return;
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await ProgressVideoFunctions.fetchCourseVideos(courseId,
            startAfter: _lastDocument, limit: _pageSize);
    List<ProgressVideo> newVideos =
        snapshot.docs.map((e) => ProgressVideo.fromSnapshot(e)).toList();
    setState(() {
      _moreVideos.addAll(newVideos);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ProgressVideo> allVideos = [..._streamVideos, ..._moreVideos];
    if (allVideos.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('No progress videos yet – be the first to upload!',
              style: CustomTextStyles.getBody(context)));
    }
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allVideos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= allVideos.length) {
            _loadMore();
            return const Center(child: CircularProgressIndicator());
          }
          ProgressVideo video = allVideos[index];
          LibraryState libraryState =
              Provider.of<LibraryState>(context, listen: false);
          var lesson = libraryState.findLesson(video.lessonId.id);
          String lessonTitle = lesson?.title ?? 'Lesson';
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProfileImageByUserIdWidget(video.userId, libraryState),
                            const SizedBox(width: 8),
                            FutureBuilder<User>(
                                future:
                                    UserFunctions.getUserById(video.userId.id),
                                builder: (context, snapshot) {
                                  String name =
                                      snapshot.data?.displayName ?? 'Student';
                                  return Text(name,
                                      style:
                                          CustomTextStyles.getBody(context));
                                }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (video.youtubeVideoId != null)
                          YouTubeVideoWidget(videoId: video.youtubeVideoId!),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => LessonDetailArgument.goToLessonDetailPage(
                              context, video.lessonId.id),
                          child: Text(lessonTitle,
                              style: CustomTextStyles.getBody(context)?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary)),
                        ),
                        if (video.timestamp != null)
                          Text(video.timestamp!.toDate().toString(),
                              style: CustomTextStyles.getBodySmall(context)),
                      ])));
        });
  }
}

