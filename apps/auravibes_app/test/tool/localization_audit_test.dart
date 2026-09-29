import 'dart:io';

import 'package:test/test.dart';

import '../../tool/localization_audit.dart';

void main() {
  late Directory root;
  late Directory translationsDir;
  late Directory sourceDir;
  late File localeKeysFile;

  setUp(() {
    root = Directory.systemTemp.createTempSync('localization-audit-');
    translationsDir = Directory('${root.path}/i18n')..createSync();
    sourceDir = Directory('${root.path}/lib')..createSync();
    localeKeysFile = File('${root.path}/locale_keys.dart')
      ..writeAsStringSync('''
abstract class LocaleKeys {
  static const menu_new_chat =
      'menu.new_chat';
}
''');
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
final title = LocaleKeys.menu_new_chat;
final home = 'menu.home'.tr();
final count = 'menu.home'.plural(2);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"new_chat":"New chat","home":"Home"}}
''');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('uses generated dotted paths and literal translation calls', () {
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"new_chat":"Nuevo chat","home":"Inicio"}}
''');

    expect(
      findMissingTranslations(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
      ),
      {'en': <String>{}, 'es': <String>{}},
    );
  });

  test('reports a missing generated path only for its locale', () {
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"home":"Inicio"}}
''');

    expect(
      findMissingTranslations(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
      ),
      {
        'en': <String>{},
        'es': {'menu.new_chat'},
      },
    );
  });

  test('reports missing literal tr and plural keys', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
final home = 'menu.home'.tr();
final count = 'menu.count'.plural(2);
final other = tr('menu.other');
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"new_chat":"Nuevo chat"}}
''');

    expect(
      findMissingTranslations(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
      ),
      {
        'en': {'menu.count', 'menu.other'},
        'es': {'menu.count', 'menu.home', 'menu.other'},
      },
    );
  });
}
