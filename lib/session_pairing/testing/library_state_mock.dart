import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/reference_helper.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class LibraryStateMock extends LibraryState {
  final List<Lesson> _lessons = [];

  LibraryStateMock(int lessonCount) : super(ApplicationState()) {
    for (int i = 0; i < lessonCount; i++) {
      String id = '${i + 1000}';
      _lessons.add(Lesson(
          id,
          docRef('courses', '0'),
          docRef('levels', '0'),
          i + 1000,
          'Lesson $id',
          'synopsis',
          'instructions',
          null,
          null,
          null,
          null,
          null,
          false,
          '0',
          null));
    }
  }

  @override
  get lessons => _lessons;
}
