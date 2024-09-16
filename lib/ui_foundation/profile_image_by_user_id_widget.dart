import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/user.dart';

class ProfileImageByUserIdWidget extends StatefulWidget {
  final DocumentReference userId;

  const ProfileImageByUserIdWidget(this.userId, {super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileImageByUserIdWidgetState();
  }
}

class ProfileImageByUserIdWidgetState extends State<ProfileImageByUserIdWidget> {
  String? _profilePhotoUrl;
  // String? _lastProfileFireStoragePath;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    if (_profilePhotoUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(_profilePhotoUrl!),
        maxRadius: 100,
      );
    } else {
      return const Icon(Icons.photo);
    }
  }

  Future<void> init() async {
    var userRef = FirebaseFirestore.instance.doc('/users/${widget.userId.id}');
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      User user = User.fromSnapshot(userSnapshot);

      if (user.profileFireStoragePath != null) {
        String url = await FirebaseStorage.instance
            .ref(user.profileFireStoragePath)
            .getDownloadURL();
        if (mounted) {
          setState(() {
            _profilePhotoUrl = url;
          });
        }
      }
    }
  }
}