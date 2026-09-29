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
    if (token.isLiteral && (index == 0 || !tokens[index - 1].isLiteral)) {
      final (key, end) = _literalSequence(tokens, index)!;
      if (end + 2 < tokens.length &&
          tokens[end].value == '.' &&
          _isTranslationCall(tokens[end + 1]) &&
          tokens[end + 2].value == '(') {
        usedKeys.add(key);
      }
    }
    if (_isTranslationCall(token) &&
        index + 1 < tokens.length &&
        tokens[index + 1].value == '(') {
      final argument = _literalSequence(tokens, index + 2);
      if (argument != null) {
        final (key, end) = argument;
        if (end < tokens.length &&
            (tokens[end].value == ',' || tokens[end].value == ')')) {
          usedKeys.add(key);
        }
      }
    }
  }
}

bool _isTranslationCall(_Token token) =>
    !token.isString && (token.value == 'tr' || token.value == 'plural');

(String, int)? _literalSequence(List<_Token> tokens, int start) {
  if (start >= tokens.length || !tokens[start].isLiteral) return null;
  final key = StringBuffer();
  var end = start;
  while (end < tokens.length && tokens[end].isLiteral) {
    key.write(tokens[end].value);
    end++;
  }
  return (key.toString(), end);
}

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
      final interpolations = <List<_Token>>[];
      var hasInterpolation = false;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source.startsWith(r'${', index)) {
          final end = _interpolationEnd(source, index);
          if (end != null) {
            hasInterpolation = true;
            interpolations.add(_tokenize(source.substring(index + 2, end)));
            index = end + 1;
            continue;
          }
        }
        if (!rawString && source[index] == '\\') {
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
      final value = source.substring(start, end);
      tokens.add((
        value: rawString ? value : _decodeDartString(value),
        isString: true,
        isLiteral: !hasInterpolation,
      ));
      for (final expression in interpolations) {
        tokens.add((value: ';', isString: false, isLiteral: false));
        tokens.addAll(expression);
        tokens.add((value: ';', isString: false, isLiteral: false));
      }
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

String _decodeDartString(String value) {
  final decoded = StringBuffer();
  var index = 0;
  while (index < value.length) {
    if (value[index] != '\\' || index + 1 >= value.length) {
      decoded.write(value[index++]);
      continue;
    }
    final escape = value[index + 1];
    if (escape == 'u' || escape == 'x') {
      final braced = escape == 'u' &&
          index + 2 < value.length &&
          value[index + 2] == '{';
      final start = index + (braced ? 3 : 2);
      final end = braced
          ? value.indexOf('}', start)
          : start + (escape == 'u' ? 4 : 2);
      if (end >= start && end <= value.length) {
        final codePoint = int.tryParse(value.substring(start, end), radix: 16);
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
        (source[index + 1] == "'" || source[index + 1] == '"') &&
        (index == 0 || !_isIdentifierPart(source.codeUnitAt(index - 1)));
    if (rawString) character = source[++index];
    if (character == "'" || character == '"') {
      final tripleQuote = '$character$character$character';
      final delimiter = source.startsWith(tripleQuote, index)
          ? tripleQuote
          : character;
      index += delimiter.length;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source[index] == '\\') index++;
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
