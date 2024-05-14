import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String uid;
  String displayName;
  String sortName;
  bool isAdmin;
  String? profileFireStoragePath;

  User(this.id, this.uid, this.displayName, this.sortName, this.isAdmin,
      this.profileFireStoragePath);

  User.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        uid = e.data()?['uid'] ?? '',
        displayName = e.data()?['displayName'] ?? '',
        sortName = e.data()?['sortName'] ?? '',
        isAdmin = e.data()?['isAdmin'] ?? false,
        profileFireStoragePath = e.data()?['profileFireStoragePath'];
}
