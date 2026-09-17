/// Returns whether [query] matches one of the provided searchable values.
bool matchesToolsSearch(String query, Iterable<String?> values) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return values.any(
    (value) => value?.toLowerCase().contains(normalizedQuery) ?? false,
  );
}
