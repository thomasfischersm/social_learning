import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_in_clause_subscription.dart';
import 'package:social_learning/state/library_state.dart';

class CourseAnalyticsState extends ChangeNotifier {
  static const int _batchSize = 30 ~/ 2;
  static const int _maxSize = 5 * _batchSize;
  static const Duration _autoDisposeDuration = Duration(hours: 1);

  final ApplicationState _applicationState;
  final LibraryState _libraryState;

  late final FirestoreListInClausSubscription<User, PracticeRecord> _subscription;

  Future<void>? _initializationFuture;
  Timer? _disposeTimer;
  _CourseAnalyticsStatus _internalStatus = _CourseAnalyticsStatus.uninitialized;
  String? _activeCourseId;

  CourseAnalyticsState(this._applicationState, this._libraryState) {
    _subscription = FirestoreListInClausSubscription(
      'users',
      (snapshot) => User.fromSnapshot(snapshot),
      'practiceRecords',
        _resubscribeSecondarySubscriber,
      (snapshot) => PracticeRecord.fromSnapshot(snapshot),
      notifyListeners,
      batchSize: _batchSize,
      maxSize: _maxSize);

    _libraryState.addListener(_handleLibraryStateChange);
  }

  Future<UnmodifiableListView<User>> getCourseUsers() async {
    await ensureInitialized();
    return UnmodifiableListView<User>(_subscription.primaryItems);
  }

  Future<UnmodifiableListView<PracticeRecord>> getPracticeRecords() async {
    await ensureInitialized();
    return UnmodifiableListView<PracticeRecord>(
        _subscription.secondaryItems);
  }

  /// Returns practice records students minus the practice records that
  /// were created to bootstrap the instructor.
  Future<List<PracticeRecord>> getActualPracticeRecords() async {
    await ensureInitialized();

    return (await getPracticeRecords())
        .where((record) => record.menteeUid != record.mentorUid)
        .toList();
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

      if (course == null || course.id == null || !await _hasAccess()) {
        return;
      }

      _activeCourseId = course.id;
      DocumentReference courseRef =
          FirestoreService.instance.doc('/courses/${course.id}');

      await _subscription.resubscribe((collection) => collection
          .where('enrolledCourseIds', arrayContains: courseRef)
          .orderBy('lastLessonTimestamp', descending: true));

      _scheduleAutoDispose();
    } finally {
      _internalStatus = _CourseAnalyticsStatus.initialized;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Query<Map<String, dynamic>> _resubscribeSecondarySubscriber(CollectionReference<Map<String, dynamic>> collectionReference, List<User> primaryBatch) {
    List<String> uids = primaryBatch.map((user) => user.uid).toList();
    DocumentReference courseRef =
    FirestoreService.instance.doc('/courses/$_activeCourseId');

    return collectionReference
        .where('courseId', isEqualTo: courseRef).where(
        Filter.or(Filter('mentorUid', whereIn: uids),
            Filter('menteeUid', whereIn: uids)));
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
    await _subscription.cancel();
  }

  @override
  void dispose() {
    _libraryState.removeListener(_handleLibraryStateChange);
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _subscription.cancel();
    super.dispose();
  }
}

enum _CourseAnalyticsStatus {
  uninitialized,
  initializing,
  initialized,
}
