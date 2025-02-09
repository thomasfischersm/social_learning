import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/state/library_state.dart';

class User {
  String id;
  String uid;
  String displayName;
  String sortName;
  String profileText;
  bool isAdmin;
  String? profileFireStoragePath;
  List<DocumentReference>? enrolledCourseIds;
  DocumentReference? currentCourseId;
  bool isProfilePrivate;
  List<CourseProficiency>? courseProficiencies;
  bool isGeoLocationEnabled;
  GeoPoint? location;
  GeoPoint? roughUserLocation;
  String? instagramHandle;
  String? calendlyUrl;

  User(
      this.id,
      this.uid,
      this.displayName,
      this.sortName,
      this.profileText,
      this.isAdmin,
      this.profileFireStoragePath,
      this.enrolledCourseIds,
      this.currentCourseId,
      this.isProfilePrivate,
      this.courseProficiencies,
      this.isGeoLocationEnabled,
      this.location,
      this.roughUserLocation,
      this.instagramHandle,
      this.calendlyUrl);

  User.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        uid = e.data()?['uid'] ?? '',
        displayName = e.data()?['displayName'] ?? '',
        sortName = e.data()?['sortName'] ?? '',
        profileText = e.data()?['profileText'] ?? '',
        isAdmin = e.data()?['isAdmin'] ?? false,
        profileFireStoragePath = e.data()?['profileFireStoragePath'],
        enrolledCourseIds = (e.data()?['enrolledCourseIds']) != null
            ? [
                for (var doc in e.data()?['enrolledCourseIds'])
                  doc as DocumentReference
              ]
            : [],
        currentCourseId = e.data()?['currentCourseId'],
        isProfilePrivate = e.data()?['isProfilePrivate'] ?? false,
        courseProficiencies = (e.data()?['courseProficiencies']) != null
            ? [
                for (var doc in e.data()?['courseProficiencies'])
                  CourseProficiency(doc['courseId'], doc['proficiency'])
              ]
            : [],
        isGeoLocationEnabled = e.data()?['isGeoLocationEnabled'] ?? false,
        location = e.data()?['location'],
        roughUserLocation = e.data()?['roughUserLocation'],
        instagramHandle = e.data()?['instagramHandle'],
        calendlyUrl = e.data()?['calendlyUrl'];

  CourseProficiency? getCourseProficiency(Course course) {
    return courseProficiencies
        ?.firstWhereOrNull((element) => element.courseId.id == course.id);
  }

  String? get calendlyHandle {
    String? localUrl = calendlyUrl;
    if (localUrl == null) {
      return null;
    }
    return RegExp(r'calendly\.com/([^/]+)').firstMatch(localUrl)?.group(1);
  }
}

class CourseProficiency {
  DocumentReference courseId;
  double proficiency;

  CourseProficiency(this.courseId, this.proficiency);
}
