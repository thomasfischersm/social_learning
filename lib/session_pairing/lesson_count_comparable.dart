/// A Helper class to compare with pairing introduces rarer lessons.
class LessonCountComparable implements Comparable<LessonCountComparable> {
  int graduatedLessonCount;
  int activeLessonCount;

  LessonCountComparable(this.graduatedLessonCount, this.activeLessonCount);

  @override
  int compareTo(LessonCountComparable other) {
    if (graduatedLessonCount == other.graduatedLessonCount) {
      return activeLessonCount.compareTo(other.activeLessonCount);
    } else {
      return graduatedLessonCount.compareTo(other.graduatedLessonCount);
    }
  }
}