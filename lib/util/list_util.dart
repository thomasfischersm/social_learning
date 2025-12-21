
extension MaxBy<T> on Iterable<T> {
  T? maxByOrNull(int Function(T a, T b) compare) {
    T? best;

    for (final element in this) {
      if (best == null || compare(element, best) > 0) {
        best = element;
      }
    }
    return best;
  }
}