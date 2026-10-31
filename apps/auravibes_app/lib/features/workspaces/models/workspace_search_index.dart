import 'package:unorm_dart/unorm_dart.dart';

final _combiningMarks = RegExp(r'\p{M}', unicode: true);

/// Folds accents and compatibility characters for workspace name matching.
String normalizeWorkspaceSearch(String value) =>
    nfkd(value).replaceAll(_combiningMarks, '').toLowerCase();

/// A workspace-name snapshot that reuses normalized names across searches.
class WorkspaceSearchIndex<T> {
  WorkspaceSearchIndex(
    Iterable<T> items, {
    required String Function(T) nameOf,
    required String Function(T) idOf,
  }) : _nameOf = nameOf,
       _idOf = idOf,
       _entries = List.unmodifiable([
         for (final item in items)
           WorkspaceSearchEntry<T>(
             item: item,
             name: nameOf(item),
             stableId: idOf(item),
           ),
       ]);

  final String Function(T) _nameOf;
  final String Function(T) _idOf;
  final List<WorkspaceSearchEntry<T>> _entries;

  /// Returns whether [items] still match the exact snapshot indexed here.
  ///
  /// Name and ID comparisons also catch mutation in API-owned objects whose
  /// identity remains stable. Immutable workspace entities are cheap identity
  /// checks, while workspace membership and order are checked by iteration.
  bool hasSameItems(Iterable<T> items) {
    final iterator = items.iterator;
    for (final entry in _entries) {
      if (!iterator.moveNext()) return false;
      final item = iterator.current;
      if (!identical(entry.item, item) ||
          entry.sourceName != _nameOf(item) ||
          entry.stableId != _idOf(item)) {
        return false;
      }
    }

    return !iterator.moveNext();
  }

  /// Filters entries by a query already normalized with
  /// [normalizeWorkspaceSearch].
  List<WorkspaceSearchEntry<T>> matching(String normalizedQuery) => [
    for (final entry in _entries)
      if (normalizedQuery.isEmpty ||
          entry.normalizedName.contains(normalizedQuery))
        entry,
  ];

  /// Filters and sorts using the names and stable IDs captured at construction.
  List<WorkspaceSearchEntry<T>> search(
    String normalizedQuery, {
    bool descending = false,
  }) {
    final matches = matching(normalizedQuery);
    _sort(matches, descending: descending);
    return matches;
  }

  /// Sorts a filtered set without normalizing names inside comparator calls.
  List<WorkspaceSearchEntry<T>> sort(
    Iterable<WorkspaceSearchEntry<T>> entries, {
    bool descending = false,
  }) {
    final sorted = List<WorkspaceSearchEntry<T>>.of(entries);
    _sort(sorted, descending: descending);
    return sorted;
  }

  void _sort(
    List<WorkspaceSearchEntry<T>> entries, {
    required bool descending,
  }) {
    entries.sort((left, right) {
      final nameComparison = left.sortName.compareTo(right.sortName);
      final comparison = nameComparison != 0
          ? nameComparison
          : left.stableId.compareTo(right.stableId);

      return descending ? -comparison : comparison;
    });
  }
}

/// An item plus the name keys calculated once when a search index is built.
class WorkspaceSearchEntry<T> {
  WorkspaceSearchEntry({
    required this.item,
    required String name,
    required this.stableId,
  }) : sourceName = name,
       normalizedName = normalizeWorkspaceSearch(name),
       sortName = name.toLowerCase();

  final T item;
  final String sourceName;
  final String normalizedName;
  final String sortName;
  final String stableId;
}
