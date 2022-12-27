import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String uid;
  String displayName;
  String sortName;
  bool isAdmin;

  User(this.id, this.uid, this.displayName, this.sortName, this.isAdmin);

  User.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        uid = e.data()['uid'] ?? '' as String,
        displayName = e.data()['displayName'] ?? '' as String,
        sortName = e.data()['sortName'] ?? '' as String,
        isAdmin = e.data()['isAdmin'] ?? false as bool;
}
