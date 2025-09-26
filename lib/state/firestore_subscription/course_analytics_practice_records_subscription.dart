import 'dart:async';

import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class CourseAnalyticsPracticeRecordsSubscription
    extends FirestoreListSubscription<PracticeRecord> {
  CourseAnalyticsPracticeRecordsSubscription(
    Function() notifyChange,
    this._onRecordsChanged,
  ) : super(
          'practiceRecords',
          (snapshot) => PracticeRecord.fromSnapshot(snapshot),
          notifyChange,
        );

  final void Function(List<PracticeRecord>) _onRecordsChanged;
  Completer<void>? _readyCompleter;

  Future<void> listenForCourseAndMentees(
    Course course,
    List<String> menteeUids,
  ) {
    if (menteeUids.isEmpty) {
      return cancelAndClear();
    }

    _readyCompleter = Completer<void>();
    super.resubscribe(
      (collection) =>
          PracticeRecordFunctions.practiceRecordsForCourseAndMenteesQuery(
        collection,
        course,
        menteeUids,
      ),
    );
    return _readyCompleter!.future;
  }

  Future<void> cancelAndClear() async {
    _onRecordsChanged(const []);
    await super.cancel();
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
    }
    _readyCompleter = null;
  }

  @override
  void postProcess(List<PracticeRecord> items) {
    _onRecordsChanged(List<PracticeRecord>.unmodifiable(items));
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
    }
    super.postProcess(items);
  }

  @override
  Future<void> cancel() async {
    await cancelAndClear();
  }
}
