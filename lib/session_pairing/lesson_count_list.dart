
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/lesson_count_comparable.dart';
import 'package:social_learning/session_pairing/paired_session.dart';

/// A holder for all the lesson counts of a pairing. This makes it easier to
/// compare which offers the rarest lessons.
///
/// Later added note: I believe the counts are a list of numbers,
/// e.g 4, 3, 3, 1. They are how often a particular lesson has been graduated
/// from. We don't care about the particular lesson, but we care about ordering
/// the "rarest" lessons.
///
/// E.g. 3, 1 vs 2, 2 both has the same amount of graduations. However, 2, 2 is
/// preferred because it means that all lessons are known by at least 2 people.
class LessonCountList implements Comparable<LessonCountList> {
  PairedSession pairedSession;
  List<LessonCountComparable> counts = [];

  LessonCountList(this.pairedSession, List<Lesson> activeLessons,
      Map<Lesson, int> graduatedLessonCounts) {
    Map<int, LessonCountComparable> graduatedCountToComparable = {};
    for (Lesson lesson in activeLessons.toSet()) {
      int graduatedLessonCount = graduatedLessonCounts[lesson] ?? 0;
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
    for (int i = 0; i < counts.length && i < other.counts.length; i++) {
      if (counts[i].compareTo(other.counts[i]) != 0) {
        return counts[i].compareTo(other.counts[i]);
      }
    }

    // If one counts has an additional lesson, that's better.
    // Example: 3, 1, 1 is better than 3, 1.
    return counts.length.compareTo(other.counts.length);
  }
}