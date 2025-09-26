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

  final List<User> _courseUsers = [];
  final List<PracticeRecord> _practiceRecords = [];

  CourseAnalyticsUsersSubscription? _userSubscription;
  CourseAnalyticsPracticeRecordsSubscription? _practiceRecordSubscription;

  Future<void>? _initializationFuture;
  Timer? _disposeTimer;
  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _hasAccess = false;
  String? _activeCourseId;
  bool _isDisposed = false;
  int _generation = 0;

  CourseAnalyticsState(this._applicationState, this._libraryState) {
    _libraryState.addListener(_handleLibraryStateChange);
  }

  bool get hasAccess => _hasAccess;
  bool get isInitialized => _isInitialized;

  Future<UnmodifiableListView<User>> getCourseUsers() async {
    await ensureInitialized();
    return UnmodifiableListView<User>(_courseUsers);
  }

  Future<UnmodifiableListView<PracticeRecord>> getPracticeRecords() async {
    await ensureInitialized();
    return UnmodifiableListView<PracticeRecord>(_practiceRecords);
  }

  Future<void> ensureInitialized() {
    if (_isDisposed) {
      return Future.error(
        StateError('CourseAnalyticsState has been disposed.'),
      );
    }

    if (_isInitialized) {
      return Future.value();
    }

    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    final int generation = _generation;
    _initializationFuture = _initialize(generation);
    return _initializationFuture!;
  }

  Future<void> _initialize(int generation) async {
    _isInitializing = true;
    try {
      final Course? course = _libraryState.selectedCourse;
      final User? user = await _applicationState.currentUserBlocking;

      if (generation != _generation) {
        return;
      }

      if (course == null || course.id == null || user == null) {
        await _resetState();
        _hasAccess = false;
        return;
      }

      final bool isCourseOwner = course.creatorId == user.uid;
      _hasAccess = user.isAdmin || isCourseOwner;
      if (!_hasAccess) {
        await _resetState();
        _activeCourseId = course.id;
        return;
      }

      _activeCourseId = course.id;

      _userSubscription ??= CourseAnalyticsUsersSubscription(
        notifyListeners,
        _handleUsersChanged,
      );
      _practiceRecordSubscription ??=
          CourseAnalyticsPracticeRecordsSubscription(
        notifyListeners,
        _handlePracticeRecordsChanged,
      );

      await _userSubscription!.listenForCourse(course, _maxRecentUsers);
      if (generation != _generation) {
        return;
      }

      final List<String> menteeUids = _recentMenteeUids();
      await _practiceRecordSubscription!
          .listenForCourseAndMentees(course, menteeUids);
      if (generation != _generation) {
        return;
      }

      _isInitialized = true;
      _scheduleAutoDispose();
    } finally {
      if (generation == _generation) {
        _initializationFuture = null;
      }
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> deinitialize() async {
    _generation++;
    _disposeTimer?.cancel();
    _disposeTimer = null;

    await _resetState();

    _activeCourseId = null;
    _hasAccess = false;
    _isInitialized = false;
    _isInitializing = false;
    _initializationFuture = null;

    notifyListeners();
  }

  Future<void> signOut() {
    return deinitialize();
  }

  void _handleLibraryStateChange() {
    if (!_isInitialized) {
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

  void _handleUsersChanged(List<User> users) {
    if (_isDisposed) {
      return;
    }

    _courseUsers
      ..clear()
      ..addAll(users);

    if (_isInitializing || !_hasAccess) {
      return;
    }

    final Course? course = _libraryState.selectedCourse;
    if (course == null || course.id == null) {
      return;
    }

    unawaited(_practiceRecordSubscription
        ?.listenForCourseAndMentees(course, _recentMenteeUids()));
  }

  void _handlePracticeRecordsChanged(List<PracticeRecord> records) {
    if (_isDisposed) {
      return;
    }

    _practiceRecords
      ..clear()
      ..addAll(records);
  }

  List<String> _recentMenteeUids() {
    return _courseUsers
        .map((user) => user.uid)
        .where((uid) => uid.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _resetState() async {
    await _userSubscription?.cancel();
    await _practiceRecordSubscription?.cancel();
    _courseUsers.clear();
    _practiceRecords.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _libraryState.removeListener(_handleLibraryStateChange);
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _userSubscription?.cancel();
    _userSubscription = null;
    _practiceRecordSubscription?.cancel();
    _practiceRecordSubscription = null;
    super.dispose();
  }
}
