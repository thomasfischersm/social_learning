import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:social_learning/state/library_state.dart';

class PracticeRecordsSubscription
    extends FirestoreListSubscription<PracticeRecord> {
  final LibraryState _libraryState;
  Map<User, List<Lesson>> _userToGraduatedLessons = {};

  PracticeRecordsSubscription(Function() notifyChange, this._libraryState)
      : super(
          'practiceRecords',
          (snapshot) => PracticeRecord.fromSnapshot(snapshot),
          notifyChange,
        );

  @override
  postProcess(List<PracticeRecord> items) {
    _userToGraduatedLessons = {};
  }

  List<Lesson> getGraduatedLessons(User user) {
    // Check if this is cached
    if (_userToGraduatedLessons.containsKey(user)) {
      return _userToGraduatedLessons[user]!;
    }

    List<Lesson> graduatedLessons = [];

    for (PracticeRecord practiceRecord in items) {
      if (practiceRecord.menteeUid == user.uid) {
        Lesson? lesson = _libraryState.findLesson(practiceRecord.lessonId.id);
        if (lesson != null) {
          graduatedLessons.add(lesson);
        }
      }
    }

    _userToGraduatedLessons[user] = List.from(graduatedLessons);

    return graduatedLessons;
  }
}
