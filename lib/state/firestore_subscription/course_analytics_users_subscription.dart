import 'dart:async';

import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/firestore_subscription/course_analytics_practice_records_subscription.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseAnalyticsUsersSubscription extends FirestoreListSubscription<User> {
  final CourseAnalyticsPracticeRecordsSubscription _practiceRecordsSubscription;

  CourseAnalyticsUsersSubscription(
    this._practiceRecordsSubscription,
    Function() notifyChange,
  ) : super(
          'users',
          (snapshot) => User.fromSnapshot(snapshot),
          notifyChange,
        );

  @override
  postProcess(List<User> users) {
    List<String> uids = users.map<String>((User user) => user.uid).toList();

    _practiceRecordsSubscription.resubscribe((collectionReference) =>
        collectionReference.where(Filter.or(Filter('mentorUid', whereIn: uids),
            Filter('menteeUid', whereIn: uids))));
  }
}
