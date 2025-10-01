import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/firestore_subscription/course_analytics_practice_records_subscription.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseAnalyticsUsersSubscription extends FirestoreListSubscription<User> {
  final CourseAnalyticsPracticeRecordsSubscription _practiceRecordsSubscription;

  DocumentReference? _courseRef;

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
    print(
        'CourseAnalyticsUsersSubscription resubscribing for ${uids.length} uids and ${users.length} users');

    if (uids.isEmpty) {
      _practiceRecordsSubscription.cancel();
    } else {
      _practiceRecordsSubscription.resubscribe((collectionReference) =>
          collectionReference.where('courseId', isEqualTo: _courseRef).where(
              Filter.or(Filter('mentorUid', whereIn: uids),
                  Filter('menteeUid', whereIn: uids))));
    }
  }

  resubscribeWithCourseRef(DocumentReference courseRef, Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collectionReference)
  whereFunction) {
    _courseRef = courseRef;
    return super.resubscribe(whereFunction);
  }
}
