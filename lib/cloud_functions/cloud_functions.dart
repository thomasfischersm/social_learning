
import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctions {
  static Future<void> generateCourseFromPlan(String coursePlanId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('generateCoursePlan');
    final result = await callable.call({'coursePlanId': coursePlanId});

    final success = result.data['success'] == true;
    if (!success) {
      throw Exception('Cloud function failed');
    }
  }
}
