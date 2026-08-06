import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

// ponytail: retain UTF-16 slicing without adding characters dependency;
// upgrade to package:characters if these paths become user-facing text.
extension on String {
  String _slice(int start, [int? end]) =>
      String.fromCharCodes(codeUnits.getRange(start, end ?? length));
}

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

  factory SelectionResult.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Manifest must be an object');
    }
    final modeValue = value['mode'];
    final reasonValue = value['reason'];
    if (modeValue is! String ||
        (reasonValue != null && reasonValue is! String)) {
      throw const FormatException('Manifest mode is required');
    }
    final mode = switch (modeValue) {
      'full' => SelectionMode.full,
      'affected' => SelectionMode.affected,
      'none' => SelectionMode.none,
      _ => throw const FormatException('Invalid manifest mode'),
    };
    final rawPackages = value['packages'];
    final packages = <String, List<String>>{};
    if (rawPackages != null) {
      if (rawPackages is! Map) throw const FormatException('Invalid packages');
      for (final entry in rawPackages.entries) {
        if (entry.key is! String ||
            entry.value is! List ||
            (entry.value as List).any((path) => path is! String)) {
          throw const FormatException('Invalid package paths');
        }
        final paths = (entry.value as List).cast<String>();
        if (entry.key == '' || paths.isEmpty) {
          throw const FormatException('Invalid package paths');
        }
        packages[entry.key as String] = paths;
      }
    }
    if (mode != SelectionMode.affected && packages.isNotEmpty) {
      throw const FormatException('Only affected manifests may list packages');
    }
    if (mode == SelectionMode.affected && packages.isEmpty) {
      throw const FormatException('Affected manifest has no packages');
    }

    return SelectionResult(
      mode: mode,
      packages: packages,
      reason: reasonValue as String? ?? '',
    );
  }

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
  if (output.isEmpty) {
    return const [];
  }
  final fields = output.split('\u0000');
  if (fields.last.isEmpty) {
    final _ = fields.removeLast();
  }
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

/// Builds stable, serialized reverse graph for callers that need to inspect it.
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
  Set<String> serverpodPackageRoots = const {},
}) {
  final paths = <String>{};
  try {
    for (final change in changes) {
      if (!_isValidChangedFile(change)) {
        return _full('Malformed changed file record.');
      }
      for (final path in [change.oldPath, change.newPath]) {
        if (path != null) {
          final _ = paths.add(_normalizePath(path));
        }
      }
    }
  } on FormatException {
    return _full('Malformed changed path.');
  }

  if (paths.isEmpty) {
    return SelectionResult(
      mode: SelectionMode.none,
      packages: const {},
      reason: 'No executable test input.',
    );
  }

  if (paths.any(_isGlobal)) {
    return _full('Global or ambiguous test input.');
  }
  if (paths.every(_isDocumentation)) {
    return SelectionResult(
      mode: SelectionMode.none,
      packages: const {},
      reason: 'No executable test input.',
    );
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

    if (_hasOpaqueRuntimeChange(
      changes,
      roots,
      headSources: headSources,
      baseSources: baseSources,
    )) {
      return _full('Known opaque runtime behavior in changed package.');
    }

    final headGraph = _buildReverseGraph(headSources, roots);
    final baseGraph = _buildReverseGraph(baseSources, roots);
    final reverse = _mergeGraphs(headGraph, baseGraph);
    final serverpodRoots = {
      for (final root in serverpodPackageRoots) _normalizePath(root),
    };
    final candidates = _currentTestCandidates(
      headSources,
      roots,
      serverpodPackageRoots: serverpodRoots,
    );
    final selected = <String>{};

    for (final change in changes) {
      for (final path in [change.oldPath, change.newPath]) {
        if (path == null) continue;
        final normalized = _normalizePath(path);
        if (candidates.contains(normalized)) {
          final _ = selected.add(normalized);
        }
        if (!normalized.endsWith('.dart')) continue;
        _addReverseClosure(normalized, reverse, selected, candidates);
      }
    }

    final packages = <String, List<String>>{};
    for (final path in selected.toList()..sort()) {
      final root = _packageRootFor(path, roots.values);
      if (root == null) continue;
      packages
          .putIfAbsent(root, () => [])
          .add(
            path._slice(root.length + 1),
          );
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
  } on Object catch (_) {
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
  bool dryRun = false,
}) async {
  if (selection.mode == SelectionMode.none) return 0;
  try {
    final packages = await _loadPackages(rootPath);
    final groups = <_TestGroup>[];
    if (selection.mode == SelectionMode.full) {
      for (final package in packages) {
        final paths = await _testFiles(package);
        if (paths.isNotEmpty) {
          final _ = groups.add(_TestGroup(package, paths));
        }
      }
    } else {
      for (final entry in selection.packages.entries) {
        final package = packages.firstWhere(
          (candidate) => candidate.relativeRoot == _normalizePath(entry.key),
          orElse: () => throw FormatException('Unknown package: ${entry.key}'),
        );
        final paths = <String>[];
        for (final path in entry.value) {
          final _ = paths.add(await _validateTestPath(package, path));
        }
        if (paths.isNotEmpty) {
          final _ = groups.add(_TestGroup(package, paths));
        }
      }
    }
    final launch = launcher ?? _launchProcess;
    var firstFailure = 0;
    for (var index = 0; index < groups.length; index += 2) {
      final batch = groups.skip(index).take(2);
      final results = await Future.wait(
        batch.map((group) async {
          final command = _command(group);
          if (dryRun) {
            stdout.writeln(
              [command.executable, ...command.arguments].join(' '),
            );

            return 0;
          }
          try {
            return await launch(
              executable: command.executable,
              arguments: command.arguments,
              workingDirectory: group.package.absoluteRoot,
            );
          } on Object catch (_) {
            return 1;
          }
        }),
      );
      for (final result in results) {
        if (result != 0 && firstFailure == 0) firstFailure = result;
      }
    }

    return firstFailure;
  } on Object catch (error) {
    stderr.writeln('changed-test-selector: $error');

    return 2;
  }
}

Future<SelectionResult> selectRepository({
  required String rootPath,
  required String base,
  required String head,
}) async {
  try {
    _validateRevision(base);
    _validateRevision(head);
    final packages = await _loadPackages(rootPath);
    final headSources = await _workspaceSources(packages);
    // ponytail: graph inputs are limited to package lib/test roots; skip
    // unrelated repository Dart files before loading base contents.
    final basePaths = await _git(
      rootPath,
      [
        'ls-tree',
        '-r',
        '--name-only',
        base,
        '--',
        for (final package in packages) ...[
          '${package.relativeRoot}/lib',
          '${package.relativeRoot}/test',
        ],
      ],
    );
    final baseSources = <String, String>{};
    for (final path
        in basePaths.split('\n').where((path) => path.endsWith('.dart'))) {
      final normalized = _normalizePath(path);
      baseSources[normalized] = await _git(rootPath, [
        'show',
        '$base:$normalized',
      ]);
    }
    final diff = await _git(
      rootPath,
      ['diff', '--name-status', '--find-renames', '-z', '$base...$head'],
    );

    return selectChangedTests(
      changes: parseNameStatus(diff),
      headSources: headSources,
      baseSources: baseSources,
      packageRoots: {
        for (final package in packages) package.name: package.relativeRoot,
      },
      serverpodPackageRoots: {
        for (final package in packages.where((package) => package.serverpod))
          package.relativeRoot,
      },
    );
  } on Object catch (error) {
    return _full('Repository snapshot failed: $error');
  }
}

Future<void> main(List<String> args) async {
  try {
    if (args.isEmpty) throw const FormatException('Command is required');
    final options = _options(args.skip(1));
    switch (args.firstOrNull) {
      case 'select':
        _checkOptions(options, const {'base', 'head', 'output'});
        final result = await selectRepository(
          rootPath: Directory.current.path,
          base: _requiredOption(options, 'base'),
          head: _requiredOption(options, 'head'),
        );
        final _ = await File(
          _requiredOption(options, 'output'),
        ).writeAsString(jsonEncode(result.toJson()));
        stderr.writeln('${result.mode.name}: ${result.reason}');
      case 'run':
        _checkOptions(options, const {'manifest', 'dry-run'});
        final result = SelectionResult.fromJson(
          jsonDecode(
            await File(_requiredOption(options, 'manifest')).readAsString(),
          ),
        );
        exitCode = await runSelectedTests(
          result,
          rootPath: Directory.current.path,
          dryRun: options.containsKey('dry-run'),
        );
      default:
        throw FormatException('Unknown command: ${args.firstOrNull}');
    }
  } on Object catch (error) {
    stderr.writeln('changed-test-selector: $error');
    exitCode = 2;
  }
}

class _Package {
  _Package({
    required this.relativeRoot,
    required this.name,
    required this.flutter,
    required this.serverpod,
    required this.absoluteRoot,
  });
  final String relativeRoot;
  final String name;
  final bool flutter;
  final bool serverpod;
  final String absoluteRoot;
}

class _TestGroup {
  _TestGroup(this.package, this.paths);
  final _Package package;
  final List<String> paths;
}

class _Command {
  _Command(this.executable, this.arguments);
  final String executable;
  final List<String> arguments;
}

Future<List<_Package>> _loadPackages(String rootPath) async {
  final root = Directory(rootPath).absolute;
  final lines = await File('${root.path}/pubspec.yaml').readAsLines();
  final members = <String>[];
  var inWorkspace = false;
  for (final line in lines) {
    if (line == 'workspace:') {
      inWorkspace = true;
      continue;
    }
    if (!inWorkspace) continue;
    final match = RegExp(r'^  - (.+)$').firstMatch(line);
    if (match != null) {
      final memberPath = match.group(1);
      if (memberPath != null) {
        final _ = members.add(_normalizePath(memberPath.trim()));
      }
    } else if (line.trim().isNotEmpty && !line.startsWith(' ')) {
      break;
    }
  }
  if (members.isEmpty) throw const FormatException('Workspace list is empty');
  final packages = <_Package>[];
  for (final member in members) {
    final packageRoot = Directory('${root.path}/$member');
    final packageLines = await File(
      '${packageRoot.path}/pubspec.yaml',
    ).readAsLines();
    final nameLine = packageLines.firstWhere(
      (line) => RegExp(r'^name:\s*\S+').hasMatch(line),
      orElse: () => throw FormatException('Package name missing: $member'),
    );
    final name = RegExp(r'^name:\s*(\S+)').firstMatch(nameLine)?.group(1);
    if (name == null) {
      throw FormatException('Package name missing: $member');
    }
    packages.add(
      _Package(
        relativeRoot: member,
        name: name,
        flutter: packageLines.any(
          (line) => RegExp(r'^  flutter:\s*(#.*)?$').hasMatch(line),
        ),
        serverpod: File(
          '${packageRoot.path}/test/integration/test_tools/serverpod_test_tools.dart',
        ).existsSync(),
        absoluteRoot: packageRoot.absolute.path,
      ),
    );
  }

  return packages;
}

Future<Map<String, String>> _workspaceSources(List<_Package> packages) async {
  final sources = <String, String>{};
  for (final package in packages) {
    final root = Directory(package.absoluteRoot);
    if (!root.existsSync()) {
      throw FormatException(
        'Package directory missing: ${package.relativeRoot}',
      );
    }
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      sources['${package.relativeRoot}/${_relativePath(package.absoluteRoot, entity.path)}'] =
          await entity.readAsString();
    }
  }

  return sources;
}

Future<List<String>> _testFiles(_Package package) async {
  final directory = Directory('${package.absoluteRoot}/test');
  if (!directory.existsSync()) return const [];
  final paths = <String>[];
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative = _relativePath(package.absoluteRoot, entity.path);
    if (_allowedTestPath(relative, package.serverpod)) paths.add(relative);
  }

  return paths..sort();
}

Future<String> _validateTestPath(_Package package, String path) async {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.startsWith('file:') ||
      path.contains(r'\')) {
    throw FormatException('Invalid selected test path: $path');
  }
  final relative = _normalizePath(path);
  if (!relative.endsWith('.dart') ||
      !_allowedTestPath(relative, package.serverpod)) {
    throw FormatException('Invalid selected test path: $path');
  }
  final file = File('${package.absoluteRoot}/$relative');
  if (!file.existsSync() || FileSystemEntity.isDirectorySync(file.path)) {
    throw FormatException('Selected test file is missing: $path');
  }
  final resolved = await file.resolveSymbolicLinks();
  final packageResolved = await Directory(
    package.absoluteRoot,
  ).resolveSymbolicLinks();
  final root = packageResolved.endsWith(Platform.pathSeparator)
      ? packageResolved
      : '$packageResolved${Platform.pathSeparator}';
  if (!resolved.startsWith(root)) {
    throw FormatException('Selected test path escapes package: $path');
  }

  return relative;
}

bool _allowedTestPath(String path, bool serverpod) =>
    path.startsWith('test/') &&
    (!serverpod ||
        path.startsWith('test/features/') ||
        path.startsWith('test/migrations/'));

_Command _command(_TestGroup group) => _Command('fvm', [
  if (group.package.flutter) 'flutter' else 'dart',
  'test',
  '--exclude-tags=integration',
  '--concurrency=2',
  '--timeout=30s',
  '--reporter=compact',
  ...group.paths,
]);

Future<int> _launchProcess({
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.stdout.toString().isNotEmpty) stdout.write(result.stdout);
  if (result.stderr.toString().isNotEmpty) stderr.write(result.stderr);

  return result.exitCode;
}

Future<String> _git(String rootPath, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: rootPath,
  );
  if (result.exitCode != 0) {
    throw FormatException(result.stderr.toString().trim());
  }

  return result.stdout.toString();
}

void _validateRevision(String revision) {
  if (revision.isEmpty ||
      revision.startsWith('-') ||
      revision.contains('\u0000')) {
    throw const FormatException('Invalid Git revision');
  }
}

Map<String, String> _options(Iterable<String> arguments) {
  final options = <String, String>{};
  final values = arguments.toList();
  for (var index = 0; index < values.length; index++) {
    final argument = values[index];
    if (argument == '--dry-run') {
      options['dry-run'] = '';
    } else if (argument.startsWith('--') && index + 1 < values.length) {
      options[argument._slice(2)] = values[++index];
    } else {
      throw FormatException('Invalid argument: $argument');
    }
  }

  return options;
}

void _checkOptions(Map<String, String> options, Set<String> allowed) {
  final unknown = options.keys.where((key) => !allowed.contains(key));
  if (unknown.isNotEmpty) {
    throw FormatException('Invalid option: --${unknown.firstOrNull}');
  }
}

String _requiredOption(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw FormatException('--$key is required');
  }

  return value;
}

String _relativePath(String root, String path) {
  final prefix = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';

  return path.startsWith(prefix)
      ? path._slice(prefix.length).replaceAll(Platform.pathSeparator, '/')
      : path.replaceAll(Platform.pathSeparator, '/');
}

SelectionResult _full(String reason) => SelectionResult(
  mode: SelectionMode.full,
  packages: const {},
  reason: reason,
);

bool _hasOpaqueRuntimeChange(
  List<ChangedFile> changes,
  Map<String, String> packageRoots, {
  required Map<String, String> headSources,
  required Map<String, String> baseSources,
}) {
  final productionRoots = <String>{};
  for (final change in changes) {
    for (final path in [change.oldPath, change.newPath]) {
      if (path == null) continue;
      final normalized = _normalizePath(path);
      for (final root in packageRoots.values) {
        if (normalized.startsWith('$root/lib/')) {
          final _ = productionRoots.add(root);
        }
      }
    }
  }
  if (productionRoots.isEmpty) return false;

  for (final sources in [headSources, baseSources]) {
    for (final entry in sources.entries) {
      final path = _normalizePath(entry.key);
      if (productionRoots.any((root) => path.startsWith('$root/')) &&
          _containsOpaqueRuntimeMarker(entry.value)) {
        return true;
      }
    }
  }

  return false;
}

bool _containsOpaqueRuntimeMarker(String source) =>
    // ponytail: this finite marker list bounds known opaque runtimes; unknown
    // dynamic/reflection behavior remains residual risk until explicit marker
    // coverage is added.
    RegExp(
      '''['"]dart:(?:ffi|mirrors|js|js_util|html)['"]''',
    ).hasMatch(source) ||
    RegExp(r'\bDynamicLibrary\b').hasMatch(source) ||
    RegExp(r'\bIsolate\s*\.\s*(?:spawnUri|resolvePackageUri)\b').hasMatch(
      source,
    ) ||
    RegExp(r'''@pragma\s*\(\s*['"]vm:entry-point['"]''').hasMatch(source);

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
  Map<String, String> packageRoots,
) {
  final normalizedSources = _normalizeSources(sources);
  final availableSources = normalizedSources;
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
        final _ = reverse[target]!.add(entry.key);
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
    final remainder = uri._slice('package:'.length);
    final slash = remainder.indexOf('/');
    if (slash <= 0) throw const FormatException('Malformed package URI');
    final package = remainder._slice(0, slash);
    final root = packageRoots[package];
    if (root == null) return null;
    final target = _normalizePath(
      '$root/lib/${remainder._slice(slash + 1)}',
      allowParent: true,
    );
    final libRoot = '$root/lib';
    if (target != libRoot && !target.startsWith('$libRoot/')) {
      throw FormatException('Package URI escapes lib root: $uri');
    }
    if (!sources.containsKey(target)) {
      throw FormatException('Unresolved workspace URI: $uri');
    }

    return target;
  }
  if (uri.contains(':')) return null;
  final slash = importer.lastIndexOf('/');
  final directory = slash < 0 ? '' : importer._slice(0, slash);
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
  Map<String, String> packageRoots, {
  required Set<String> serverpodPackageRoots,
}) {
  final candidates = <String>{};
  for (final path in sources.keys.map(_normalizePath)) {
    final root = _packageRootFor(path, packageRoots.values);
    if (root != null &&
        _isCandidateTest(
          path,
          root,
          serverpod: serverpodPackageRoots.contains(root),
        )) {
      final _ = candidates.add(path);
    }
  }

  return candidates;
}

bool _isCandidateTest(
  String path,
  String root, {
  required bool serverpod,
}) {
  final prefix = '$root/test/';
  if (!path.startsWith(prefix) || !path.endsWith('.dart')) return false;
  final relative = path._slice(root.length + 1);
  if (relative.startsWith('test/integration/')) return false;
  if (serverpod) {
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
  var queueIndex = 0;
  while (queueIndex < queue.length) {
    final path = queue[queueIndex++];
    if (!visited.add(path)) continue;
    if (candidates.contains(path)) {
      final _ = selected.add(path);
    }
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

  return matches.firstOrNull;
}

String _normalizePath(String path, {bool allowParent = false}) {
  final normalized = path.replaceAll(r'\', '/');
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
      final _ = parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  if (parts.isEmpty) throw const FormatException('Empty repository path');

  return parts.join('/');
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

bool _isValidChangedFile(ChangedFile change) => switch (change.status) {
  'added' => change.oldPath == null && change.newPath != null,
  'modified' =>
    change.oldPath != null &&
        change.newPath != null &&
        change.oldPath == change.newPath,
  'deleted' => change.oldPath != null && change.newPath == null,
  'renamed' => change.oldPath != null && change.newPath != null,
  _ => false,
};
