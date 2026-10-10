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
      r'''import '\x70ackage:material_ui/material_ui.dart';''',
      r'''export '\u{70}ackage:cupertino_ui/cupertino_ui.dart';''',
      r'''import '\u0070ackage:material_ui/material_ui.dart';''',
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
          value: .fromCharCodes(source.codeUnits.getRange(start, index)),
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
    if (!raw && source.codeUnitAt(index) == 0x5C && index + 1 < source.length) {
      final escape = source[index + 1];
      if (escape == 'x' && index + 3 < source.length) {
        final codeUnit = int.tryParse(
          _codeUnitRangeAsString(source, index + 2, index + 4),
          radix: 16,
        );
        if (codeUnit != null) {
          value.writeCharCode(codeUnit);
          index += 4;
          continue;
        }
      }
      if (escape == 'u') {
        final unicodeEscape = _readUnicodeEscape(source, index);
        if (unicodeEscape != null) {
          value.write(String.fromCharCode(unicodeEscape.value));
          index = unicodeEscape.end;
          continue;
        }
      }
      if (escape == '\n') {
        index += 2;
        continue;
      }
      if (escape == '\r') {
        index += index + 2 < source.length && source[index + 2] == '\n' ? 3 : 2;
        continue;
      }
      value.write(switch (escape) {
        'b' => '\b',
        'f' => '\f',
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        'v' => '\x0B',
        _ => escape,
      });
      index += 2;
      continue;
    }
    value.write(source[index]);
    index++;
  }

  return (value: value.toString(), end: source.length);
}

({int value, int end})? _readUnicodeEscape(String source, int start) {
  final digitStart = start + 2;
  if (digitStart >= source.length) return null;
  if (source[digitStart] == '{') {
    final closingBrace = source.indexOf('}', digitStart + 1);
    if (closingBrace == -1) return null;
    final value = int.tryParse(
      _codeUnitRangeAsString(source, digitStart + 1, closingBrace),
      radix: 16,
    );
    if (value == null || value > 0x10FFFF) return null;

    return (value: value, end: closingBrace + 1);
  }

  final end = digitStart + 4;
  if (end > source.length) return null;
  final value = int.tryParse(
    _codeUnitRangeAsString(source, digitStart, end),
    radix: 16,
  );
  if (value == null) return null;

  return (value: value, end: end);
}

String _codeUnitRangeAsString(String source, int start, int end) =>
    String.fromCharCodes(source.codeUnits.getRange(start, end));

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
