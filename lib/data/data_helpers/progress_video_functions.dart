
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class ProgressVideoFunctions {
  static bool isValidYouTubeUrl(String url) {
    final youtubeUrlPattern = RegExp(
      r'^(https?\:\/\/)?(www\.youtube\.com|youtu\.?be)\/.+$',
      caseSensitive: false,
      multiLine: false,
    );
    return youtubeUrlPattern.hasMatch(url.trim());
  }

  static String? extractYouTubeVideoId(String url) {
    final videoIdPattern = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    final match = videoIdPattern.firstMatch(url.trim());
    return match?.group(1); // Returns the video ID if found, else null
  }

  static void createProgressVideo(
      Lesson lesson, User user, String youtubeUrl) async {
    await FirebaseFirestore.instance
        .collection('progressVideos')
        .add(<String, dynamic>{
      'userId': docRef('users', user.id),
      'userUid': user.uid,
      'courseId':
          docRef('courses', lesson.courseId.id),
      'lessonId': docRef('lessons', lesson.id!),
      'youtubeUrl': youtubeUrl,
      'youtubeVideoId': extractYouTubeVideoId(youtubeUrl),
      'isProfilePrivate': user.isProfilePrivate,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static StreamBuilder createMyProgressVideosStream(
      String lessonId,
      User user,
      Widget Function(BuildContext context, List<ProgressVideo> progressVideos)
          builder) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('progressVideos')
            .where('lessonId', isEqualTo: docRef('lessons', lessonId))
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertAsyncSnapshotToSortedProgressVideos(snapshot);

          return builder(context, progressVideos);
        });
  }

  static StreamBuilder createMyProgressVideosForLessonStream(
      String lessonId,
      User user,
      Widget Function(BuildContext context, List<ProgressVideo> progressVideos)
          builder) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('progressVideos')
            .where('lessonId', isEqualTo: docRef('lessons', lessonId))
            .where('userId', isEqualTo: docRef('users', user.id))
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertAsyncSnapshotToSortedProgressVideos(snapshot);

          return builder(context, progressVideos);
        });
  }

  static StreamBuilder createProgressVideosForLessonStream(
      String lessonId,
      Widget Function(BuildContext context, List<ProgressVideo> progressVideos)
          builder) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('progressVideos')
            .where('lessonId', isEqualTo: docRef('lessons', lessonId))
            .where('isProfilePrivate', isNotEqualTo: true)
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertAsyncSnapshotToSortedProgressVideos(snapshot);

          // Remove self videos
          ApplicationState applicationState =
              Provider.of<ApplicationState>(context, listen: false);
          String? currentUserUid = applicationState.currentUser?.uid;
          if (currentUserUid != null) {
            progressVideos
                .removeWhere((element) => element.userUid == currentUserUid);
          }

          return builder(context, progressVideos);
        });
  }

  static List<ProgressVideo> convertAsyncSnapshotToSortedProgressVideos(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> asyncSnapshot) {
    var snapshot = asyncSnapshot.data;
    print('convertSnapshotToSortedProgressVideos data: $snapshot');
    if (snapshot == null) {
      return [];
    }

    return convertSnapshotToSortedProgressVideos(snapshot);
  }

  static List<ProgressVideo> convertSnapshotToSortedProgressVideos(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    List<ProgressVideo> progressVideos = snapshot.docs.map(
      (DocumentSnapshot<Map<String, dynamic>> document) {
        return ProgressVideo.fromSnapshot(document);
      },
    ).toList();

    progressVideos.sort((a, b) {
      Timestamp timestampA = a.timestamp ?? Timestamp.now();
      Timestamp timestampB = b.timestamp ?? Timestamp.now();
      return timestampB.compareTo(timestampA);
    });

    return progressVideos;
  }

  static StreamBuilder createProfileProgressVideoStream(
      ApplicationState applicationState,
      LibraryState libraryState,
      Widget Function(
              BuildContext context, List<List<ProgressVideo>> progressVideos)
          builder) {
    var currentUserRef =
        docRef('users', applicationState.currentUser?.id ?? '');
    var currentDocRef =
        docRef('courses', libraryState.selectedCourse?.id ?? '');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('progressVideos')
            .where('userId', isEqualTo: currentUserRef)
            .where('courseId', isEqualTo: currentDocRef)
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertAsyncSnapshotToSortedProgressVideos(snapshot);

          // Group by lessonId
          Map<String, List<ProgressVideo>> progressVideosByLessonId =
              {};
          for (var progressVideo in progressVideos) {
            String lessonId = progressVideo.lessonId.id;
            if (!progressVideosByLessonId.containsKey(lessonId)) {
              progressVideosByLessonId[lessonId] = [];
            }
            progressVideosByLessonId[lessonId]!.add(progressVideo);
          }

          List<List<ProgressVideo>> progressVideosList =
              progressVideosByLessonId.values.toList();
          return builder(context, progressVideosList);
        });
  }

  static Future<List<List<ProgressVideo>>> createProfileProgressVideoFuture(
      User user,
      LibraryState libraryState) async {
    var currentUserRef = docRef('users', user.id);
    var currentDocRef =
        docRef('courses', libraryState.selectedCourse?.id ?? '');

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('progressVideos')
        .where('userId', isEqualTo: currentUserRef)
        .where('courseId', isEqualTo: currentDocRef)
        .get();

    List<ProgressVideo> progressVideos =
        convertSnapshotToSortedProgressVideos(snapshot);

    // Group by lessonId
    Map<String, List<ProgressVideo>> progressVideosByLessonId = {};
    for (var progressVideo in progressVideos) {
      String lessonId = progressVideo.lessonId.id;
      if (!progressVideosByLessonId.containsKey(lessonId)) {
        progressVideosByLessonId[lessonId] = [];
      }
      progressVideosByLessonId[lessonId]!.add(progressVideo);
    }

    List<List<ProgressVideo>> progressVideosList =
        progressVideosByLessonId.values.toList();
    return progressVideosList;
  }
}
