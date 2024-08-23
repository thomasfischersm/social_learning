import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';

/// A widget that shows the cover photo for a lesson. The user can tap to
/// upload a new photo. If there is no photo, a place holder is shown.
/// The photo is stored in Firebase Storage.
class UploadLessonCoverWidget extends StatefulWidget {
  final Lesson? lesson;

  const UploadLessonCoverWidget(this.lesson, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UploadLessonCoverWidgetState();
  }
}

class UploadLessonCoverWidgetState extends State<UploadLessonCoverWidget> {
  String? _lastCoverFireStoragePath;
  String? _coverPhotoUrl;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    _lastCoverFireStoragePath = widget.lesson?.coverFireStoragePath;
    if (_lastCoverFireStoragePath != null) {
      String url = await FirebaseStorage.instance
          .ref(_lastCoverFireStoragePath)
          .getDownloadURL();
      setState(() {
        _coverPhotoUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastCoverFireStoragePath != widget.lesson?.coverFireStoragePath) {
      init();
    }

    if (_coverPhotoUrl != null) {
      return buildActualCoverPhoto(context);
    } else {
      return buildPlaceHolder(context);
    }
  }

  Widget buildActualCoverPhoto(BuildContext context) {
    return InkWell(
        onTap: () => _pickCoverPhoto(),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(_coverPhotoUrl!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ));
  }

  Widget buildPlaceHolder(BuildContext context) {
    return InkWell(
        onTap: () => _pickCoverPhoto(),
        // TODO: Tell the user to save the lesson first.
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey[500],
              ),
            ),
          ),
        ));
  }

  _pickCoverPhoto() async {
    Lesson? lesson = widget.lesson;
    if (lesson == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not yet...'),
          content: const Text('Please, save the lesson before uploading a photo.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );

      return;
    }

    var libraryState = Provider.of<LibraryState>(context, listen: false);

    // Pick the photo from the user.
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    int length = await file?.length() ?? -1;

    // Upload the photo to Firebase.
    if (file != null) {
      var fireStoragePath = '/lesson_covers/${lesson.id}/coverPhoto';
      var storageRef = FirebaseStorage.instance.ref(fireStoragePath);
      try {
        var imageData = await file.readAsBytes();
        await storageRef.putData(
            imageData, SettableMetadata(contentType: file.mimeType));

        // Save the path to the lesson.
        lesson.coverFireStoragePath = fireStoragePath;
        libraryState.updateLesson(lesson);
      } catch (e) {
        print('Error uploading photo: $e');
      }

      // Cause the photo to be re-rendered.
      setState(() {
        _lastCoverFireStoragePath = null;
      });

      print('Uploaded photo of length $length to $fireStoragePath');
    }
  }
}
