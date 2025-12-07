/// Extension methods for String manipulation.
extension StringExtensions on String {
  /// Converts an identifier (snake_case, camelCase, kebab-case, or mixed)
  /// to a human-readable format with proper capitalization.
  ///
  /// Examples:
  /// - `read_file` -> `Read File`
  /// - `readFile` -> `Read File`
  /// - `read-file` -> `Read File`
  /// - `READ_FILE` -> `Read File`
  /// - `my_server` -> `My Server`
  /// - `MyServer` -> `My Server`
  String toHumanReadable() {
    if (isEmpty) return this;

    // First, insert spaces before uppercase letters (for camelCase/PascalCase)
    final withSpaces = replaceAllMapped(
      RegExp('([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Replace underscores and hyphens with spaces
    final normalized = withSpaces.replaceAll(RegExp('[_-]+'), ' ');

    // Split into words, capitalize each, and join
    final words = normalized.split(RegExp(r'\s+'));
    final capitalizedWords = words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase());

    return capitalizedWords.join(' ');
  }
}
