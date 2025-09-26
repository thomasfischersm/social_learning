import 'dart:async';

import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/state/firestore_subscription/course_analytics_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class CourseAnalyticsPracticeRecordsSubscription
    extends FirestoreListSubscription<PracticeRecord> {
  CourseAnalyticsPracticeRecordsSubscription(Function() notifyChange)
      : super(
          'practiceRecords',
          (snapshot) => PracticeRecord.fromSnapshot(snapshot),
          notifyChange,
        );
}
