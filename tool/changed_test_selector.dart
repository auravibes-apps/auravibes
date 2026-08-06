import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Selection mode for changed-test execution.
enum SelectionMode { full, affected, none }

/// One file row from a Git change range.
class ChangedFile {
  ChangedFile({
    required this.status,
    this.oldPath,
    this.newPath,
  }) {
    if (status != 'added' &&
        status != 'modified' &&
        status != 'deleted' &&
        status != 'renamed') {
      throw ArgumentError.value(status, 'status', 'Unsupported change status');
    }
  }

  const ChangedFile.added(String path)
    : status = 'added',
      oldPath = null,
      newPath = path;

  const ChangedFile.modified(String path)
    : status = 'modified',
      oldPath = path,
      newPath = path;

  const ChangedFile.deleted(String path)
    : status = 'deleted',
      oldPath = path,
      newPath = null;

  const ChangedFile.renamed({
    required String this.oldPath,
    required String this.newPath,
  }) : status = 'renamed';

  final String status;
  final String? oldPath;
  final String? newPath;
}

/// Immutable selector output.
class SelectionResult {
  SelectionResult({
    required this.mode,
    required Map<String, List<String>> packages,
    required this.reason,
  }) : packages = _freezePackages(packages);

  final SelectionMode mode;
  final Map<String, List<String>> packages;
  final String reason;

  /// Returns values accepted by `jsonEncode`.
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'mode': mode.name,
      'reason': reason,
    };
    if (packages.isNotEmpty || mode == SelectionMode.affected) {
      json['packages'] = packages;
    }
    return json;
  }

  static Map<String, List<String>> _freezePackages(
    Map<String, List<String>> packages,
  ) {
    final frozen = <String, List<String>>{};
    for (final entry in packages.entries) {
      final paths = entry.value.toSet().toList()..sort();
      frozen[entry.key] = List.unmodifiable(paths);
    }
    return Map.unmodifiable(frozen);
  }
}

/// Parses NUL-delimited `git diff --name-status --find-renames -z` output.
List<ChangedFile> parseNameStatus(String output) {
  if (output.isEmpty) return const [];
  final fields = output.split('\u0000');
  if (fields.last.isEmpty) fields.removeLast();
  final changes = <ChangedFile>[];
  var index = 0;
  while (index < fields.length) {
    final status = fields[index++];
    if (status == 'A' || status == 'M' || status == 'D') {
      if (index >= fields.length) {
        throw const FormatException('Malformed name-status record');
      }
      final path = _normalizePath(fields[index++]);
      changes.add(switch (status) {
        'A' => ChangedFile.added(path),
        'M' => ChangedFile.modified(path),
        _ => ChangedFile.deleted(path),
      });
      continue;
    }
    if (RegExp(r'^R\d{1,3}$').hasMatch(status)) {
      if (index + 1 >= fields.length) {
        throw const FormatException('Malformed rename record');
      }
      final oldPath = _normalizePath(fields[index++]);
      final newPath = _normalizePath(fields[index++]);
      changes.add(ChangedFile.renamed(oldPath: oldPath, newPath: newPath));
      continue;
    }
    throw FormatException('Unsupported or malformed status: $status');
  }
  return List.unmodifiable(changes);
}

/// Builds a stable, serialized reverse graph for callers that need to inspect it.
/// Values contain comma-separated, sorted dependent paths; selection uses the
/// lossless internal set representation instead.
Map<String, String> buildReverseImportGraph(
  Map<String, String> sources,
  Map<String, String> packageRoots,
) {
  final reverse = _buildReverseGraph(sources, packageRoots);
  final result = <String, String>{};
  for (final path in reverse.keys.toList()..sort()) {
    final dependents = reverse[path]!.toList()..sort();
    result[path] = dependents.join(',');
  }
  return result;
}

/// Selects a conservative result from changed paths.
SelectionResult selectChangedTests({
  required List<ChangedFile> changes,
  required Map<String, String> headSources,
  required Map<String, String> baseSources,
  required Map<String, String> packageRoots,
}) {
  final paths = <String>{};
  try {
    for (final change in changes) {
      for (final path in [change.oldPath, change.newPath]) {
        if (path != null) paths.add(_normalizePath(path));
      }
    }
  } on FormatException {
    return _full('Malformed changed path.');
  }

  if (paths.isEmpty || paths.every(_isDocumentation)) {
    return SelectionResult(
      mode: SelectionMode.none,
      packages: const {},
      reason: 'No executable test input.',
    );
  }

  if (paths.any(_isGlobal)) {
    return _full('Global or ambiguous test input.');
  }

  final roots = <String, String>{};
  try {
    for (final entry in packageRoots.entries) {
      roots[entry.key] = _normalizePath(entry.value);
    }
    for (final path in paths.where((path) => !_isDocumentation(path))) {
      if (!_isSupportedDartPath(path, roots.values)) {
        return _full('Global or ambiguous test input.');
      }
    }

    final resolutionSources = <String, String>{
      ...baseSources,
      ...headSources,
    };
    final headGraph = _buildReverseGraph(
      headSources,
      roots,
      resolutionSources: resolutionSources,
    );
    final baseGraph = _buildReverseGraph(
      baseSources,
      roots,
      resolutionSources: resolutionSources,
    );
    final reverse = _mergeGraphs(headGraph, baseGraph);
    final candidates = _currentTestCandidates(headSources, roots);
    final selected = <String>{};

    for (final change in changes) {
      for (final path in [change.oldPath, change.newPath]) {
        if (path == null) continue;
        final normalized = _normalizePath(path);
        if (candidates.contains(normalized)) selected.add(normalized);
        if (!normalized.endsWith('.dart')) continue;
        _addReverseClosure(normalized, reverse, selected, candidates);
      }
    }

    final packages = <String, List<String>>{};
    for (final path in selected.toList()..sort()) {
      final root = _packageRootFor(path, roots.values);
      if (root == null) continue;
      packages.putIfAbsent(root, () => []).add(path.substring(root.length + 1));
    }
    for (final packagePaths in packages.values) {
      packagePaths.sort();
    }
    if (packages.isEmpty) {
      return SelectionResult(
        mode: SelectionMode.none,
        packages: const {},
        reason: 'No affected current test files.',
      );
    }
    return SelectionResult(
      mode: SelectionMode.affected,
      packages: packages,
      reason: 'reverse import impact',
    );
  } catch (_) {
    // ponytail: any incomplete static graph runs full suite; dynamic/runtime
    // loading is outside this deliberately bounded analyzer graph.
    return _full('Unable to build import graph.');
  }
}

typedef ProcessLauncher =
    Future<int> Function({
      required String executable,
      required List<String> arguments,
      required String workingDirectory,
    });

/// Contract entry point for running a selected result.
Future<int> runSelectedTests(
  SelectionResult selection, {
  required String rootPath,
  ProcessLauncher? launcher,
}) async {
  if (selection.mode == SelectionMode.none) {
    return 0;
  }

  // ponytail: execution is Task 3; fail closed rather than silently skipping.
  final launcherState = launcher == null ? 'default' : 'injected';
  throw UnsupportedError(
    'Selected-test execution is not implemented yet in $rootPath ($launcherState).',
  );
}

SelectionResult _full(String reason) => SelectionResult(
  mode: SelectionMode.full,
  packages: const {},
  reason: reason,
);

Map<String, String> _normalizeSources(Map<String, String> sources) {
  final normalized = <String, String>{};
  for (final entry in sources.entries) {
    final path = _normalizePath(entry.key);
    if (normalized.containsKey(path)) {
      throw const FormatException('Duplicate normalized source path');
    }
    normalized[path] = entry.value;
  }
  return normalized;
}

Map<String, Set<String>> _buildReverseGraph(
  Map<String, String> sources,
  Map<String, String> packageRoots, {
  Map<String, String>? resolutionSources,
}) {
  final normalizedSources = _normalizeSources(sources);
  final availableSources = _normalizeSources(resolutionSources ?? sources);
  final roots = <String, String>{
    for (final entry in packageRoots.entries)
      entry.key: _normalizePath(entry.value),
  };
  final reverse = <String, Set<String>>{
    for (final path in availableSources.keys) path: <String>{},
  };

  for (final entry in normalizedSources.entries) {
    if (!entry.key.endsWith('.dart')) continue;
    final parsed = parseString(
      content: entry.value,
      path: entry.key,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      throw const FormatException('Dart parse failure');
    }
    for (final directive in parsed.unit.directives) {
      final uris = _directiveUris(directive);
      for (final uri in uris) {
        final target = _resolveUri(
          uri,
          entry.key,
          availableSources,
          roots,
        );
        if (target == null) continue;
        if (!availableSources.containsKey(target)) {
          throw FormatException('Unresolved workspace URI: $uri');
        }
        reverse[target]!.add(entry.key);
      }
    }
  }
  return reverse;
}

Iterable<String> _directiveUris(Directive directive) sync* {
  if (directive is ImportDirective) {
    yield* _namespaceUris(directive.uri.stringValue, directive.configurations);
  } else if (directive is ExportDirective) {
    yield* _namespaceUris(directive.uri.stringValue, directive.configurations);
  } else if (directive is PartDirective) {
    final uri = directive.uri.stringValue;
    if (uri != null) yield uri;
  }
}

Iterable<String> _namespaceUris(
  String? main,
  Iterable<Configuration> configurations,
) sync* {
  if (main != null) yield main;
  for (final configuration in configurations) {
    final uri = configuration.uri.stringValue;
    if (uri != null) yield uri;
  }
}

String? _resolveUri(
  String uri,
  String importer,
  Map<String, String> sources,
  Map<String, String> packageRoots,
) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    final remainder = uri.substring('package:'.length);
    final slash = remainder.indexOf('/');
    if (slash <= 0) throw const FormatException('Malformed package URI');
    final package = remainder.substring(0, slash);
    final root = packageRoots[package];
    if (root == null) return null;
    final target = _normalizePath(
      '$root/lib/${remainder.substring(slash + 1)}',
      allowParent: true,
    );
    if (!sources.containsKey(target)) {
      throw FormatException('Unresolved workspace URI: $uri');
    }
    return target;
  }
  if (uri.contains(':')) return null;
  final slash = importer.lastIndexOf('/');
  final directory = slash < 0 ? '' : importer.substring(0, slash);
  final target = _normalizePath(
    directory.isEmpty ? uri : '$directory/$uri',
    allowParent: true,
  );
  if (!sources.containsKey(target)) {
    throw FormatException('Unresolved relative URI: $uri');
  }
  return target;
}

Map<String, Set<String>> _mergeGraphs(
  Map<String, Set<String>> first,
  Map<String, Set<String>> second,
) {
  final merged = <String, Set<String>>{};
  for (final graph in [first, second]) {
    for (final entry in graph.entries) {
      merged.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    }
  }
  return merged;
}

Set<String> _currentTestCandidates(
  Map<String, String> sources,
  Map<String, String> packageRoots,
) {
  final candidates = <String>{};
  for (final path in sources.keys.map(_normalizePath)) {
    final root = _packageRootFor(path, packageRoots.values);
    if (root != null && _isCandidateTest(path, root)) {
      candidates.add(path);
    }
  }
  return candidates;
}

bool _isCandidateTest(String path, String root) {
  final prefix = '$root/test/';
  if (!path.startsWith(prefix) || !path.endsWith('.dart')) return false;
  final relative = path.substring(root.length + 1);
  if (relative.startsWith('test/integration/')) return false;
  final rootName = root.split('/').last;
  if (rootName == 'auravibes_server' || rootName.contains('serverpod')) {
    return relative.startsWith('test/features/') ||
        relative.startsWith('test/migrations/');
  }
  return true;
}

void _addReverseClosure(
  String changed,
  Map<String, Set<String>> reverse,
  Set<String> selected,
  Set<String> candidates,
) {
  final visited = <String>{};
  final queue = <String>[changed];
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    if (!visited.add(path)) continue;
    if (candidates.contains(path)) selected.add(path);
    for (final dependent in reverse[path] ?? const <String>{}) {
      if (!visited.contains(dependent)) queue.add(dependent);
    }
  }
}

bool _isSupportedDartPath(String path, Iterable<String> roots) {
  if (!path.endsWith('.dart')) return false;
  return roots.any(
    (root) => path.startsWith('$root/lib/') || path.startsWith('$root/test/'),
  );
}

String? _packageRootFor(String path, Iterable<String> roots) {
  final matches =
      roots
          .where(
            (root) => path.startsWith('$root/test/'),
          )
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  return matches.isEmpty ? null : matches.first;
}

String _normalizePath(String path, {bool allowParent = false}) {
  var normalized = path.replaceAll(r'\', '/');
  if (normalized.startsWith('/') ||
      RegExp('^[A-Za-z]:/').hasMatch(normalized)) {
    throw const FormatException('Absolute path is not repository-relative');
  }
  final parts = <String>[];
  for (final part in normalized.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (!allowParent || parts.isEmpty) {
        throw const FormatException('Path escapes repository root');
      }
      parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  if (parts.isEmpty) throw const FormatException('Empty repository path');
  normalized = parts.join('/');
  return normalized;
}

bool _isDocumentation(String path) {
  final file = path.split('/').last.toLowerCase();
  return file.endsWith('.md') ||
      file.endsWith('.mdx') ||
      file == 'readme' ||
      file == 'changelog' ||
      file == 'changelog.md' ||
      file == 'license' ||
      file == 'license.md';
}

bool _isGlobal(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final file = normalized.split('/').last;
  return normalized.startsWith('.github/') ||
      normalized.startsWith('.fvm/') ||
      normalized == '.fvmrc' ||
      normalized == 'pubspec.yaml' ||
      normalized.endsWith('/pubspec.yaml') ||
      normalized == 'pubspec.lock' ||
      normalized.endsWith('/pubspec.lock') ||
      normalized.endsWith('/analysis_options.yaml') ||
      normalized == 'analysis_options.yaml' ||
      normalized == 'dart_dependency_validator.yaml' ||
      normalized == 'melos.yaml' ||
      normalized == 'build.yaml' ||
      normalized.startsWith('tool/') ||
      file.endsWith('.g.dart') ||
      file.endsWith('.freezed.dart') ||
      file.endsWith('locale_keys.dart') ||
      normalized.contains('/generated/') ||
      file.endsWith('drift_worker.js') ||
      normalized.startsWith('assets/') ||
      normalized.contains('/assets/') ||
      normalized.startsWith('android/') ||
      normalized.startsWith('ios/') ||
      normalized.startsWith('macos/') ||
      normalized.startsWith('windows/') ||
      normalized.startsWith('linux/') ||
      normalized.startsWith('web/');
}
