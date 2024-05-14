import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileImageWidget extends StatefulWidget {
  final String? profileFireStoragePath;

  const ProfileImageWidget(this.profileFireStoragePath, {super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileImageWidgetState();
  }
}

class ProfileImageWidgetState extends State<ProfileImageWidget> {
  String? _profilePhotoUrl;
  String? _lastProfileFireStoragePath;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastProfileFireStoragePath != widget.profileFireStoragePath) {
      init();
    }
    var profilePhotoUrl = _profilePhotoUrl;
    if (profilePhotoUrl != null) {
      return CircleAvatar(
            backgroundImage: NetworkImage(profilePhotoUrl),
            maxRadius: 100,
          );
    } else {
      return const Icon(Icons.photo);
    }
  }

  Future<void> init() async {
    _lastProfileFireStoragePath = widget.profileFireStoragePath;
    if (widget.profileFireStoragePath != null) {
      String url = await FirebaseStorage.instance
          .ref(widget.profileFireStoragePath)
          .getDownloadURL();
      setState(() {
        _profilePhotoUrl = url;
      });
    }
  }
}
