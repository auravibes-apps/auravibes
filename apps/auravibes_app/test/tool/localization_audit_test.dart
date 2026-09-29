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
final raw = tr(r'menu.raw');
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
        'en': {'menu.count', 'menu.other', 'menu.raw'},
        'es': {'menu.count', 'menu.home', 'menu.other', 'menu.raw'},
      },
    );
  });

  test('ignores comments and code-looking text inside strings', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
// LocaleKeys.unknown_line and 'menu.fake_line'.tr()
/* LocaleKeys.unknown_block and 'menu.fake_block'.plural(2)
   /* tr('menu.fake_nested') */ */
final example = "LocaleKeys.unknown_string and 'menu.fake_string'.tr()";
final more = """plural('menu.fake_multiline')""";
final title = LocaleKeys.menu_new_chat;
final home = 'menu.home'.tr();
''');
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

  test('scans LocaleKeys references inside string interpolation', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final label = '${LocaleKeys.menu_new_chat.tr()}';
final fake = "LocaleKeys.unknown_text and tr('menu.fake')";
''');
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

  test('reports escaped dollar in a literal translation key', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final price = 'menu.\$price'.tr();
final quote = tr('menu.quo\'te');
final slash = tr('menu.back\\slash');
final dynamic = 'menu.$name'.tr();
''');
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
        'en': {r'menu.$price', "menu.quo'te", r'menu.back\slash'},
        'es': {r'menu.$price', "menu.quo'te", r'menu.back\slash'},
      },
    );
  });

  test('decodes Unicode escapes to the runtime translation key', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final home = tr('menu.\u0068ome');
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
        'en': <String>{},
        'es': {'menu.home'},
      },
    );
  });

  test('accepts static adjacent literals and skips dynamic arguments', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final home = tr('menu.' 'home');
final count = plural('menu.' 'count', 2);
final dynamic = tr('menu.' + suffix);
final dynamicCount = plural('menu.' + suffix, 2);
final receiver = 'menu.home'.tr();
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
        'en': {'menu.count'},
        'es': {'menu.count', 'menu.home'},
      },
    );
  });
}
