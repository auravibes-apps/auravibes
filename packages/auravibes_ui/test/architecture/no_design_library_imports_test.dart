import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbiddenDirective = RegExp(
  r'''(?:^|\n)\s*(?:import|export)(?:\s|//[^\n]*\n|/\*[\s\S]*?\*/)*(?:r)?(['"])\1{0,2}package:(?:material_ui|cupertino_ui)/''',
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
        if (_forbiddenDirective.hasMatch(file.readAsStringSync())) {
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
        _forbiddenDirective.hasMatch(directive),
        isTrue,
        reason: directive,
      );
    }
  });
}
