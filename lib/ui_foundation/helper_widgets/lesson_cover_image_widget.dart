import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/download_url_cache_state.dart';

class LessonCoverImageWidget extends StatefulWidget {
  final String? coverFireStoragePath;

  const LessonCoverImageWidget(this.coverFireStoragePath, {super.key});

  @override
  State<StatefulWidget> createState() {
    return LessonCoverImageWidgetState();
  }
}

class LessonCoverImageWidgetState extends State<LessonCoverImageWidget> {
  String? _coverPhotoUrl;
  String? _lastCoverFireStoragePath;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastCoverFireStoragePath != widget.coverFireStoragePath) {
      init();
    }
    var coverPhotoUrl = _coverPhotoUrl;
    if (coverPhotoUrl != null) {
      return AspectRatio(
          aspectRatio: 16 / 9,
          child:
              Image(image: NetworkImage(coverPhotoUrl), fit: BoxFit.contain));
    }
    return const SizedBox.shrink();
  }

  Future<void> init() async {
    _lastCoverFireStoragePath = widget.coverFireStoragePath;
    if (widget.coverFireStoragePath != null) {
      try {
        DownloadUrlCacheState cacheState =
            Provider.of<DownloadUrlCacheState>(context, listen: false);
        String? url = await cacheState.getDownloadUrl(
          widget.coverFireStoragePath,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _coverPhotoUrl = url;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _coverPhotoUrl = null;
        });
      }
    } else {
      setState(() {
        _coverPhotoUrl = null;
      });
    }
  }
}
