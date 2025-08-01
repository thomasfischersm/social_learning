import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:url_launcher/url_launcher.dart';

class UserFunctions {
  static void createUser(String uid, String? displayName, String? email) {
    FirebaseFirestore.instance.collection('users').add(<String, dynamic>{
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'displayName': displayName,
      'sortName': displayName?.toLowerCase(),
      'profileText': '',
      'email': email,
      'isProfilePrivate': false,
      'isGeoLocationEnabled': false,
      'created': FieldValue.serverTimestamp(),
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

  static void updateCurrentCourse(User currentUser, String courseId) async {
    var courseRef = docRef('courses', courseId);
    currentUser.currentCourseId = courseRef;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .set({'currentCourseId': courseRef}, SetOptions(merge: true));
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

  static Future<User> getUserByUid(String uid) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    var userDoc = snapshot.docs[0];
    return User.fromSnapshot(userDoc);
  }

  static Future<User> getUserById(String id) async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get();
    return User.fromSnapshot(doc);
  }

  static bool get isFirebaseAuthLoggedOut =>
      auth.FirebaseAuth.instance.currentUser == null;

  static String? extractNumberId(DocumentReference? id) {
    if (id != null) {
      var idStr = id.path;
      int index = idStr.lastIndexOf('/');
      if (index != -1) {
        return idStr.substring(index + 1);
      }
    }

    return null;
  }

  static void updateCourseProficiency(ApplicationState applicationState,
      LibraryState libraryState, StudentState studentState) async {
    // Calculate proficiency.
    Course? course = libraryState.selectedCourse;
    if (course == null) {
      return;
    }
    int lessons = max(libraryState.lessons?.length ?? 1, 1);
    int completedLessons = studentState.getLessonsLearned(course, libraryState);
    double proficiency = completedLessons / lessons.toDouble();
    proficiency = double.parse((proficiency.toStringAsFixed(2)));
    if (lessons == 1 || completedLessons == 0) {
      print(
          'Not updating proficiency because learned lessons or lesson count has not been loaded.');
      return;
    }

    // Check if the proficiency has changed.
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }
    CourseProficiency? courseProficiency = user.getCourseProficiency(course);
    if (courseProficiency != null &&
        ((courseProficiency.proficiency - proficiency).abs() < 0.01)) {
      print(
          'Proficiency has not changed $proficiency. Completed lessons: $completedLessons, total lessons: $lessons.');
      return;
    }

    // Update course proficiency.
    if (courseProficiency != null) {
      // Remove the old entry.
      await docRef('users', user.id).update({
        'courseProficiencies': FieldValue.arrayRemove([
          {
            'courseId': courseProficiency.courseId,
            'proficiency': courseProficiency.proficiency,
          }
        ]),
      });
    }

    // Add the new entry.
    await docRef('users', user.id).update({
      'courseProficiencies': FieldValue.arrayUnion([
        {
          'courseId': docRef('courses', course.id),
          'proficiency': proficiency,
        }
      ]),
    });

    // Update the local value.
    if (courseProficiency != null) {
      courseProficiency.proficiency = proficiency;
    } else {
      user.courseProficiencies?.add(CourseProficiency(
          docRef('courses', course.id),
          proficiency));
    }

    print('Updated proficiency to $proficiency.');
  }

  static void updateProfileText(
      ApplicationState applicationState, String profileText) {
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }

    profileText = profileText.trim();
    user.profileText = profileText;

    docRef('users', user.id).update({
      'profileText': profileText,
    });
  }

  static Future<void> disableGeoLocation(
      ApplicationState applicationState) async {
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }

    user.isGeoLocationEnabled = false;
    user.location = null;
    user.roughUserLocation = null;

    removeGeoFromPracticeRecords(user);

    await docRef('users', user.id).update({
      'isGeoLocationEnabled': false,
      'location': null,
      'roughUserLocation': null,
    });
  }

  static Future<bool> enableGeoLocation(
      ApplicationState applicationState) async {
    User? user = applicationState.currentUser;
    if (user == null) {
      return false;
    }

    if (kIsWeb) {
      if (!await updateGeoLocation(applicationState)) {
        return false;
      }
    } else {
      // for iOS and Android
      PermissionStatus status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        print("Mobile: Location permission granted.");
      } else if (status.isDenied) {
        var permissionStatus = await Permission.locationWhenInUse.request();
        if (!permissionStatus.isGranted) {
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        openAppSettings(); // Guide user to app settings
        return false;
      }
    }

    if (!kIsWeb && !await updateGeoLocation(applicationState)) {
      // Failed to update the geo location.
      return false;
    }

    user.isGeoLocationEnabled = true;

    await docRef('users', user.id).update({
      'isGeoLocationEnabled': true,
    });

    return true;
  }

  /// Tries to get the current location and returns false if the user denied
  /// permission.
  static Future<bool> updateGeoLocation(
      ApplicationState applicationState) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return or handle accordingly
      print("Location services are disabled.");
      return false;
    }

    // Check if location permission is granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if it is denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied, handle it here
        print("Location permission denied.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      print("Location permission is permanently denied.");
      return false;
    }

    // If permissions are granted, get the current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      print(
          "Current location: Lat: ${position.latitude}, Lon: ${position.longitude}");

      var newLocation = GeoPoint(position.latitude, position.longitude);
      var userData = {
        'location': newLocation,
      };
      User user = applicationState.currentUser!;

      if (_updatePracticeRecordsGeoLocation(applicationState, position)) {
        user.roughUserLocation = newLocation;
        userData['roughUserLocation'] = newLocation;
      }

      user.location = newLocation;
      await docRef('users', applicationState.currentUser!.id)
          .update(userData);

      return true;
    } catch (e) {
      print("Error getting location: $e");
      return false;
    }
  }

  static bool _updatePracticeRecordsGeoLocation(
      ApplicationState applicationState, Position position) {
    GeoPoint? roughUserLocation =
        applicationState.currentUser?.roughUserLocation;
    GeoPoint currentLocation = GeoPoint(position.latitude, position.longitude);

    // Skip if the profile is private.
    if (applicationState.currentUser?.isProfilePrivate ?? true) {
      print('User profile is private. Not updating practice records.');
      return false;
    }

    // Calculate distance between the points.
    double minDistanceToUpdate = 20;
    if ((roughUserLocation != null) &&
        haversineDistance(currentLocation, roughUserLocation) <
            minDistanceToUpdate) {
      // Don't update the practice records. The user hasn't moved enough.
      print('User has not moved enough to update practice records.');
      return false;
    }

    // Update the practice records.
    FirebaseFirestore.instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: applicationState.currentUser!.uid)
        .where('isGraduation', isEqualTo: true)
        .get()
        .then((snapshot) {
      // TODO: Perhaps batch the writes.
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        var record = PracticeRecord.fromSnapshot(doc);
        batch.update(
            docRef('practiceRecords', record.id), {
          'roughUserLocation': currentLocation,
        });
      }
      batch.commit();
      print(
          'Updated ${snapshot.docs.length} practice records with a new geo location.');
    });

    return true;
  }

  static double haversineDistance(GeoPoint point1, GeoPoint point2) {
    const R = 6371; // Earth radius in kilometers

    double lat1Rad = _radians(point1.latitude);
    double lat2Rad = _radians(point2.latitude);
    double dLatRad = _radians(point2.latitude - point1.latitude);
    double dLonRad = _radians(point2.longitude - point1.longitude);

    double a = sin(dLatRad / 2) * sin(dLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLonRad / 2) * sin(dLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double? toMiles(double? kilometers) {
    if (kilometers == null) {
      return null;
    }
    return kilometers * 0.621371;
  }

  static double _radians(double degrees) {
    return degrees * pi / 180;
  }

  static void removeGeoFromPracticeRecords(User user) {
    FirebaseFirestore.instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: user.uid)
        .where('isGraduation', isEqualTo: true)
        .get()
        .then((snapshot) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        // TODO: Perhaps batch the writes.
        var record = PracticeRecord.fromSnapshot(doc);
        if (record.roughUserLocation != null) {
          batch.update(
              docRef('practiceRecords', record.id), {
            'roughUserLocation': null,
          });
        }
      }
      batch.commit();
      print('Removed ${snapshot.docs.length} practice records geo location.');
    });
  }

  static void updateInstagramHandle(
      String? newInstagramHandle, ApplicationState applicationState) async {
    // Clean up the input
    newInstagramHandle = newInstagramHandle?.trim();
    if (newInstagramHandle?.startsWith('@') ?? false) {
      newInstagramHandle = newInstagramHandle!.substring(1);
    }

    // Convert to null if necessary.
    if (newInstagramHandle?.isEmpty ?? false) {
      newInstagramHandle = null;
    }

    // Update the user's Instagram handle
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }

    user.instagramHandle = newInstagramHandle;

    await docRef('users', user.id).update({
      'instagramHandle': newInstagramHandle,
    });
  }

  static void updateCalendlyUrl(
      String? newCalendlyUrl, ApplicationState applicationState) async {
    // Clean up the input
    newCalendlyUrl = newCalendlyUrl?.trim();

    // Convert to null if necessary.
    if (newCalendlyUrl?.isEmpty ?? false) {
      newCalendlyUrl = null;
    }

    // Check the format: https://calendly.com/thomas-playposse/30min
    if (newCalendlyUrl != null) {
      final uri = Uri.tryParse(newCalendlyUrl);
      if (uri == null || uri.host != 'calendly.com') {
        newCalendlyUrl = null;
      }
    }

    // Update the user's Instagram handle
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }

    user.calendlyUrl = newCalendlyUrl;

    await docRef('users', user.id).update({
      'calendlyUrl': newCalendlyUrl,
    });
  }

  static Future<void> openInstaProfile(User? user) async {
    if ((user == null) || (user.instagramHandle == null)) {
      return;
    }

    final url = Uri.parse('https://www.instagram.com/${user.instagramHandle}/');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> openCalendlyUrl(User? user) async {
    if ((user == null) || (user.calendlyUrl == null)) {
      return;
    }

    final url = Uri.parse(user.calendlyUrl!);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> openEmailClient(User? user) async {
      if (user == null || user.email == null) {
        return;
      }

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: user.email,
        query: Uri.encodeQueryComponent('subject=Hello&body=Hi ${user.displayName},'),
      );

      if (await canLaunchUrl(emailUri)) {
        print('Launching email client with URI: $emailUri');
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $emailUri';
      }
    }
}
