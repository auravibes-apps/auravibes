import 'dart:convert';
import 'dart:io';

Map<String, Set<String>> findMissingTranslations({
  required Directory translationsDir,
  required Directory sourceDir,
  required File localeKeysFile,
}) {
  final generatedKeys = <String, String>{};
  final declaration = RegExp(
    r'''static\s+const\s+(\w+)\s*=\s*['"]([^'"]+)['"]\s*;''',
  );
  final declarations = localeKeysFile.readAsStringSync();
  for (final match in declaration.allMatches(declarations)) {
    generatedKeys[match.group(1)!] = match.group(2)!;
  }

  final usedKeys = <String>{};
  final sourceFiles = sourceDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in sourceFiles) {
    _collectUsedKeys(file.readAsStringSync(), generatedKeys, usedKeys);
  }

  final localeFiles = translationsDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final missing = <String, Set<String>>{};
  for (final file in localeFiles) {
    final locale = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );
    final translations =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final availableKeys = <String>{};
    _collectKeys(translations, '', availableKeys);
    missing[locale] = {
      for (final key in usedKeys.toList()..sort())
        if (!availableKeys.contains(key)) key,
    };
  }
  return missing;
}

typedef _Token = ({String value, bool isString, bool isLiteral});

void _collectUsedKeys(
  String source,
  Map<String, String> generatedKeys,
  Set<String> usedKeys,
) {
  final tokens = _tokenize(source);
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    if (token.value == 'LocaleKeys' &&
        !token.isString &&
        index + 2 < tokens.length &&
        tokens[index + 1].value == '.' &&
        !tokens[index + 2].isString) {
      final symbol = tokens[index + 2].value;
      final key = generatedKeys[symbol];
      if (key == null) {
        throw StateError('Unknown LocaleKeys symbol: $symbol');
      }
      usedKeys.add(key);
    }
    if (token.isLiteral &&
        index + 3 < tokens.length &&
        tokens[index + 1].value == '.' &&
        _isTranslationCall(tokens[index + 2]) &&
        tokens[index + 3].value == '(') {
      usedKeys.add(token.value);
    }
    if (_isTranslationCall(token) &&
        index + 2 < tokens.length &&
        tokens[index + 1].value == '(' &&
        tokens[index + 2].isLiteral) {
      usedKeys.add(tokens[index + 2].value);
    }
  }
}

bool _isTranslationCall(_Token token) =>
    !token.isString && (token.value == 'tr' || token.value == 'plural');

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index + 2);
      index = end < 0 ? source.length : end;
      continue;
    }
    if (source.startsWith('/*', index)) {
      var depth = 1;
      index += 2;
      while (index < source.length && depth > 0) {
        if (source.startsWith('/*', index)) {
          depth++;
          index += 2;
        } else if (source.startsWith('*/', index)) {
          depth--;
          index += 2;
        } else {
          index++;
        }
      }
      continue;
    }
    final character = source[index];
    final rawString =
        (character == 'r' || character == 'R') &&
        index + 1 < source.length &&
        (source[index + 1] == "'" || source[index + 1] == '"') &&
        (index == 0 || !_isIdentifierPart(source.codeUnitAt(index - 1)));
    if (rawString || character == "'" || character == '"') {
      if (rawString) index++;
      final quote = source[index];
      final tripleQuote = '$quote$quote$quote';
      final triple = source.startsWith(tripleQuote, index);
      final delimiter = triple ? tripleQuote : quote;
      index += delimiter.length;
      final start = index;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source[index] == '\\') index++;
        index++;
      }
      final end = index < source.length ? index : source.length;
      final value = source.substring(start, end);
      tokens.add((
        value: value,
        isString: true,
        isLiteral: rawString || !value.contains(r'$'),
      ));
      index += delimiter.length;
      continue;
    }
    final code = source.codeUnitAt(index);
    if (_isIdentifierStart(code)) {
      final start = index++;
      while (index < source.length &&
          _isIdentifierPart(source.codeUnitAt(index))) {
        index++;
      }
      tokens.add((
        value: source.substring(start, index),
        isString: false,
        isLiteral: false,
      ));
      continue;
    }
    if (character.trim().isNotEmpty) {
      tokens.add((value: character, isString: false, isLiteral: false));
    }
    index++;
  }
  return tokens;
}

bool _isIdentifierStart(int code) =>
    code == 95 || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);

bool _isIdentifierPart(int code) =>
    _isIdentifierStart(code) || (code >= 48 && code <= 57);

void _collectKeys(
  Map<String, dynamic> values,
  String prefix,
  Set<String> keys,
) {
  for (final entry in values.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    keys.add(key);
    if (entry.value case final Map<String, dynamic> children) {
      _collectKeys(children, key, keys);
    }
  }
}

void main() {
  final appDir = File.fromUri(Platform.script).parent.parent;
  final missing = findMissingTranslations(
    translationsDir: Directory('${appDir.path}/assets/i18n'),
    sourceDir: Directory('${appDir.path}/lib'),
    localeKeysFile: File('${appDir.path}/lib/i18n/locale_keys.dart'),
  );
  for (final entry in missing.entries) {
    for (final key in entry.value) {
      stdout.writeln('${entry.key}: $key');
      exitCode = 1;
    }
  }
  if (exitCode == 0) {
    stdout.writeln('No missing translations.');
  }
}
