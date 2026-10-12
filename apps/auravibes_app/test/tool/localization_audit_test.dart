import 'dart:io';

import 'package:test/test.dart';

import '../../tool/localization_audit.dart';
import '../../tool/localization_dynamic_registry.dart';

void main() {
  final root = Directory.systemTemp.createTempSync('localization-audit-');
  final translationsDir = Directory('${root.path}/i18n');
  final sourceDir = Directory('${root.path}/lib');
  final localeKeysFile = File('${root.path}/locale_keys.dart');

  setUp(() {
    translationsDir.createSync();
    sourceDir.createSync();
    localeKeysFile.writeAsStringSync('''
abstract class LocaleKeys {
  static const menu_new_chat =
      'menu.new_chat';
  static const menu_home = 'menu.home';
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

  tearDownAll(() => root.deleteSync(recursive: true));

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
final vertical = tr('menu.vertical\vtab');
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
        'en': {
          r'menu.$price',
          'menu.quo${String.fromCharCode(39)}te',
          r'menu.back\slash',
          'menu.vertical\u000Btab',
        },
        'es': {
          r'menu.$price',
          'menu.quo${String.fromCharCode(39)}te',
          r'menu.back\slash',
          'menu.vertical\u000Btab',
        },
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
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
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

  test('collects raw-string constants used as extension translation keys', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
const _rawMenuKey = 'menu.raw';
final rawMenu = _rawMenuKey.tr();
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"raw":"Crudo"}}
''');

    expect(
      findMissingTranslations(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
      ),
      {
        'en': {'menu.raw'},
        'es': <String>{},
      },
    );
    expect(
      findDynamicTranslationIssues(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
        registry: const [],
      ),
      isEmpty,
    );
  });

  test('rejects adjacent extension receivers with interpolation', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final simple = 'menu.$name' 'home'.tr();
final braced = 'menu.${name}' 'count'.plural(2);
final static = 'menu.' 'new_chat'.tr();
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{}}
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

  test('matching named and positional placeholders pass', () {
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"greeting":"Hello {name}, you have {} items"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"greeting":"Hola {name}, tienes {} elementos"}}
''');

    expect(
      findPlaceholderMismatches(translationsDir: translationsDir),
      isEmpty,
    );
  });

  test('reports placeholder mismatches by locale and key', () {
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"greeting":"Hello {name}","selected_count":"{} selected"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"greeting":"Hola {user}","selected_count":"Seleccionados"}}
''');

    final issues = findPlaceholderMismatches(translationsDir: translationsDir);

    expect(
      issues,
      contains(
        'es: menu.greeting (named placeholders: expected {name}, found {user})',
      ),
    );
    expect(
      issues,
      contains(
        'es: menu.selected_count '
        '(positional placeholders: expected 1, found 0)',
      ),
    );
  });

  test('compares placeholder signatures for matching plural branches', () {
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"items":{"one":"{} item","other":"{} items"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"items":{"one":"{} elemento","other":"{count} elementos"}}
''');

    expect(
      findPlaceholderMismatches(translationsDir: translationsDir),
      contains(
        'es: items [branch: other] '
        '(named placeholders: expected {}, found {count}; '
        'positional placeholders: expected 1, found 0)',
      ),
    );
  });

  test('reports unused nested catalog keys missing from another locale', () {
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"new_chat":"New chat","unused":{"label":"Unused"}}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"new_chat":"Nuevo chat"}}
''');

    expect(
      findLocaleKeyParityIssues(translationsDir: translationsDir),
      contains('es: menu.unused.label (missing catalog key)'),
    );
  });

  test('audits TextLocale literals and static LocaleKeys ternaries', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
TextLocale('menu.text_locale');
TextLocale(isNewChat ? LocaleKeys.menu_new_chat : LocaleKeys.menu_home);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"new_chat":"New chat","home":"Home","text_locale":"Text"}}
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
        'es': {'menu.home', 'menu.text_locale'},
      },
    );
  });

  test('resolves static const keys and helper key variants', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
const _homeKey = LocaleKeys.menu_home;
const _newChatKey = LocaleKeys.menu_new_chat;
String _menuKey(bool isNewChat) =>
    isNewChat ? _newChatKey : _homeKey;
TextLocale(_menuKey(true));
final title = _menuKey(false).tr();
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
    expect(
      findDynamicTranslationIssues(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
        registry: const [],
      ),
      isEmpty,
    );
  });

  test('does not resolve a helper parameter through a same-named constant', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
const _dynamicKey = LocaleKeys.menu_home;
String _passThrough(String _dynamicKey) => _dynamicKey;
final title = _passThrough(dynamicKey).tr();
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [],
    );

    expect(issues.join('\n'), contains('unregistered dynamic tr key'));
  });

  test('treats nested conditional returns as part of a helper key', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
String _menuKey(bool useDynamic) {
  if (useDynamic) {
    return serverKey;
  }
  return LocaleKeys.menu_home;
}
TextLocale(_menuKey(true));
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [],
    );

    expect(issues.join('\n'), contains('unregistered dynamic TextLocale key'));
  });

  test('ignores returns inside nested block function literals', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
String _menuKey() {
  final callback = () {
    return serverKey;
  };
  return LocaleKeys.menu_home;
}
TextLocale(_menuKey());
''');

    expect(
      findDynamicTranslationIssues(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
        registry: const [],
      ),
      isEmpty,
    );
  });

  test('keeps same-named class constants in separate registered families', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
class FirstScreen {
  static const _key = 'menu.first';
  Widget build() => TextLocale(_key);
}
class SecondScreen {
  static const _key = 'menu.second';
  Widget build() => TextLocale(_key);
}
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"first":"First","second":"Second"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"first":"Primero"}}
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [
        LocalizationDynamicRegistry(
          family: 'first screen label',
          sites: [
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'TextLocale',
              keyExpression: '_key',
            ),
          ],
          keys: {'menu.first'},
        ),
        LocalizationDynamicRegistry(
          family: 'second screen label',
          sites: [
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'TextLocale',
              keyExpression: '_key',
              occurrence: 1,
            ),
          ],
          keys: {'menu.second'},
        ),
      ],
    );

    expect(
      issues,
      contains(
        'es: menu.second (registered dynamic key missing translation; '
        'family: second screen label)',
      ),
    );
    expect(issues, hasLength(1));
  });

  test('reports unregistered dynamic translation calls and wrapper keys', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync(r'''
final direct = tr(key);
final interpolated = 'menu.$suffix'.tr();
final count = context.plural(pluralKey, 2);
TextLocale(dynamicKey);
TextLocale(isNewChat ? LocaleKeys.menu_new_chat : LocaleKeys.menu_home);
final staticTernary = (isHome ? LocaleKeys.menu_home : LocaleKeys.menu_new_chat).tr();
// tr('menu.comment_only') and TextLocale(commentOnly)
final example = "plural('menu.string_only')";
''');
    final wrapperDir = Directory('${sourceDir.path}/widgets')..createSync();
    File('${wrapperDir.path}/text_locale.dart').writeAsStringSync('''
class TextLocale {
  Widget build(BuildContext context) => Text(data.tr(context: context));
}
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [],
    );

    expect(
      issues.where((issue) => issue.contains('unregistered dynamic tr key')),
      hasLength(2),
    );
    expect(
      issues.where(
        (issue) => issue.contains('unregistered dynamic plural key'),
      ),
      hasLength(1),
    );
    expect(
      issues.where(
        (issue) => issue.contains('unregistered dynamic TextLocale key'),
      ),
      hasLength(1),
    );
    expect(
      issues.singleWhere((issue) => issue.contains('dynamicKey')),
      contains('screen.dart:4'),
    );
  });

  test(
    'reports the full braced interpolation receiver for extension calls',
    () {
      File('${sourceDir.path}/screen.dart')
          .writeAsStringSync(r'''final item = 'menu.${suffix}'.tr();''');

      final issues = findDynamicTranslationIssues(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
        registry: const [],
      );

      expect(issues, [
        r'''screen.dart:1: unregistered dynamic tr key ('menu.${suffix}')''',
      ]);
    },
  );

  test('checks registered dynamic family keys in every locale', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
// Line changes must not invalidate reviewed call sites.
final title = tr(dynamicTitle);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title"}}
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [
        LocalizationDynamicRegistry(
          family: 'screen title variants',
          sites: [
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'tr',
              keyExpression: 'dynamicTitle',
            ),
          ],
          keys: {'menu.dynamic'},
        ),
      ],
    );
    expect(issues, isEmpty);
  });

  test('disambiguates repeated dynamic expressions by occurrence', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
final first = tr(dynamicTitle);
final second = tr(dynamicTitle);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title"}}
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [
        LocalizationDynamicRegistry(
          family: 'screen title variants',
          sites: [
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'tr',
              keyExpression: 'dynamicTitle',
            ),
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'tr',
              keyExpression: 'dynamicTitle',
              occurrence: 1,
            ),
          ],
          keys: {'menu.dynamic'},
        ),
      ],
    );

    expect(issues, isEmpty);
  });

  test('checks every explicitly registered dynamic family key', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
final title = tr(dynamicTitle);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title","home":"Home"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title","home":"Inicio"}}
''');
    const registry = [
      LocalizationDynamicRegistry(
        family: 'menu title variants',
        sites: [
          DynamicTranslationSite(
            file: 'screen.dart',
            method: 'tr',
            keyExpression: 'dynamicTitle',
          ),
        ],
        keys: {'menu.dynamic', 'menu.home'},
      ),
    ];

    expect(
      findDynamicTranslationIssues(
        translationsDir: translationsDir,
        sourceDir: sourceDir,
        localeKeysFile: localeKeysFile,
        registry: registry,
      ),
      isEmpty,
    );

    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title"}}
''');
    final missing = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: registry,
    );
    expect(
      missing.join('\n'),
      contains('es: menu.home (registered dynamic key missing translation'),
    );
  });

  test('reports registered dynamic keys missing from one locale', () {
    File('${sourceDir.path}/screen.dart').writeAsStringSync('''
final title = tr(dynamicTitle);
''');
    File('${translationsDir.path}/en.json').writeAsStringSync('''
{"menu":{"dynamic":"Dynamic title"}}
''');
    File('${translationsDir.path}/es.json').writeAsStringSync('''
{"menu":{}}
''');

    final issues = findDynamicTranslationIssues(
      translationsDir: translationsDir,
      sourceDir: sourceDir,
      localeKeysFile: localeKeysFile,
      registry: const [
        LocalizationDynamicRegistry(
          family: 'screen title variants',
          sites: [
            DynamicTranslationSite(
              file: 'screen.dart',
              method: 'tr',
              keyExpression: 'dynamicTitle',
            ),
          ],
          keys: {'menu.dynamic'},
        ),
      ],
    );
    expect(
      issues.join('\n'),
      contains(
        'es: menu.dynamic (registered dynamic key missing translation; family:',
      ),
    );
  });
}
