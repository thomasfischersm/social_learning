import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/state/library_state.dart';

class User {
  String id;
  String uid;
  String displayName;
  String sortName;
  bool isAdmin;
  String? profileFireStoragePath;
  List<DocumentReference>? enrolledCourseIds;
  DocumentReference? currentCourseId;
  bool isProfilePrivate;
  List<CourseProficiency>? courseProficiencies;

  User(this.id, this.uid, this.displayName, this.sortName, this.isAdmin,
      this.profileFireStoragePath, this.enrolledCourseIds, this.currentCourseId, this.isProfilePrivate, this.courseProficiencies);

  User.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        uid = e.data()?['uid'] ?? '',
        displayName = e.data()?['displayName'] ?? '',
        sortName = e.data()?['sortName'] ?? '',
        isAdmin = e.data()?['isAdmin'] ?? false,
        profileFireStoragePath = e.data()?['profileFireStoragePath'],
        enrolledCourseIds = (e.data()?['enrolledCourseIds']) != null ? [for(var doc in e.data()?['enrolledCourseIds']) doc as DocumentReference] : [],
        currentCourseId = e.data()?['currentCourseId'],
        isProfilePrivate = e.data()?['isProfilePrivate'] ?? false,
        courseProficiencies = (e.data()?['courseProficiencies']) != null ? [for(var doc in e.data()?['courseProficiencies']) CourseProficiency(doc['courseId'], doc['proficiency'])] : [];

  CourseProficiency? getCourseProficiency(Course course) {
    return courseProficiencies?.firstWhereOrNull((element) => element.courseId.id == course.id);
  }
}

class CourseProficiency {
  DocumentReference courseId;
  double proficiency;

  CourseProficiency(this.courseId, this.proficiency);
}
