import 'package:characters/characters.dart';

/// Extension methods for String manipulation.
extension StringExtensions on String {
  /// Converts an identifier (snake_case, camelCase, kebab-case, or mixed).
  /// Converts it to a human-readable format with proper capitalization.
  ///
  /// Examples include `read_file`, `readFile`, `read-file`, and `READ_FILE`,
  /// which become `Read File`. The identifiers `my_server` and `MyServer`
  /// become `My Server`.
  String toHumanReadable() {
    if (isEmpty) return this;

    return _capitalizeWords(_normalizeIdentifier(this));
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
    const edgeCharacterCount = 2;
    final stringCharacters = characters;
    if (stringCharacters.length <= edgeCharacterCount) return '';

    return stringCharacters
        .skip(1)
        .take(stringCharacters.length - edgeCharacterCount)
        .toString();
  }
}

String _normalizeIdentifier(String value) {
  const firstGroup = 1;
  const secondGroup = 2;

  return value
      .replaceAllMapped(
        RegExp('([a-z])([A-Z])'),
        (match) => '${match.group(firstGroup)} ${match.group(secondGroup)}',
      )
      .replaceAll(RegExp('[_-]+'), ' ');
}

String _capitalizeWords(String value) => value
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map(_capitalizeWord)
    .join(' ');

String _capitalizeWord(String word) {
  final wordCharacters = word.characters;
  final firstCharacter = wordCharacters.take(1).toString().toUpperCase();
  final remainingCharacters = wordCharacters.skip(1).toString();

  return '$firstCharacter${remainingCharacters.toLowerCase()}';
}
