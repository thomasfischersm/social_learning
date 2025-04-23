import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/progress_video_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/youtube_video_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class ProfileProgressVideoWidget extends StatelessWidget {
  final User user;

  const ProfileProgressVideoWidget(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    LibraryState libraryState = Provider.of<LibraryState>(context, listen: true);

    return FutureBuilder(
        future: ProgressVideoFunctions.createProfileProgressVideoFuture(
            user, libraryState),
        builder: (BuildContext context,
            AsyncSnapshot<List<List<ProgressVideo>>> snapshot) {
          var progressVideosByLesson = snapshot.data;
          if ((progressVideosByLesson == null) ||
              progressVideosByLesson.isEmpty) {
            // The user doesn't have progress videos. Show nothing.
            return const SizedBox.shrink();
          }

          List<Widget> children = [];
          children.add(Text(
            'Progress Videos',
            style: CustomTextStyles.subHeadline,
          ));

          for (List<ProgressVideo> progressVideoList
              in progressVideosByLesson) {
            if (progressVideoList.isEmpty) {
              continue;
            }

            // Show the lesson title.
            children.add(const SizedBox(
              height: 4,
            ));
            var firstVideo = progressVideoList[0];
            Lesson? lesson = libraryState.findLesson(firstVideo.lessonId.id);
            if (lesson != null) {
              children.add(
                  Text(lesson.title, style: CustomTextStyles.getBody(context)));
            }

            // Show the first video big.
            children
                .add(YouTubeVideoWidget(videoId: firstVideo.youtubeVideoId!));

            // Show the remaining videos small.
            if (progressVideoList.length > 1) {
              children.add(const SizedBox(
                height: 4,
              ));

              children.add(LayoutBuilder(builder: (context, constraints) {
                return SizedBox(
                    width: constraints.maxWidth,
                    child: Wrap(
                        spacing: 10,
                        alignment: WrapAlignment.start,
                        runSpacing: 10,
                        children:
                            progressVideoList.sublist(1).map((progressVideo) {
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
                              width:
                                  (constraints.maxWidth ~/ 3 - 20).toDouble(),
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
              }));
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        });
  }
}
