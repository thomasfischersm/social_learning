import 'dart:async';

import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class CourseAnalyticsUsersSubscription extends FirestoreListSubscription<User> {
  CourseAnalyticsUsersSubscription(
    Function() notifyChange,
    this._onUsersChanged,
  ) : super(
          'users',
          (snapshot) => User.fromSnapshot(snapshot),
          notifyChange,
        );

  final void Function(List<User>) _onUsersChanged;
  Completer<void>? _readyCompleter;

  Future<void> listenForCourse(Course course, int maxUsers) {
    _readyCompleter = Completer<void>();
    super.resubscribe(
      (collection) => UserFunctions.recentActiveUsersForCourseQuery(
        collection,
        course,
        maxUsers,
      ),
    );
    return _readyCompleter!.future;
  }

  @override
  void postProcess(List<User> items) {
    _onUsersChanged(List<User>.unmodifiable(items));
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
    }
    super.postProcess(items);
  }

  @override
  Future<void> cancel() async {
    await super.cancel();
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
    }
    _readyCompleter = null;
  }
}
