/// Selection mode for changed-test execution.
enum SelectionMode { full, affected, none }

/// One file row from a Git change range.
class ChangedFile {
  const ChangedFile({
    required this.status,
    this.oldPath,
    this.newPath,
  }) : assert(
         status == 'added' ||
             status == 'modified' ||
             status == 'deleted' ||
             status == 'renamed',
         'Unsupported change status',
       );

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

/// Selects a conservative result from changed paths.
SelectionResult selectChangedTests({
  required List<ChangedFile> changes,
  required Map<String, String> headSources,
  required Map<String, String> baseSources,
  required Map<String, String> packageRoots,
}) {
  // ponytail: graph traversal waits for Task 2; ordinary Dart changes fail
  // closed until analyzer-backed impact selection exists.
  final paths = <String>{
    for (final change in changes)
      ...[change.oldPath, change.newPath].whereType<String>(),
  };

  if (paths.isEmpty || paths.every(_isDocumentation)) {
    return SelectionResult(
      mode: SelectionMode.none,
      packages: const {},
      reason: 'No executable test input.',
    );
  }

  if (paths.any(_isGlobal)) {
    return SelectionResult(
      mode: SelectionMode.full,
      packages: const {},
      reason: 'Global or ambiguous test input.',
    );
  }

  final graphContext = <String>[
    if (headSources.isNotEmpty) 'head',
    if (baseSources.isNotEmpty) 'base',
    if (packageRoots.isNotEmpty) 'packages',
  ].join(', ');
  return SelectionResult(
    mode: SelectionMode.full,
    packages: const {},
    reason: graphContext.isEmpty
        ? 'Static graph selection required.'
        : 'Static graph selection required ($graphContext).',
  );
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

bool _isDocumentation(String path) {
  final file = path.split('/').last.toLowerCase();
  return file.endsWith('.md') ||
      file.endsWith('.mdx') ||
      file == 'changelog' ||
      file == 'changelog.md' ||
      file == 'license' ||
      file == 'license.md';
}

bool _isGlobal(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final file = normalized.split('/').last;
  return file == 'pubspec.yaml' ||
      file == 'pubspec.lock' ||
      file == 'analysis_options.yaml' ||
      file == 'dart_dependency_validator.yaml' ||
      file == 'melos.yaml' ||
      file == 'build.yaml' ||
      file == '.fvmrc' ||
      normalized.startsWith('.github/') ||
      normalized.startsWith('.fvm/') ||
      normalized.startsWith('tool/') ||
      file.endsWith('.g.dart') ||
      file.endsWith('.freezed.dart');
}
