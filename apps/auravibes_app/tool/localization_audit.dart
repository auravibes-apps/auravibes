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
  final reference = RegExp(r'LocaleKeys\.(\w+)');
  final literalCall = RegExp(
    r'''(['"])([^'"]+)\1\s*\.\s*(?:tr|plural)\s*\(''',
  );
  final literalFunction = RegExp(
    r'''\b(?:tr|plural)\s*\(\s*(['"])([^'"]+)\1''',
  );
  final sourceFiles = sourceDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in sourceFiles) {
    final source = file.readAsStringSync();
    for (final match in reference.allMatches(source)) {
      final symbol = match.group(1)!;
      final key = generatedKeys[symbol];
      if (key == null) {
        throw StateError('Unknown LocaleKeys symbol: $symbol');
      }
      usedKeys.add(key);
    }
    for (final match in literalCall.allMatches(source)) {
      usedKeys.add(match.group(2)!);
    }
    for (final match in literalFunction.allMatches(source)) {
      usedKeys.add(match.group(2)!);
    }
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
