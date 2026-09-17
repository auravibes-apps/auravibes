/// Search helpers shared by workspace and conversation tool lists.
abstract final class ToolsSearch {
  /// Returns whether [query] matches one of the provided searchable values.
  static bool matches(String query, Iterable<String?> values) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return values.any(
      (value) => value?.toLowerCase().contains(normalizedQuery) ?? false,
    );
  }
}
