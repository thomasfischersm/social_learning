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

List<T> intersectAll<T>(List<List<T>> lists) {
  if (lists.isEmpty) return [];

  var result = lists.first.toSet();

  for (var i = 1; i < lists.length; i++) {
    result = result.intersection(lists[i].toSet());
  }

  return result.toList();
}

T? firstSharedByOrder<T>(List<List<T>> lists) {
  if (lists.isEmpty) return null;
  if (lists.any((l) => l.isEmpty)) return null;

  // 1) candidates = intersection of all lists
  var candidates = lists.first.toSet();
  for (int i = 1; i < lists.length; i++) {
    candidates = candidates.intersection(lists[i].toSet());
    if (candidates.isEmpty) return null;
  }

  // 2) pick earliest candidate in the preferred order (the first list’s order)
  for (final x in lists.first) {
    if (candidates.contains(x)) return x;
  }
  return null; // should be unreachable unless equality/hashCode is broken
}

extension ListSetOps<T> on List<T> {
  void forEachCombination(int k, void Function(List<T> tuple) visit) {
    if (k <= 0 || k > length) return;

    void rec(int start, List<T> acc) {
      if (acc.length == k) {
        visit(List<T>.unmodifiable(acc)); // or acc.toList() if you prefer
        return;
      }

      // Prune: not enough remaining items to reach k
      final needed = k - acc.length;
      for (int i = start; i <= length - needed; i++) {
        acc.add(this[i]);
        rec(i + 1, acc);
        acc.removeLast();
      }
    }

    rec(0, <T>[]);
  }

  void forEachMaxGroupings(
    int k,
    void Function(List<List<T>> groups, List<T> leftovers) visit,
  ) {
    final n = length;
    if (k <= 0) return;

    final used = List<bool>.filled(n, false);
    final groups = <List<T>>[];

    int firstUnused() {
      for (int i = 0; i < n; i++) {
        if (!used[i]) return i;
      }
      return -1;
    }

    void recurse() {
      final anchor = firstUnused();
      if (anchor == -1) {
        // No items left.
        visit(
          groups.map((g) => List<T>.unmodifiable(g)).toList(growable: false),
          const [],
        );
        return;
      }

      // Collect unused indices starting at anchor (keeps a canonical order).
      final remaining = <int>[];
      for (int i = anchor; i < n; i++) {
        if (!used[i]) remaining.add(i);
      }

      // If we can’t form another full group, whatever remains is leftovers.
      if (remaining.length < k) {
        final leftovers = <T>[for (final idx in remaining) this[idx]];
        visit(
          groups.map((g) => List<T>.unmodifiable(g)).toList(growable: false),
          leftovers,
        );
        return;
      }

      // Anchor must be in the next group to avoid duplicate groupings.
      used[anchor] = true;

      final partners = <int>[];

      void choosePartners(int startPos) {
        if (partners.length == k - 1) {
          // Commit this group.
          for (final p in partners) used[p] = true;
          groups.add(<T>[this[anchor], ...partners.map((i) => this[i])]);

          recurse();

          // Backtrack.
          groups.removeLast();
          for (final p in partners) used[p] = false;
          return;
        }

        final need = (k - 1) - partners.length;
        for (int pos = startPos; pos <= remaining.length - need; pos++) {
          final idx = remaining[pos]; // note: remaining[0] is anchor itself
          if (used[idx]) continue;
          partners.add(idx);
          choosePartners(pos + 1);
          partners.removeLast();
        }
      }

      choosePartners(1); // start after anchor in remaining[]

      used[anchor] = false;
    }

    recurse();
  }

  List<T> minus(Iterable<T> other) {
    final remove = other.toSet();
    return where((e) => !remove.contains(e)).toList();
  }
}
