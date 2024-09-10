import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubeVideoWidget extends StatefulWidget {
  final String videoId;

  const YouTubeVideoWidget({super.key, required this.videoId});

  @override
  YouTubeVideoWidgetState createState() => YouTubeVideoWidgetState();
}

class YouTubeVideoWidgetState extends State<YouTubeVideoWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the video ID passed in

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: false,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close(); // Close the controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return Column(
          children: [
            // Player Widget
            player,
          ],
        );
      },
    );
  }
}
