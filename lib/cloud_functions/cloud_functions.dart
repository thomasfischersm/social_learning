import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../data/course.dart';
import '../data/course_profile.dart';

class CloudFunctions {
  static Future<void> generateCourseFromPlan(String coursePlanId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await http
        .post(
          Uri.parse(
              'https://learning-lab-server-kofwkwjq5q-uc.a.run.app/api/generate-course-plan'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'coursePlanId': coursePlanId}),
        )
        .timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      print('Cloud Run call failed: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Cloud Run call failed: ${response.body}');
    }
  }

  static Future<void> generateCourseInventory(
      Course course, CourseProfile? profile) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await http
        .post(
          Uri.parse(
              'https://learning-lab-server-kofwkwjq5q-uc.a.run.app/api/generate-teachable-items'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': course.title,
            'description': course.description,
            'topicAndFocus': profile?.topicAndFocus,
            'scheduleAndDuration': profile?.scheduleAndDuration,
            'targetAudience': profile?.targetAudience,
            'groupSizeAndFormat': profile?.groupSizeAndFormat,
            'location': profile?.location,
            'howStudentsJoin': profile?.howStudentsJoin,
            'toneAndApproach': profile?.toneAndApproach,
            'anythingUnusual': profile?.anythingUnusual,
          }),
        )
        .timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      print('Cloud Run call failed: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Cloud Run call failed: ${response.body}');
    }
  }
}
