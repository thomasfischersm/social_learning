
import 'package:firebase_analytics/firebase_analytics.dart';

class CustomFirebase {

  static  late FirebaseAnalytics analytics;

  static init() {
    analytics = FirebaseAnalytics.instance;
  }
}