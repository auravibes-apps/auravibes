import 'package:characters/characters.dart';

/// Extension methods for String manipulation.
extension StringExtensions on String {
  /// Converts an identifier (snake_case, camelCase, kebab-case, or mixed).
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

    // First, insert spaces before uppercase letters (for camelCase/PascalCase).
    final withSpaces = replaceAllMapped(
      RegExp('([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Replace underscores and hyphens with spaces.
    final normalized = withSpaces.replaceAll(RegExp('[_-]+'), ' ');

    // Split into words, capitalize each, and join.
    final words = normalized.split(RegExp(r'\s+'));
    final capitalizedWords = words.where((word) => word.isNotEmpty).map((word) {
      final wordCharacters = word.characters;
      final firstCharacter = wordCharacters.take(1).toString().toUpperCase();
      final remainingCharacters = wordCharacters.skip(1).toString();

      return '$firstCharacter${remainingCharacters.toLowerCase()}';
    });

    return capitalizedWords.join(' ');
  }

  /// Returns the first [count] user-perceived characters.
  String firstCharacters(int count) {
    return characters.take(count).toString();
  }

  /// Returns the last [count] user-perceived characters.
  String lastCharacters(int count) {
    final stringCharacters = characters;
    if (stringCharacters.length <= count) return this;

    return stringCharacters.skip(stringCharacters.length - count).toString();
  }

  /// Truncates to [maxLength] user-perceived characters, including [suffix].
  String truncateCharacters(int maxLength, {String suffix = '...'}) {
    final stringCharacters = characters;
    if (stringCharacters.length <= maxLength) return this;

    final suffixLength = suffix.characters.length;
    final contentLength = maxLength - suffixLength;
    if (contentLength <= 0) {
      return suffix.characters.take(maxLength).toString();
    }

    return '${stringCharacters.take(contentLength)}$suffix';
  }

  /// Removes one user-perceived character from both ends.
  String withoutEdgeCharacters() {
    final stringCharacters = characters;
    if (stringCharacters.length <= 2) return '';

    return stringCharacters
        .skip(1)
        .take(stringCharacters.length - 2)
        .toString();
  }
}
