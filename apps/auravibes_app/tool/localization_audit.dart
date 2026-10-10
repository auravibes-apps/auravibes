import 'dart:convert';
import 'dart:io';

extension on String {
  String _slice(int start, int end) =>
      String.fromCharCodes(codeUnits.getRange(start, end));
}

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
    final symbol = match.group(1);
    final path = match.group(2);
    if (symbol == null || path == null) continue;
    generatedKeys[symbol] = path;
  }

  final usedKeys = <String>{};
  final sourceFiles =
      sourceDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in sourceFiles) {
    _collectUsedKeys(file.readAsStringSync(), generatedKeys, usedKeys);
  }

  final localeFiles =
      translationsDir
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

/// Reports nested catalog paths missing from any supported locale.
List<String> findLocaleKeyParityIssues({required Directory translationsDir}) {
  final catalogs = _loadLocaleCatalogs(translationsDir);
  final allKeys =
      catalogs.values.expand((catalog) => catalog.keys).toSet().toList()
        ..sort();
  final issues = <String>[];
  for (final locale in catalogs.keys.toList()..sort()) {
    for (final key in allKeys) {
      if (!catalogs[locale]!.keys.contains(key)) {
        issues.add('$locale: $key (missing catalog key)');
      }
    }
  }

  return issues;
}

/// Compares named and positional placeholders across matching locale entries.
List<String> findPlaceholderMismatches({required Directory translationsDir}) {
  final catalogs = _loadLocaleCatalogs(translationsDir);
  if (catalogs.length < 2) return const [];

  final locales = catalogs.keys.toList()..sort();
  final pluralBranches = <String, Set<String>>{};
  for (final catalog in catalogs.values) {
    for (final key in catalog.translations.keys) {
      final branch = _pluralBranch(key);
      if (branch == null) continue;
      pluralBranches.putIfAbsent(branch.key, () => {}).addAll([branch.branch]);
    }
  }

  final issues = <String>[];
  for (final entry in pluralBranches.entries) {
    final key = entry.key;
    for (final locale in locales) {
      final catalog = catalogs[locale]!;
      for (final branch in entry.value.toList()..sort()) {
        final branchKey = '$key.$branch';
        final translation = catalog.translations[branchKey];
        if (translation == null) {
          issues.add('$locale: $key [branch: $branch] (missing plural branch)');
          continue;
        }
        final referenceLocale = locales.firstWhere(
          (candidate) =>
              catalogs[candidate]!.translations.containsKey(branchKey),
        );
        if (referenceLocale == locale) continue;
        final reference = catalogs[referenceLocale]!.translations[branchKey]!;
        final mismatch = _placeholderMismatch(
          locale: locale,
          key: key,
          branch: branch,
          expected: reference,
          actual: translation,
        );
        if (mismatch != null) issues.add(mismatch);
      }
    }
  }

  final allKeys =
      catalogs.values
          .expand((catalog) => catalog.translations.keys)
          .toSet()
          .where((key) => _pluralBranch(key) == null)
          .toList()
        ..sort();
  for (final key in allKeys) {
    final referenceLocale = locales.firstWhere(
      (locale) => catalogs[locale]!.translations.containsKey(key),
    );
    final reference = catalogs[referenceLocale]!.translations[key]!;
    for (final locale in locales) {
      if (locale == referenceLocale) continue;
      final translation = catalogs[locale]!.translations[key];
      if (translation == null) continue;
      final mismatch = _placeholderMismatch(
        locale: locale,
        key: key,
        expected: reference,
        actual: translation,
      );
      if (mismatch != null) issues.add(mismatch);
    }
  }

  return issues;
}

typedef _LocaleCatalog = ({Set<String> keys, Map<String, String> translations});

Map<String, _LocaleCatalog> _loadLocaleCatalogs(Directory translationsDir) {
  final files =
      translationsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final catalogs = <String, _LocaleCatalog>{};
  for (final file in files) {
    final locale = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final keys = <String>{};
    final translations = <String, String>{};
    _collectCatalogEntries(data, '', keys, translations);
    catalogs[locale] = (keys: keys, translations: translations);
  }

  return catalogs;
}

void _collectCatalogEntries(
  Map<String, dynamic> values,
  String prefix,
  Set<String> keys,
  Map<String, String> translations,
) {
  for (final entry in values.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    keys.addAll([key]);
    if (entry.value case final String value) {
      translations[key] = value;
    } else if (entry.value case final Map<String, dynamic> children) {
      _collectCatalogEntries(children, key, keys, translations);
    }
  }
}

const _pluralBranchNames = {'zero', 'one', 'two', 'few', 'many', 'other'};

({String key, String branch})? _pluralBranch(String key) {
  final separator = key.lastIndexOf('.');
  if (separator < 1) return null;
  final branch = key._slice(separator + 1, key.length);
  if (!_pluralBranchNames.contains(branch)) return null;

  return (key: key._slice(0, separator), branch: branch);
}

String? _placeholderMismatch({
  required String locale,
  required String key,
  required String expected,
  required String actual,
  String? branch,
}) {
  final expectedPositionals = RegExp(r'\{\}').allMatches(expected).length;
  final actualPositionals = RegExp(r'\{\}').allMatches(actual).length;
  final expectedNamed = _namedPlaceholders(expected);
  final actualNamed = _namedPlaceholders(actual);
  final differences = <String>[];
  if (!_setsEqual(expectedNamed, actualNamed)) {
    differences.add(
      'named placeholders: expected ${_formatPlaceholderSet(expectedNamed)}, '
      'found ${_formatPlaceholderSet(actualNamed)}',
    );
  }
  if (expectedPositionals != actualPositionals) {
    differences.add(
      'positional placeholders: expected $expectedPositionals, '
      'found $actualPositionals',
    );
  }
  if (differences.isEmpty) return null;
  final location = branch == null ? key : '$key [branch: $branch]';

  return '$locale: $location (${differences.join('; ')})';
}

Set<String> _namedPlaceholders(String text) => {
  for (final match in RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}').allMatches(text))
    if (match.group(1) case final String placeholder) placeholder,
};

bool _setsEqual(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

String _formatPlaceholderSet(Set<String> values) =>
    '{${(values.toList()..sort()).join(', ')}}';

typedef _Token = ({
  String value,
  bool isString,
  bool isLiteral,
  bool followsString,
});

const _singleQuoteCodeUnit = 0x27;

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
      usedKeys.addAll([key]);
    }
    if (token.isLiteral && !token.followsString) {
      final receiver = _literalSequence(tokens, index);
      if (receiver != null &&
          receiver.end + 2 < tokens.length &&
          tokens[receiver.end].value == '.' &&
          _isTranslationCall(tokens[receiver.end + 1]) &&
          tokens[receiver.end + 2].value == '(') {
        usedKeys.addAll([receiver.key]);
      }
    }
    if (_isTranslationCall(token) &&
        index + 1 < tokens.length &&
        tokens[index + 1].value == '(') {
      final argument = _literalSequence(tokens, index + 2);
      if (argument != null) {
        if (argument.end < tokens.length &&
            (tokens[argument.end].value == ',' ||
                tokens[argument.end].value == ')')) {
          usedKeys.addAll([argument.key]);
        }
      }
    }
  }
}

bool _isTranslationCall(_Token token) =>
    !token.isString && (token.value == 'tr' || token.value == 'plural');

({String key, int end})? _literalSequence(List<_Token> tokens, int start) {
  if (start >= tokens.length || !tokens[start].isLiteral) return null;
  final key = StringBuffer();
  var end = start;
  while (end < tokens.length &&
      tokens[end].isLiteral &&
      (end == start || tokens[end].followsString)) {
    key.write(tokens[end].value);
    end++;
  }

  return (key: key.toString(), end: end);
}

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var index = 0;
  var previousWasString = false;
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
        (source.codeUnitAt(index + 1) == _singleQuoteCodeUnit ||
            source[index + 1] == '"') &&
        (index == 0 || !_isIdentifierPart(source.codeUnitAt(index - 1)));
    if (rawString ||
        character.codeUnitAt(0) == _singleQuoteCodeUnit ||
        character == '"') {
      if (rawString) index++;
      final quote = source[index];
      final tripleQuote = '$quote$quote$quote';
      final triple = source.startsWith(tripleQuote, index);
      final delimiter = triple ? tripleQuote : quote;
      index += delimiter.length;
      final start = index;
      final interpolations = <List<_Token>>[];
      var hasInterpolation = false;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source.startsWith(r'${', index)) {
          final end = _interpolationEnd(source, index);
          if (end != null) {
            hasInterpolation = true;
            interpolations.add(_tokenize(source._slice(index + 2, end)));
            index = end + 1;
            continue;
          }
        }
        if (!rawString && source[index] == r'\') {
          index += 2;
          continue;
        }
        if (!rawString &&
            source[index] == r'$' &&
            index + 1 < source.length &&
            _isIdentifierStart(source.codeUnitAt(index + 1))) {
          hasInterpolation = true;
        }
        index++;
      }
      final end = index < source.length ? index : source.length;
      final value = source._slice(start, end);
      tokens.add((
        value: rawString ? value : _decodeDartString(value),
        isString: true,
        isLiteral: !hasInterpolation,
        followsString: previousWasString,
      ));
      const boundary = (
        value: ';',
        isString: false,
        isLiteral: false,
        followsString: false,
      );
      for (final expression in interpolations) {
        tokens.addAll([boundary, ...expression, boundary]);
      }
      previousWasString = true;
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
        value: source._slice(start, index),
        isString: false,
        isLiteral: false,
        followsString: false,
      ));
      previousWasString = false;
      continue;
    }
    if (character.trim().isNotEmpty) {
      tokens.add((
        value: character,
        isString: false,
        isLiteral: false,
        followsString: false,
      ));
      previousWasString = false;
    }
    index++;
  }

  return tokens;
}

String _decodeDartString(String value) {
  final decoded = StringBuffer();
  var index = 0;
  while (index < value.length) {
    if (value[index] != r'\' || index + 1 >= value.length) {
      decoded.write(value[index++]);
      continue;
    }
    final escape = value[index + 1];
    if (escape == 'u' || escape == 'x') {
      final hasBrace = index + 2 < value.length && value[index + 2] == '{';
      final braced = escape == 'u' && hasBrace;
      final start = index + (braced ? 3 : 2);
      final width = escape == 'u' ? 4 : 2;
      final end = braced ? value.indexOf('}', start) : start + width;
      if (end >= start && end <= value.length) {
        final codePoint = int.tryParse(value._slice(start, end), radix: 16);
        if (codePoint != null && codePoint <= 0x10ffff) {
          decoded.write(String.fromCharCode(codePoint));
          index = end + (braced ? 1 : 0);
          continue;
        }
      }
    }
    decoded.write(switch (escape) {
      'n' => '\n',
      'r' => '\r',
      't' => '\t',
      'b' => '\b',
      'f' => '\f',
      'v' => '\u000B',
      _ => escape,
    });
    index += 2;
  }

  return decoded.toString();
}

int? _interpolationEnd(String source, int start) {
  var depth = 1;
  var index = start + 2;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index + 2);
      index = end < 0 ? source.length : end;
      continue;
    }
    if (source.startsWith('/*', index)) {
      var commentDepth = 1;
      index += 2;
      while (index < source.length && commentDepth > 0) {
        if (source.startsWith('/*', index)) {
          commentDepth++;
          index += 2;
        } else if (source.startsWith('*/', index)) {
          commentDepth--;
          index += 2;
        } else {
          index++;
        }
      }
      continue;
    }
    var character = source[index];
    final rawString =
        (character == 'r' || character == 'R') &&
        index + 1 < source.length &&
        (source.codeUnitAt(index + 1) == _singleQuoteCodeUnit ||
            source[index + 1] == '"') &&
        (index == 0 || !_isIdentifierPart(source.codeUnitAt(index - 1)));
    if (rawString) character = source[++index];
    if (character.codeUnitAt(0) == _singleQuoteCodeUnit || character == '"') {
      final tripleQuote = '$character$character$character';
      final delimiter = source.startsWith(tripleQuote, index)
          ? tripleQuote
          : character;
      index += delimiter.length;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source[index] == r'\') index++;
        index++;
      }
      index += delimiter.length;
      continue;
    }
    if (character == '{') depth++;
    if (character == '}' && --depth == 0) return index;
    index++;
  }

  return null;
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
    keys.addAll([key]);
    if (entry.value case final Map<String, dynamic> children) {
      _collectKeys(children, key, keys);
    }
  }
}

void main() {
  final appDir = File.fromUri(Platform.script).parent.parent;
  final translationsDir = Directory('${appDir.path}/assets/i18n');
  final missing = findMissingTranslations(
    translationsDir: translationsDir,
    sourceDir: .new('${appDir.path}/lib'),
    localeKeysFile: .new('${appDir.path}/lib/i18n/locale_keys.dart'),
  );
  for (final entry in missing.entries) {
    for (final key in entry.value) {
      stdout.writeln('${entry.key}: $key');
      exitCode = 1;
    }
  }
  for (final issue in findLocaleKeyParityIssues(
    translationsDir: translationsDir,
  )) {
    stdout.writeln('Catalog key parity: $issue');
    exitCode = 1;
  }
  for (final issue in findPlaceholderMismatches(
    translationsDir: translationsDir,
  )) {
    stdout.writeln('Placeholder mismatch: $issue');
    exitCode = 1;
  }
  if (exitCode == 0) {
    stdout.writeln(
      'Localization audit passed (referenced keys, '
      'catalog parity, placeholders).',
    );
  }
}
