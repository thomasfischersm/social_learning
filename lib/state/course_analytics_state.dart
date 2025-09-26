import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/course_analytics_practice_records_subscription.dart';
import 'package:social_learning/state/firestore_subscription/course_analytics_users_subscription.dart';
import 'package:social_learning/state/library_state.dart';

class CourseAnalyticsState extends ChangeNotifier {
  static const int _maxRecentUsers = 30;
  static const Duration _autoDisposeDuration = Duration(hours: 1);

  final ApplicationState _applicationState;
  final LibraryState _libraryState;

  // final List<User> _courseUsers = [];
  final List<PracticeRecord> _practiceRecords = [];

  late CourseAnalyticsUsersSubscription _userSubscription;
  late CourseAnalyticsPracticeRecordsSubscription _practiceRecordSubscription;

  Future<void>? _initializationFuture;
  Timer? _disposeTimer;
  _CourseAnalyticsStatus _internalStatus = _CourseAnalyticsStatus.uninitialized;
  String? _activeCourseId;

  CourseAnalyticsState(this._applicationState, this._libraryState) {
    _practiceRecordSubscription =
        CourseAnalyticsPracticeRecordsSubscription(notifyListeners);
    _userSubscription = CourseAnalyticsUsersSubscription(
        _practiceRecordSubscription, notifyListeners);
    _libraryState.addListener(_handleLibraryStateChange);
  }

  Future<UnmodifiableListView<User>> getCourseUsers() async {
    await ensureInitialized();
    return UnmodifiableListView<User>(_userSubscription.items);
  }

  Future<UnmodifiableListView<PracticeRecord>> getPracticeRecords() async {
    await ensureInitialized();
    return UnmodifiableListView<PracticeRecord>(_practiceRecords);
  }

  Future<void> ensureInitialized() {
    if (_internalStatus == _CourseAnalyticsStatus.initialized) {
      return Future.value();
    }

    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializationFuture = _initialize();
    return _initializationFuture!;
  }

  Future<void> _initialize() async {
    _internalStatus = _CourseAnalyticsStatus.initializing;
    try {
      final Course? course = _libraryState.selectedCourse;

      if (course == null || course.id == null || ! await _hasAccess()) {
        return;
      }

      _activeCourseId = course.id;

      await _userSubscription.resubscribe((collection) => collection
          .where('enrolledCourseIds', arrayContains: course.id)
          .orderBy('lastActive', descending: true)
          .limit(_maxRecentUsers));

      _scheduleAutoDispose();
    } finally {
      _internalStatus = _CourseAnalyticsStatus.initialized;
      notifyListeners();
    }
  }

  Future<bool> _hasAccess() async {
    final Course? course = _libraryState.selectedCourse;
    if (course == null || course.id == null) {
      return false;
    }

    final User? user = await _applicationState.currentUserBlocking;
    return user != null && (user.isAdmin || course.creatorId == user.uid);
  }

  Future<void> deinitialize() async {
    _disposeTimer?.cancel();
    _disposeTimer = null;

    await _resetState();

    _activeCourseId = null;
    _internalStatus = _CourseAnalyticsStatus.uninitialized;
    _initializationFuture = null;

    notifyListeners();
  }

  Future<void> signOut() {
    return deinitialize();
  }

  void _handleLibraryStateChange() {
    if (_internalStatus != _CourseAnalyticsStatus.initialized) {
      return;
    }

    final String? selectedCourseId = _libraryState.selectedCourse?.id;
    if (selectedCourseId != _activeCourseId) {
      unawaited(deinitialize());
    }
  }

  void _scheduleAutoDispose() {
    _disposeTimer?.cancel();
    _disposeTimer = Timer(_autoDisposeDuration, () {
      unawaited(deinitialize());
    });
  }

  Future<void> _resetState() async {
    await _userSubscription.cancel();
    await _practiceRecordSubscription.cancel();
  }

  @override
  void dispose() {
    _libraryState.removeListener(_handleLibraryStateChange);
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _userSubscription.cancel();
    _practiceRecordSubscription.cancel();
    super.dispose();
  }
}

enum _CourseAnalyticsStatus {
  uninitialized,
  initializing,
  initialized,
}
