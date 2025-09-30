
import 'package:social_learning/data/practice_record.dart';
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
