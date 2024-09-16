import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';

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
      String lessonId, User user, String youtubeUrl) async {
    await FirebaseFirestore.instance
        .collection('progressVideos')
        .add(<String, dynamic>{
      'userId': FirebaseFirestore.instance.doc('/users/${user.id}'),
      'userUid': user.uid,
      'lessonId': FirebaseFirestore.instance.doc('/lessons/$lessonId'),
      'youtubeUrl': youtubeUrl,
      'youtubeVideoId': extractYouTubeVideoId(youtubeUrl),
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
            .where('lessonId',
                isEqualTo: FirebaseFirestore.instance.doc('/lessons/$lessonId'))
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertSnapshotToSortedProgressVideos(snapshot);

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
            .where('lessonId',
                isEqualTo: FirebaseFirestore.instance.doc('/lessons/$lessonId'))
            .where('userId',
                isEqualTo: FirebaseFirestore.instance.doc('/users/${user.id}'))
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertSnapshotToSortedProgressVideos(snapshot);

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
            .where('lessonId',
                isEqualTo: FirebaseFirestore.instance.doc('/lessons/$lessonId'))
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            print('Something went wrong: ${snapshot.error}');
            return const Text('Something went wrong.');
          }

          List<ProgressVideo> progressVideos =
              convertSnapshotToSortedProgressVideos(snapshot).reversed.toList();

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

  static List<ProgressVideo> convertSnapshotToSortedProgressVideos(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    print('convertSnapshotToSortedProgressVideos data: ${snapshot.data}');
    if (snapshot.data == null) {
      return [];
    }

    List<ProgressVideo> progressVideos = snapshot.data!.docs.map(
      (DocumentSnapshot<Map<String, dynamic>> document) {
        return ProgressVideo.fromSnapshot(document);
      },
    ).toList();

    progressVideos.sort((a, b) {
      Timestamp timeStampA = a.timestamp ?? Timestamp.now();
      Timestamp timestampB = b.timestamp ?? Timestamp.now();
      return timeStampA.compareTo(timestampB);
    });

    return progressVideos;
  }
}
