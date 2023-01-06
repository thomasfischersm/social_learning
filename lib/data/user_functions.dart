import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:social_learning/data/user.dart';

class UserFunctions {
  static void createUser(String uid, String? displayName, String? email) {
    FirebaseFirestore.instance.collection('users').add(<String, dynamic>{
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'displayName': displayName,
      'sortName': displayName?.toLowerCase(),
      'email': email,
    });
  }

  static void updateDisplayName(String uid, String displayName) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    FirebaseFirestore.instance
        .collection('users')
        .doc(querySnapshot.docs[0].id)
        .update({
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'displayName': displayName,
      'sortName': displayName.toLowerCase(),
    });
  }

  static void updateProfilePhoto(String profileFireStoragePath) async {
    String uid = auth.FirebaseAuth.instance.currentUser!.uid;
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    FirebaseFirestore.instance
        .collection('users')
        .doc(querySnapshot.docs[0].id)
        .update({
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'profileFireStoragePath': profileFireStoragePath,
    });
  }

  static Future<List<User>> findUsersByPartialDisplayName(
      String partialDisplayName, int resultLimit) async {
    // Protect against charges.
    if (partialDisplayName.length < 3) {
      return [];
    }

    partialDisplayName = partialDisplayName.toLowerCase();
    String minStr = partialDisplayName;
    String maxStr = partialDisplayName.substring(
            0, partialDisplayName.length - 1) +
        String.fromCharCode(
            partialDisplayName.codeUnits[partialDisplayName.length - 1] + 1);

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('sortName', isGreaterThanOrEqualTo: minStr)
        .where('sortName', isLessThan: maxStr)
        .limit(resultLimit)
        .get();
    List<User> users = snapshot.docs.map((e) => User.fromSnapshot(e)).toList();
    users.removeWhere(
        (user) => user.uid == auth.FirebaseAuth.instance.currentUser!.uid);

    return users;
  }

  static Future<User> getCurrentUser() async {
    String uid = auth.FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    var userDoc = snapshot.docs[0];
    return User.fromSnapshot(userDoc);
  }
}
