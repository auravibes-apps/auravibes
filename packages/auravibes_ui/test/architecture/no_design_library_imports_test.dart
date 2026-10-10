import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbiddenPackageUri = RegExp(
  r'^package:(?:material_ui|cupertino_ui)(?:/|$)',
);

void main() {
  test(
    'UI production code avoids Material and Cupertino package directives',
    () {
      final violations = <String>[];
      for (final file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (_hasForbiddenPackageDirective(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );

  test('boundary matcher handles comments and URI quote forms', () {
    final tripleSingleQuote = String.fromCharCodes([39, 39, 39]);
    for (final directive in [
      '''import /* comment */ 'package:material_ui/material_ui.dart';''',
      '''
export // comment
 'package:cupertino_ui/cupertino_ui.dart';''',
      '''import  'package:cupertino_ui/cupertino_ui.dart';''',
      '''import r'package:material_ui/material_ui.dart';''',
      '''export r"package:cupertino_ui/cupertino_ui.dart";''',
      'import r${tripleSingleQuote}package:material_ui/material_ui.dart$tripleSingleQuote;',
      'export r"""package:cupertino_ui/cupertino_ui.dart""";',
      'import """package:cupertino_ui/cupertino_ui.dart""";',
      'export """package:material_ui/material_ui.dart""";',
    ]) {
      expect(
        _hasForbiddenPackageDirective(directive),
        isTrue,
        reason: directive,
      );
    }
  });

  test('boundary matcher checks every conditional import and export URI', () {
    for (final directive in [
      '''import 'stub.dart' if (dart.library.io) 'package:material_ui/material_ui.dart';''',
      '''import 'stub.dart' if (dart.library.io) 'safe.dart' if (dart.library.html) 'package:cupertino_ui/cupertino_ui.dart';''',
      '''export 'stub.dart' if (dart.library.io) 'package:cupertino_ui/cupertino_ui.dart';''',
      '''export 'stub.dart' if (dart.library.io) 'safe.dart' if (dart.library.html) 'package:material_ui/material_ui.dart';''',
    ]) {
      expect(
        _hasForbiddenPackageDirective(directive),
        isTrue,
        reason: directive,
      );
    }
  });

  test('boundary matcher ignores ordinary string literals', () {
    final tripleSingleQuote = String.fromCharCodes([39, 39, 39]);
    for (final source in [
      '''final example = "import 'package:material_ui/material_ui.dart';";''',
      '''
final example = $tripleSingleQuote
import 'package:cupertino_ui/cupertino_ui.dart';
$tripleSingleQuote;''',
    ]) {
      expect(_hasForbiddenPackageDirective(source), isFalse, reason: source);
    }
  });
}

bool _hasForbiddenPackageDirective(String source) {
  final tokens = _tokenizeDart(source);
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    if (token.isStringLiteral ||
        (token.value != 'import' && token.value != 'export')) {
      continue;
    }

    for (var next = index + 1; next < tokens.length; next++) {
      final candidate = tokens[next];
      if (!candidate.isStringLiteral && candidate.value == ';') break;
      if (candidate.isStringLiteral &&
          _forbiddenPackageUri.hasMatch(candidate.value)) {
        return true;
      }
    }
  }

  return false;
}

List<_DartToken> _tokenizeDart(String source) {
  final tokens = <_DartToken>[];
  var index = 0;
  while (index < source.length) {
    final character = source[index];
    if (_isWhitespace(character)) {
      index++;
      continue;
    }

    if (source.startsWith('//', index)) {
      index = _skipLineComment(source, index + 2);
      continue;
    }
    if (source.startsWith('/*', index)) {
      index = _skipBlockComment(source, index + 2);
      continue;
    }

    var raw = false;
    if ((character == 'r' || character == 'R') &&
        index + 1 < source.length &&
        _isQuote(source[index + 1])) {
      raw = true;
      index++;
    }
    if (_isQuote(source[index])) {
      final parsed = _readString(source, index, raw: raw);
      tokens.add(_DartToken(value: parsed.value, isStringLiteral: true));
      index = parsed.end;
      continue;
    }

    if (_isIdentifierStart(character)) {
      final start = index++;
      while (index < source.length && _isIdentifierPart(source[index])) {
        index++;
      }
      tokens.add(
        _DartToken(
          value: String.fromCharCodes(source.codeUnits.getRange(start, index)),
        ),
      );
      continue;
    }

    tokens.add(_DartToken(value: character));
    index++;
  }

  return tokens;
}

({String value, int end}) _readString(
  String source,
  int start, {
  required bool raw,
}) {
  final quote = source[start];
  final isTriple =
      start + 2 < source.length &&
      source[start + 1] == quote &&
      source[start + 2] == quote;
  final delimiterLength = isTriple ? 3 : 1;
  final value = StringBuffer();
  var index = start + delimiterLength;

  while (index < source.length) {
    if (isTriple
        ? source.startsWith('$quote$quote$quote', index)
        : source[index] == quote) {
      return (value: value.toString(), end: index + delimiterLength);
    }
    if (!raw &&
        source[index].codeUnitAt(0) == 92 &&
        index + 1 < source.length) {
      value.write(source[index + 1]);
      index += 2;
      continue;
    }
    value.write(source[index]);
    index++;
  }

  return (value: value.toString(), end: source.length);
}

int _skipLineComment(String source, int start) {
  var index = start;
  while (index < source.length && source[index] != '\n') {
    index++;
  }

  return index;
}

int _skipBlockComment(String source, int start) {
  var index = start;
  var depth = 1;
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

  return index;
}

bool _isQuote(String character) =>
    character.codeUnitAt(0) == 39 || character.codeUnitAt(0) == 34;

bool _isWhitespace(String character) =>
    character == ' ' ||
    character == '\t' ||
    character == '\n' ||
    character == '\r';

bool _isIdentifierStart(String character) =>
    (character.codeUnitAt(0) >= 65 && character.codeUnitAt(0) <= 90) ||
    (character.codeUnitAt(0) >= 97 && character.codeUnitAt(0) <= 122) ||
    character == '_' ||
    character == r'$';

bool _isIdentifierPart(String character) =>
    _isIdentifierStart(character) ||
    (character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57);

class const _DartToken({
  required final String value,
  final bool isStringLiteral = false,
});
