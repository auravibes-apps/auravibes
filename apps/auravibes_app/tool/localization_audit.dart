import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'localization_dynamic_registry.dart';

extension on String {
  String _slice(int start, int end) =>
      String.fromCharCodes(codeUnits.getRange(start, end));
}

Map<String, Set<String>> findMissingTranslations({
  required Directory translationsDir,
  required Directory sourceDir,
  required File localeKeysFile,
}) {
  final generatedKeys = _loadGeneratedKeys(localeKeysFile);

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

/// Reports dynamic translation calls that are missing a family registration,
/// stale registrations, and registered keys absent from a supported locale.
List<String> findDynamicTranslationIssues({
  required Directory translationsDir,
  required Directory sourceDir,
  required File localeKeysFile,
  required List<LocalizationDynamicRegistry> registry,
}) {
  final generatedKeys = _loadGeneratedKeys(localeKeysFile);
  final sourceFiles =
      sourceDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final calls = <_DynamicTranslationCall>{};
  for (final file in sourceFiles) {
    final source = file.readAsStringSync();
    final relativePath = file.path
        .replaceFirst('${sourceDir.path}${Platform.pathSeparator}', '')
        .replaceAll(Platform.pathSeparator, '/');
    final fileCalls = _findDynamicTranslationCalls(
      source,
      relativePath,
      generatedKeys,
    );
    calls.addAll(fileCalls);
  }

  final issues = <String>[];
  final registrations =
      <
        _DynamicTranslationSiteIdentity,
        ({LocalizationDynamicRegistry family, DynamicTranslationSite site})
      >{};
  for (final registration in registry) {
    if (registration.keys.isEmpty) {
      issues.add('${registration.family}: no keys registered');
    }
    if (registration.sites.isEmpty) {
      issues.add('${registration.family}: no call sites registered');
    }
    for (final registeredSite in registration.sites) {
      final site = _dynamicTranslationSite(
        registeredSite.file,
        registeredSite.method,
        registeredSite.keyExpression,
        registeredSite.occurrence,
      );
      if (registrations.containsKey(site)) {
        issues.add(
          'Duplicate dynamic translation registration: ${registration.family}',
        );
        continue;
      }
      registrations[site] = (family: registration, site: registeredSite);
    }
  }

  final matchedRegistrations = <_DynamicTranslationSiteIdentity>{};
  final catalogs = _loadLocaleCatalogs(translationsDir);
  for (final call in calls) {
    final site = _dynamicTranslationSite(
      call.file,
      call.method,
      call.keyExpression,
      call.occurrence,
    );
    final registered = registrations[site];
    if (registered == null) {
      issues.add(
        '${call.file}:${call.line}: unregistered dynamic ${call.method} key '
        '(${call.keyExpression})',
      );
      continue;
    }
    final _ = matchedRegistrations.add(site);
  }

  for (final entry in registrations.entries) {
    if (!matchedRegistrations.contains(entry.key)) {
      final registration = entry.value;
      issues.add(
        '${registration.family.family}: no dynamic ${registration.site.method} '
        'call for ${registration.site.keyExpression} '
        '(${registration.site.file}, occurrence '
        '${registration.site.occurrence})',
      );
    }
  }

  for (final registration in registry) {
    for (final locale in catalogs.keys.toList()..sort()) {
      for (final key in registration.keys.toList()..sort()) {
        if (!catalogs[locale]!.translations.containsKey(key)) {
          issues.add(
            '$locale: $key (registered dynamic key missing translation; '
            'family: ${registration.family})',
          );
        }
      }
    }
  }

  return issues.toSet().toList()..sort();
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
          expected: reference,
          actual: translation,
          branch: branch,
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

Map<String, String> _loadGeneratedKeys(File localeKeysFile) {
  final generatedKeys = <String, String>{};
  final declaration = RegExp(
    r'''static\s+const\s+(\w+)\s*=\s*['"]([^'"]+)['"]\s*;''',
  );
  for (final match in declaration.allMatches(
    localeKeysFile.readAsStringSync(),
  )) {
    final symbol = match.group(1);
    final path = match.group(2);
    if (symbol == null || path == null) continue;
    generatedKeys[symbol] = path;
  }

  return generatedKeys;
}

typedef _Token = ({
  String value,
  bool isString,
  bool isLiteral,
  bool followsString,
  int start,
  int end,
});

const _singleQuoteCodeUnit = 0x27;

void _collectUsedKeys(
  String source,
  Map<String, String> generatedKeys,
  Set<String> usedKeys,
) {
  final tokens = _tokenize(source);
  final resolver = LocalizationAudit(tokens, generatedKeys);
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    if (token.value == 'TextLocale' &&
        !token.isString &&
        index + 1 < tokens.length &&
        tokens[index + 1].value == '(') {
      final argumentStart = index + 2;
      final argumentEnd = _callArgumentEnd(tokens, argumentStart);
      usedKeys.addAll(
        resolver.resolve(argumentStart, argumentEnd) ?? const <String>{},
      );
    }
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
      } else if (_translationKeyExpression(tokens, index) case final keySpan?) {
        final resolved =
            resolver.resolve(keySpan.start, keySpan.end) ?? const <String>{};
        usedKeys.addAll(resolved);
      }
    }
  }
}

bool _isTranslationCall(_Token token) =>
    !token.isString && (token.value == 'tr' || token.value == 'plural');

typedef _TokenSpan = ({int start, int end});

typedef _DynamicTranslationSiteIdentity = ({
  String file,
  String method,
  String keyExpression,
  int occurrence,
});

typedef _DynamicTranslationCall = ({
  String file,
  int line,
  String method,
  String keyExpression,
  int occurrence,
});

typedef _StaticTranslationDefinitions = ({
  Map<String, List<_TokenSpan>> constants,
  Map<String, List<_TokenSpan>> functions,
  Map<String, List<_TokenSpan>> getters,
  Set<String> ambiguousNames,
  Set<String> parameterNames,
});

class LocalizationAudit {
  new(this.tokens, this.generatedKeys)
    : definitions = _findStaticTranslationDefinitions(tokens);

  final List<_Token> tokens;
  final Map<String, String> generatedKeys;
  final _StaticTranslationDefinitions definitions;

  Set<String>? resolve(
    int startOffset,
    int endOffset, [
    Set<String>? resolving,
  ]) {
    var start = startOffset;
    var end = endOffset;
    final span = _stripOuterParentheses(tokens, start, end);
    start = span.start;
    end = span.end;
    if (start >= end) return null;

    final literal = _literalSequence(tokens, start);
    if (literal != null && literal.end == end) return {literal.key};
    if (_isLocaleKeyReference(tokens, start, end)) {
      final symbol = tokens[start + 2].value;
      final key = generatedKeys[symbol];
      if (key == null) throw StateError('Unknown LocaleKeys symbol: $symbol');

      return {key};
    }

    final conditional = _conditionalBranches(tokens, start, end);
    if (conditional != null) {
      final whenTrue = resolve(
        conditional.trueStart,
        conditional.trueEnd,
        resolving,
      );
      final whenFalse = resolve(
        conditional.falseStart,
        conditional.falseEnd,
        resolving,
      );
      if (whenTrue == null || whenFalse == null) return null;

      return {...whenTrue, ...whenFalse};
    }

    final switchResults = _switchResultSpans(tokens, start, end);
    if (switchResults.isNotEmpty) {
      final keys = <String>{};
      for (final result in switchResults) {
        final branchKeys = resolve(result.start, result.end, resolving);
        if (branchKeys == null) return null;
        keys.addAll(branchKeys);
      }

      return keys;
    }

    final activeNames = resolving ?? <String>{};
    if (end == start + 1 &&
        _isIdentifierToken(tokens[start]) &&
        tokens[start].value.startsWith('_') &&
        !definitions.parameterNames.contains(tokens[start].value)) {
      if (definitions.ambiguousNames.contains(tokens[start].value)) return null;

      return _resolveDefinition(
            tokens[start].value,
            definitions.constants,
            activeNames,
          ) ??
          _resolveDefinition(
            tokens[start].value,
            definitions.getters,
            activeNames,
          );
    }

    if (end == start + 3 &&
        _isIdentifierToken(tokens[start]) &&
        tokens[start].value.startsWith('_') &&
        tokens[start + 1].value == '.' &&
        _isIdentifierToken(tokens[start + 2])) {
      if (definitions.ambiguousNames.contains(tokens[start + 2].value)) {
        return null;
      }

      return _resolveDefinition(
            tokens[start + 2].value,
            definitions.constants,
            activeNames,
          ) ??
          _resolveDefinition(
            tokens[start + 2].value,
            definitions.getters,
            activeNames,
          );
    }

    if (end >= start + 3 &&
        _isIdentifierToken(tokens[start]) &&
        tokens[start + 1].value == '(' &&
        _matchingClosing(tokens, start + 1, '(', ')') == end - 1) {
      if (definitions.ambiguousNames.contains(tokens[start].value)) return null;

      return _resolveDefinition(
        tokens[start].value,
        definitions.functions,
        activeNames,
      );
    }

    if (end >= start + 5 &&
        _isIdentifierToken(tokens[start]) &&
        tokens[start + 1].value == '.' &&
        _isIdentifierToken(tokens[start + 2]) &&
        tokens[start + 2].value.startsWith('_') &&
        tokens[start + 3].value == '(' &&
        _matchingClosing(tokens, start + 3, '(', ')') == end - 1) {
      if (definitions.ambiguousNames.contains(tokens[start + 2].value)) {
        return null;
      }

      return _resolveDefinition(
        tokens[start + 2].value,
        definitions.functions,
        activeNames,
      );
    }

    return null;
  }

  Set<String>? _resolveDefinition(
    String name,
    Map<String, List<_TokenSpan>> definitionsByName,
    Set<String> resolving,
  ) {
    final definitions = definitionsByName[name];
    if (definitions == null ||
        definitions.isEmpty ||
        resolving.contains(name)) {
      return null;
    }
    final nestedResolving = {...resolving, name};
    final keys = <String>{};
    for (final definition in definitions) {
      final definitionKeys = resolve(
        definition.start,
        definition.end,
        nestedResolving,
      );
      if (definitionKeys == null) return null;
      keys.addAll(definitionKeys);
    }

    return keys;
  }
}

_StaticTranslationDefinitions _findStaticTranslationDefinitions(
  List<_Token> tokens,
) {
  final constants = <String, List<_TokenSpan>>{};
  final functions = <String, List<_TokenSpan>>{};
  final getters = <String, List<_TokenSpan>>{};
  final declaredNames = <String>{};
  final ambiguousNames = <String>{};
  final parameterNames = <String>{};

  // Definitions are file-scoped here; duplicate names may belong to different
  // classes, so resolution must not union their values.
  void markDeclaredName(String name) {
    if (!declaredNames.add(name)) {
      final _ = ambiguousNames.add(name);
    }
  }

  for (var index = 0; index < tokens.length; index++) {
    if (tokens[index].value == 'const') {
      final equals = _findDeclarationEquals(tokens, index + 1);
      if (equals != null && equals > index + 1) {
        final name = tokens[equals - 1];
        if (_isIdentifierToken(name)) {
          final valueEnd = _expressionEnd(tokens, equals + 1, tokens.length);
          if (valueEnd > equals + 1) {
            markDeclaredName(name.value);
            constants.putIfAbsent(name.value, () => []).add((
              start: equals + 1,
              end: valueEnd,
            ));
          }
        }
      }
    }

    if (tokens[index].value == 'get' &&
        index + 3 < tokens.length &&
        _isIdentifierToken(tokens[index + 1]) &&
        tokens[index + 2].value == '=' &&
        tokens[index + 3].value == '>') {
      final expressionStart = index + 4;
      final expressionEnd = _expressionEnd(
        tokens,
        expressionStart,
        tokens.length,
      );
      if (expressionEnd > expressionStart) {
        markDeclaredName(tokens[index + 1].value);
        getters.putIfAbsent(tokens[index + 1].value, () => []).add((
          start: expressionStart,
          end: expressionEnd,
        ));
      }
    }

    if (!_isIdentifierToken(tokens[index]) ||
        (index > 0 && tokens[index - 1].value == '.') ||
        index + 1 >= tokens.length ||
        tokens[index + 1].value != '(') {
      continue;
    }
    final parametersEnd = _matchingClosing(tokens, index + 1, '(', ')');
    if (parametersEnd == null) continue;
    var bodyStart = parametersEnd + 1;
    while (bodyStart < tokens.length &&
        (tokens[bodyStart].value == 'async' ||
            tokens[bodyStart].value == 'sync' ||
            tokens[bodyStart].value == '*')) {
      bodyStart++;
    }
    final hasArrowBody =
        bodyStart + 1 < tokens.length &&
        tokens[bodyStart].value == '=' &&
        tokens[bodyStart + 1].value == '>';
    final hasBlockBody =
        bodyStart < tokens.length && tokens[bodyStart].value == '{';
    if (!hasArrowBody && !hasBlockBody) continue;
    markDeclaredName(tokens[index].value);

    for (final parameter in _callArguments(tokens, index + 1)) {
      var parameterEnd = parameter.end;
      for (var cursor = parameter.start; cursor < parameter.end; cursor++) {
        if (tokens[cursor].value == '=') {
          parameterEnd = cursor;
          break;
        }
      }
      for (var cursor = parameterEnd - 1; cursor >= parameter.start; cursor--) {
        if (_isIdentifierToken(tokens[cursor])) {
          final _ = parameterNames.add(tokens[cursor].value);
          break;
        }
      }
    }

    if (hasArrowBody) {
      final expressionStart = bodyStart + 2;
      final expressionEnd = _expressionEnd(
        tokens,
        expressionStart,
        tokens.length,
      );
      if (expressionEnd > expressionStart) {
        functions.putIfAbsent(tokens[index].value, () => []).add((
          start: expressionStart,
          end: expressionEnd,
        ));
      }
    } else if (bodyStart < tokens.length && tokens[bodyStart].value == '{') {
      final bodyEnd = _matchingClosing(tokens, bodyStart, '{', '}');
      if (bodyEnd == null) continue;
      var cursor = bodyStart + 1;
      while (cursor < bodyEnd) {
        if (tokens[cursor].value == '{' &&
            _isNestedFunctionLiteralBody(tokens, cursor)) {
          final closureEnd = _matchingClosing(tokens, cursor, '{', '}');
          if (closureEnd == null || closureEnd >= bodyEnd) {
            functions.putIfAbsent(tokens[index].value, () => []).add((
              start: cursor,
              end: cursor,
            ));
            break;
          }
          cursor = closureEnd + 1;
          continue;
        }
        if (tokens[cursor].value != 'return') {
          cursor++;
          continue;
        }

        final expressionStart = cursor + 1;
        final expressionEnd = _expressionEnd(tokens, expressionStart, bodyEnd);
        functions.putIfAbsent(tokens[index].value, () => []).add((
          start: expressionStart,
          end: expressionEnd,
        ));
        cursor = expressionEnd + 1;
      }
    }
  }

  return (
    constants: constants,
    functions: functions,
    getters: getters,
    ambiguousNames: ambiguousNames,
    parameterNames: parameterNames,
  );
}

bool _isNestedFunctionLiteralBody(List<_Token> tokens, int openingBrace) {
  var previous = openingBrace - 1;
  while (previous >= 0 &&
      (tokens[previous].value == 'async' ||
          tokens[previous].value == 'sync' ||
          tokens[previous].value == '*')) {
    previous--;
  }
  if (previous < 0 || tokens[previous].value != ')') return false;

  final openingParenthesis = _matchingOpening(tokens, previous, '(', ')');
  if (openingParenthesis == null || openingParenthesis == 0) return true;

  return !const {
    'if',
    'for',
    'while',
    'switch',
    'catch',
  }.contains(tokens[openingParenthesis - 1].value);
}

int? _findDeclarationEquals(List<_Token> tokens, int start) {
  for (var index = start; index < tokens.length; index++) {
    final value = tokens[index].value;
    if (value == '=') return index;
    if (value == ';' || value == '(' || value == '{' || value == ',') {
      return null;
    }
    if (!_isIdentifierToken(tokens[index]) &&
        value != '?' &&
        value != '<' &&
        value != '>') {
      return null;
    }
  }

  return null;
}

int _expressionEnd(List<_Token> tokens, int start, int limit) {
  var parentheses = 0;
  var brackets = 0;
  var braces = 0;
  for (var index = start; index < limit; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        if (parentheses == 0 && brackets == 0 && braces == 0) return index;
        parentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        if (braces == 0 && parentheses == 0 && brackets == 0) return index;
        braces--;
      case ';':
        if (parentheses == 0 && brackets == 0 && braces == 0) return index;
    }
  }

  return limit;
}

_DynamicTranslationSiteIdentity _dynamicTranslationSite(
  String file,
  String method,
  String keyExpression,
  int occurrence,
) => (
  file: file,
  method: method,
  keyExpression: keyExpression,
  occurrence: occurrence,
);

List<_DynamicTranslationCall> _findDynamicTranslationCalls(
  String source,
  String file,
  Map<String, String> generatedKeys,
) {
  final tokens = _tokenize(source);
  final resolver = LocalizationAudit(tokens, generatedKeys);
  final calls = <_DynamicTranslationCall>[];
  final occurrences = <({String method, String keyExpression}), int>{};
  void addCall(String method, _TokenSpan expression, int callIndex) {
    final callOffset = tokens[callIndex].start;
    // TextLocale usages are audited above this wrapper. Exclude only its
    // direct forwarding call so another dynamic helper in this file remains
    // visible to the audit.
    if (file == 'widgets/text_locale.dart' &&
        method == 'tr' &&
        _isTextLocaleForwardingCall(tokens, callIndex)) {
      return;
    }
    final keyExpression = _sourceSpanText(source, tokens, expression);
    final occurrenceKey = (method: method, keyExpression: keyExpression);
    final occurrence = occurrences[occurrenceKey] ?? 0;
    occurrences[occurrenceKey] = occurrence + 1;
    calls.add((
      file: file,
      line: _lineNumber(source, callOffset),
      method: method,
      keyExpression: keyExpression,
      occurrence: occurrence,
    ));
  }

  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    if (token.value == 'TextLocale' &&
        !token.isString &&
        !_isTextLocaleClassDeclaration(tokens, index) &&
        index + 1 < tokens.length &&
        tokens[index + 1].value == '(') {
      final argumentStart = index + 2;
      final argumentEnd = _callArgumentEnd(tokens, argumentStart);
      if (resolver.resolve(argumentStart, argumentEnd) == null) {
        final argument = (start: argumentStart, end: argumentEnd);
        addCall('TextLocale', argument, index);
      }
    }
    if (_isTranslationCall(token) &&
        index + 1 < tokens.length &&
        tokens[index + 1].value == '(') {
      final keyExpression = _translationKeyExpression(tokens, index);
      if (keyExpression != null &&
          resolver.resolve(keyExpression.start, keyExpression.end) == null) {
        addCall(token.value, keyExpression, index);
      }
    }
  }

  return calls;
}

String _sourceSpanText(String source, List<_Token> tokens, _TokenSpan span) {
  if (span.start >= span.end || span.start >= tokens.length) return '';
  final start = tokens[span.start].start;
  final end = tokens[span.end - 1].end;

  return source._slice(start, end).replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isTextLocaleClassDeclaration(List<_Token> tokens, int index) {
  for (var cursor = index - 1; cursor >= 0 && index - cursor <= 4; cursor--) {
    final value = tokens[cursor].value;
    if (value == 'class') return true;
    if (value == ';' || value == '{' || value == '}') return false;
  }

  return false;
}

bool _isTextLocaleForwardingCall(List<_Token> tokens, int callIndex) {
  if (callIndex < 2 ||
      tokens[callIndex].value != 'tr' ||
      tokens[callIndex - 1].value != '.' ||
      tokens[callIndex - 2].value != 'data') {
    return false;
  }

  for (var classIndex = 0; classIndex < tokens.length; classIndex++) {
    if (tokens[classIndex].value != 'TextLocale' ||
        !_isTextLocaleClassDeclaration(tokens, classIndex)) {
      continue;
    }
    final classBodyStart = _textLocaleClassBodyStart(tokens, classIndex);
    if (classBodyStart == null) continue;
    final classBodyEnd = _matchingClosing(tokens, classBodyStart, '{', '}');
    if (classBodyEnd == null) continue;

    for (
      var methodIndex = classBodyStart + 1;
      methodIndex < classBodyEnd;
      methodIndex++
    ) {
      if (tokens[methodIndex].value != 'build' ||
          methodIndex + 1 >= classBodyEnd ||
          tokens[methodIndex + 1].value != '(') {
        continue;
      }
      final parametersEnd = _matchingClosing(tokens, methodIndex + 1, '(', ')');
      if (parametersEnd == null ||
          parametersEnd >= classBodyEnd ||
          parametersEnd + 4 >= classBodyEnd) {
        continue;
      }
      final arrowIndex = parametersEnd + 1;
      final textIndex = arrowIndex + 2;
      if (tokens[arrowIndex].value != '=' ||
          tokens[arrowIndex + 1].value != '>' ||
          tokens[textIndex].value != 'Text' ||
          tokens[textIndex + 1].value != '(') {
        continue;
      }

      final firstArgument = textIndex + 2;
      if (firstArgument + 2 >= classBodyEnd) continue;
      if (firstArgument == callIndex - 2 &&
          tokens[firstArgument].value == 'data' &&
          tokens[firstArgument + 1].value == '.' &&
          tokens[firstArgument + 2].value == 'tr') {
        return true;
      }
    }
  }

  return false;
}

int? _textLocaleClassBodyStart(List<_Token> tokens, int classIndex) {
  var parentheses = 0;
  for (var index = classIndex + 1; index < tokens.length; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        parentheses--;
      case '{':
        if (parentheses == 0) return index;
      case ';':
        if (parentheses == 0) return null;
    }
  }

  return null;
}

int _lineNumber(String source, int offset) {
  var line = 1;
  for (var index = 0; index < offset && index < source.length; index++) {
    if (source.codeUnitAt(index) == 0x0a) line++;
  }

  return line;
}

_TokenSpan? _translationKeyExpression(List<_Token> tokens, int methodIndex) {
  final method = tokens[methodIndex].value;
  final arguments = _callArguments(tokens, methodIndex + 1);
  final memberDot = _memberDotStart(tokens, methodIndex);
  if (memberDot != null &&
      _isExtensionTranslationCall(tokens, method, arguments)) {
    final expressionStart = _expressionStart(tokens, memberDot);
    if (expressionStart == null) return null;
    final receiverStart = _adjacentStringSequenceStart(tokens, expressionStart);

    return (start: receiverStart, end: memberDot);
  }

  return arguments.firstOrNull;
}

int _adjacentStringSequenceStart(List<_Token> tokens, int start) {
  var sequenceStart = start;
  while (tokens[sequenceStart].isString &&
      tokens[sequenceStart].followsString) {
    final currentStart = tokens[sequenceStart].start;
    var previousString = -1;
    for (var index = 0; index < sequenceStart; index++) {
      final token = tokens[index];
      if (token.isString &&
          token.end <= currentStart &&
          (previousString < 0 || token.end > tokens[previousString].end)) {
        previousString = index;
      }
    }
    if (previousString < 0) break;
    sequenceStart = previousString;
  }

  return sequenceStart;
}

List<_TokenSpan> _callArguments(List<_Token> tokens, int openParenthesis) {
  final arguments = <_TokenSpan>[];
  var start = openParenthesis + 1;
  var parentheses = 0;
  var brackets = 0;
  var braces = 0;
  for (var index = start; index < tokens.length; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        if (parentheses == 0 && brackets == 0 && braces == 0) {
          if (start < index) arguments.add((start: start, end: index));

          return arguments;
        }
        parentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        braces--;
      case ',':
        if (parentheses == 0 && brackets == 0 && braces == 0) {
          if (start < index) arguments.add((start: start, end: index));
          start = index + 1;
        }
    }
  }

  return arguments;
}

int? _memberDotStart(List<_Token> tokens, int methodIndex) {
  if (methodIndex == 0 || tokens[methodIndex - 1].value != '.') return null;
  if (methodIndex >= 2 && tokens[methodIndex - 2].value == '?') {
    return methodIndex - 2;
  }

  return methodIndex - 1;
}

bool _isExtensionTranslationCall(
  List<_Token> tokens,
  String method,
  List<_TokenSpan> arguments,
) {
  if (arguments.isEmpty ||
      arguments.every((argument) => _isNamedArgument(tokens, argument))) {
    return true;
  }
  if (method != 'plural') return false;
  if (arguments.length == 1) return true;

  return arguments
      .skip(1)
      .every((argument) => _isNamedArgument(tokens, argument));
}

bool _isNamedArgument(List<_Token> tokens, _TokenSpan argument) =>
    argument.start + 1 < argument.end &&
    _isIdentifierToken(tokens[argument.start]) &&
    tokens[argument.start + 1].value == ':';

bool _isIdentifierToken(_Token token) =>
    !token.isString &&
    token.value.isNotEmpty &&
    _isIdentifierStart(token.value.codeUnitAt(0));

int? _expressionStart(List<_Token> tokens, int end) {
  if (end <= 0) return null;
  var start = end - 1;
  final receiver = tokens[start];
  if (receiver.value == ';' &&
      !receiver.isString &&
      receiver.start == receiver.end) {
    for (var index = start - 1; index >= 0; index--) {
      final token = tokens[index];
      if (token.isString && token.end == receiver.start) return index;
    }
  }

  final value = tokens[start].value;
  if (value == ')') {
    final open = _matchingOpening(tokens, start, '(', ')');
    if (open != null) {
      start = open;
      if (start > 0 && _isIdentifierToken(tokens[start - 1])) start--;
    }
  } else if (value == ']') {
    start = _matchingOpening(tokens, start, '[', ']') ?? start;
  } else if (value == '}') {
    start = _matchingOpening(tokens, start, '{', '}') ?? start;
  }

  while (start >= 2 &&
      tokens[start - 1].value == '.' &&
      _isIdentifierToken(tokens[start - 2])) {
    start -= 2;
  }

  return start;
}

bool _isLocaleKeyReference(List<_Token> tokens, int start, int end) =>
    end == start + 3 &&
    tokens[start].value == 'LocaleKeys' &&
    tokens[start + 1].value == '.' &&
    _isIdentifierToken(tokens[start + 2]);

_TokenSpan _stripOuterParentheses(List<_Token> tokens, int start, int end) {
  var spanStart = start;
  var spanEnd = end;
  while (spanStart < spanEnd && tokens[spanStart].value == '(') {
    final close = _matchingClosing(tokens, spanStart, '(', ')');
    if (close != spanEnd - 1) break;
    spanStart++;
    spanEnd--;
  }

  return (start: spanStart, end: spanEnd);
}

({int trueStart, int trueEnd, int falseStart, int falseEnd})?
_conditionalBranches(List<_Token> tokens, int start, int end) {
  var parentheses = 0;
  var brackets = 0;
  var braces = 0;
  var question = -1;
  var pendingQuestions = 0;
  for (var index = start; index < end; index++) {
    final value = tokens[index].value;
    switch (value) {
      case '(':
        parentheses++;
      case ')':
        parentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        braces--;
      case '?':
        if (parentheses == 0 && brackets == 0 && braces == 0) {
          final next = index + 1 < end ? tokens[index + 1].value : '';
          final previous = index > start ? tokens[index - 1].value : '';
          if (next != '.' && next != '?' && previous != '?') {
            if (question < 0) question = index;
            pendingQuestions++;
          }
        }
      case ':':
        if (question >= 0 &&
            parentheses == 0 &&
            brackets == 0 &&
            braces == 0 &&
            --pendingQuestions == 0) {
          return (
            trueStart: question + 1,
            trueEnd: index,
            falseStart: index + 1,
            falseEnd: end,
          );
        }
    }
  }

  return null;
}

List<_TokenSpan> _switchResultSpans(List<_Token> tokens, int start, int end) {
  if (start >= end || tokens[start].value != 'switch') return const [];
  var parentheses = 0;
  var bodyStart = -1;
  for (var index = start + 1; index < end; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        parentheses--;
      case '{':
        if (parentheses == 0) {
          bodyStart = index;
          break;
        }
    }
    if (bodyStart >= 0) break;
  }
  if (bodyStart < 0) return const [];
  final bodyEnd = _matchingClosing(tokens, bodyStart, '{', '}');
  if (bodyEnd == null || bodyEnd > end) return const [];

  final results = <_TokenSpan>[];
  var nestedParentheses = 0;
  var brackets = 0;
  var braces = 0;
  for (var index = bodyStart + 1; index < bodyEnd; index++) {
    switch (tokens[index].value) {
      case '(':
        nestedParentheses++;
      case ')':
        nestedParentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        braces--;
      case '=':
        if (nestedParentheses == 0 &&
            brackets == 0 &&
            braces == 0 &&
            index + 1 < bodyEnd &&
            tokens[index + 1].value == '>') {
          final expressionStart = index + 2;
          final expressionEnd = _switchArmEnd(tokens, expressionStart, bodyEnd);
          if (expressionStart < expressionEnd) {
            results.add((start: expressionStart, end: expressionEnd));
          }
          index = expressionEnd;
        }
    }
  }

  return results;
}

int _switchArmEnd(List<_Token> tokens, int start, int bodyEnd) {
  var parentheses = 0;
  var brackets = 0;
  var braces = 0;
  for (var index = start; index < bodyEnd; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        parentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        if (braces == 0 && parentheses == 0 && brackets == 0) {
          return index;
        }
        braces--;
      case ',':
        if (parentheses == 0 && brackets == 0 && braces == 0) return index;
    }
  }

  return bodyEnd;
}

int? _matchingClosing(
  List<_Token> tokens,
  int open,
  String opening,
  String closing,
) {
  var depth = 0;
  for (var index = open; index < tokens.length; index++) {
    if (tokens[index].value == opening) depth++;
    if (tokens[index].value == closing && --depth == 0) return index;
  }

  return null;
}

int? _matchingOpening(
  List<_Token> tokens,
  int close,
  String opening,
  String closing,
) {
  var depth = 0;
  for (var index = close; index >= 0; index--) {
    if (tokens[index].value == closing) depth++;
    if (tokens[index].value == opening && --depth == 0) return index;
  }

  return null;
}

int _callArgumentEnd(List<_Token> tokens, int start) {
  var parentheses = 0;
  var brackets = 0;
  var braces = 0;
  for (var index = start; index < tokens.length; index++) {
    switch (tokens[index].value) {
      case '(':
        parentheses++;
      case ')':
        if (parentheses == 0 && brackets == 0 && braces == 0) {
          return index;
        }
        parentheses--;
      case '[':
        brackets++;
      case ']':
        brackets--;
      case '{':
        braces++;
      case '}':
        braces--;
      case ',':
        if (parentheses == 0 && brackets == 0 && braces == 0) {
          return index;
        }
    }
  }

  return tokens.length;
}

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

List<_Token> _tokenize(String source, {int baseOffset = 0}) {
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
    final tokenStart = index;
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
      final contentStart = index;
      final interpolations = <List<_Token>>[];
      var hasInterpolation = false;
      while (index < source.length && !source.startsWith(delimiter, index)) {
        if (!rawString && source.startsWith(r'${', index)) {
          final end = _interpolationEnd(source, index);
          if (end != null) {
            hasInterpolation = true;
            final expressionStart = index + 2;
            interpolations.add(
              _tokenize(
                source._slice(expressionStart, end),
                baseOffset: baseOffset + expressionStart,
              ),
            );
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
      final tokenEnd = end < source.length ? end + delimiter.length : end;
      final value = source._slice(contentStart, end);
      tokens.add((
        value: rawString ? value : _decodeDartString(value),
        isString: true,
        isLiteral: !hasInterpolation,
        followsString: previousWasString,
        start: baseOffset + tokenStart,
        end: baseOffset + tokenEnd,
      ));
      for (final expression in interpolations) {
        tokens
          ..add((
            value: ';',
            isString: false,
            isLiteral: false,
            followsString: false,
            start: baseOffset + tokenEnd,
            end: baseOffset + tokenEnd,
          ))
          ..addAll(expression)
          ..add((
            value: ';',
            isString: false,
            isLiteral: false,
            followsString: false,
            start: baseOffset + tokenEnd,
            end: baseOffset + tokenEnd,
          ));
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
        start: baseOffset + start,
        end: baseOffset + index,
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
        start: baseOffset + index,
        end: baseOffset + index + 1,
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
  final sourceDir = Directory('${appDir.path}/lib');
  final localeKeysFile = File('${appDir.path}/lib/i18n/locale_keys.dart');
  final missing = findMissingTranslations(
    translationsDir: translationsDir,
    sourceDir: sourceDir,
    localeKeysFile: localeKeysFile,
  );
  for (final entry in missing.entries) {
    for (final key in entry.value) {
      stdout.writeln('${entry.key}: $key');
      exitCode = 1;
    }
  }
  for (final issue in findDynamicTranslationIssues(
    translationsDir: translationsDir,
    sourceDir: sourceDir,
    localeKeysFile: localeKeysFile,
    registry: localizationDynamicKeyRegistry,
  )) {
    stdout.writeln('Dynamic translation key: $issue');
    exitCode = 1;
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
      'Localization audit passed (referenced and dynamic keys, '
      'catalog parity, placeholders).',
    );
  }
}
