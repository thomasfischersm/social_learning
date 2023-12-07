
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/lesson_count_comparable.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';

/// A holder for all the lesson counts of a pairing. This makes it easier to
/// compare which offers the rarest lessons.
class LessonCountList implements Comparable<LessonCountList> {
  PairedSession pairedSession;
  List<LessonCountComparable> counts = [];

  LessonCountList(this.pairedSession, List<Lesson> activeLessons,
      Map<Lesson, int> graduatedLessonCounts) {
    Map<int, LessonCountComparable> graduatedCountToComparable = {};
    for (Lesson lesson in activeLessons.toSet()) {
      var graduatedLessonCount = graduatedLessonCounts[lesson] ?? 0;
      if (graduatedCountToComparable.containsKey(graduatedLessonCounts)) {
        LessonCountComparable comparable =
        graduatedCountToComparable[graduatedLessonCount]!;
        comparable.activeLessonCount++;
      } else {
        graduatedCountToComparable[graduatedLessonCount] =
            LessonCountComparable(graduatedLessonCount, 1);
      }
    }

    counts = graduatedCountToComparable.values.toList()..sort();
  }

  @override
  int compareTo(LessonCountList other) {
    for (int i = 0; i < counts.length; i++) {
      if (counts[i].compareTo(other.counts[i]) != 0) {
        return counts[i].compareTo(other.counts[i]);
      }
    }

    return 0;
  }
}