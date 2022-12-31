import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String uid;
  String displayName;
  String sortName;
  bool isAdmin;
  String? profileFireStoragePath;
  String? profilePhotoUrl;

  User(this.id, this.uid, this.displayName, this.sortName, this.isAdmin,
      this.profileFireStoragePath, this.profilePhotoUrl);

  User.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        uid = e.data()?['uid'] ?? '' as String,
        displayName = e.data()?['displayName'] ?? '' as String,
        sortName = e.data()?['sortName'] ?? '' as String,
        isAdmin = e.data()?['isAdmin'] ?? false as bool,
        profileFireStoragePath = e.data()?['profileFireStoragePath'],
        profilePhotoUrl = e.data()?['profilePhotoUrl'];
}
