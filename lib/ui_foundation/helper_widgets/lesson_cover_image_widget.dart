import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/admin/directory_v1.dart';

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
    } else {
      return const Placeholder();
    }
  }

  Future<void> init() async {
    _lastCoverFireStoragePath = widget.coverFireStoragePath;
    if (widget.coverFireStoragePath != null) {
      String url = await FirebaseStorage.instance
          .ref(widget.coverFireStoragePath)
          .getDownloadURL();
      setState(() {
        _coverPhotoUrl = url;
      });
    }
  }
}
