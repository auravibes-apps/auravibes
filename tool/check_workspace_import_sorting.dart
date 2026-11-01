import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:import_sorter/files.dart' as import_files;
import 'package:import_sorter/sort.dart' as import_sorter;
import 'package:path/path.dart' as p;

const _nestedFixturePath =
    'tool/fixtures/import_sorter_workspace/packages/'
    'nested_import_sorter_fixture';
const _generatedPluginRegistrant = 'lib/generated_plugin_registrant.dart';
// Keep checks aligned with the repository's separator-free import style.
const _noImportGroupComments = true;
// Make import_sorter treat Flutter and workspace package URIs as one group.
const _packageUriSortGroup = 'package:workspace_sorting_group/';

void main() {
  final root = Directory.current.absolute;
  final errors = <String>[];
  _verifyNestedPackageFixture(root, errors);

  final packages = _workspacePackages(root, errors);
  if (packages.isEmpty) {
    errors.add('Melos reported no workspace packages to check.');
  }

  var totalDartFiles = 0;
  for (final package in packages) {
    final packageRoot = Directory(
      p.isAbsolute(package.location)
          ? package.location
          : p.join(root.path, package.location),
    ).absolute;
    if (!p.isWithin(root.path, packageRoot.path)) {
      errors.add(
        'Melos package ${package.name} resolves outside the repository: '
        '${package.location}',
      );
      continue;
    }
    if (!packageRoot.existsSync() ||
        !File(p.join(packageRoot.path, 'pubspec.yaml')).existsSync()) {
      errors.add(
        'Melos package ${package.name} is missing its package root: '
        '${package.location}',
      );
      continue;
    }

    final files = import_files.dartFiles(packageRoot.path, const []);
    final generatedPluginRegistrant = p.normalize(
      p.join(packageRoot.path, _generatedPluginRegistrant),
    );
    files.removeWhere(
      (path, _) => p.normalize(path) == generatedPluginRegistrant,
    );
    totalDartFiles += files.length;
    stdout.writeln('Checking ${package.location}: ${files.length} Dart files');
    if (files.isEmpty) {
      errors.add(
        'Melos package ${package.name} has no Dart files in the directories '
        'covered by import_sorter.',
      );
      continue;
    }

    for (final entry in files.entries) {
      if (_hasUnsortedImports(entry.value.readAsStringSync())) {
        errors.add(
          '${p.relative(entry.key, from: root.path)} has unsorted imports.',
        );
      }
    }
  }

  stdout.writeln(
    'Import sorting covered ${packages.length} Melos package roots and '
    '$totalDartFiles Dart files.',
  );
  if (errors.isNotEmpty) {
    errors.forEach(stderr.writeln);
    exitCode = 1;
  }
}

// import_sorter is line-based and treats pre-import comments as source text.
// Feed it normalized AST directives so comments and multiline imports do not
// create false positives.
bool _hasUnsortedImports(String source) {
  final directives = parseString(content: source).unit.directives
      .whereType<ImportDirective>();
  final sorterLines = <String>[];
  String? previousGroup;

  for (final directive in directives) {
    final group = _importGroup(directive.uri.stringValue);
    if (previousGroup != null && group != previousGroup) {
      sorterLines.add('');
    }
    final singleLineDirective = source
        .substring(directive.offset, directive.end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    sorterLines.addAll(_inOnePackageUriGroup([singleLineDirective]));
    previousGroup = group;
  }

  if (sorterLines.isEmpty) return false;
  sorterLines.add('');

  return import_sorter
      .sortImports(sorterLines, '', false, false, _noImportGroupComments)
      .updated;
}

String _importGroup(String? uri) {
  if (uri?.startsWith('dart:') ?? false) return 'dart';
  if (uri?.startsWith('package:') ?? false) return 'package';

  return 'relative';
}

List<String> _inOnePackageUriGroup(List<String> lines) => [
  for (final line in lines)
    if (line.startsWith('import '))
      line.replaceAll('package:', _packageUriSortGroup)
    else
      line,
];

List<_WorkspacePackage> _workspacePackages(
  Directory root,
  List<String> errors,
) {
  const arguments = ['run', 'melos', 'list', '--json', '--relative'];
  final result = Process.runSync(
    'dart',
    arguments,
    workingDirectory: root.path,
  );
  if (result.exitCode != 0) {
    errors.add('Could not list Melos workspace packages.');
    stderr.write(result.stderr);

    return const [];
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(result.stdout as String);
  } on FormatException catch (error) {
    errors.add('Melos package list was not valid JSON: ${error.message}');

    return const [];
  }
  if (decoded is! List) {
    errors.add('Melos package list must be a JSON array.');

    return const [];
  }

  final packages = <_WorkspacePackage>[];
  for (final item in decoded) {
    if (item is! Map<String, dynamic> ||
        item['name'] is! String ||
        item['location'] is! String) {
      errors.add('Melos returned a package without a name and location.');
      continue;
    }
    packages.add(
      _WorkspacePackage(
        name: item['name'] as String,
        location: item['location'] as String,
      ),
    );
  }

  return packages;
}

void _verifyNestedPackageFixture(Directory root, List<String> errors) {
  final fixtureWorkspace = File(
    p.join(root.path, 'tool/fixtures/import_sorter_workspace/pubspec.yaml'),
  );
  final fixtureRoot = Directory(p.join(root.path, _nestedFixturePath));
  final fixturePubspec = File(p.join(fixtureRoot.path, 'pubspec.yaml'));
  final fixtureSource = File(
    p.join(fixtureRoot.path, 'lib/unsorted_imports.dart.fixture'),
  );
  if (!fixtureWorkspace.existsSync() ||
      !fixturePubspec.existsSync() ||
      !fixtureSource.existsSync()) {
    errors.add('Nested import-sorter workspace fixture is incomplete.');

    return;
  }

  final packageRoot = Directory.systemTemp.createTempSync(
    'import_sorter_nested_package_',
  );
  try {
    final _ = fixturePubspec.copySync(p.join(packageRoot.path, 'pubspec.yaml'));
    final lib = Directory(p.join(packageRoot.path, 'lib'))
      ..createSync(recursive: true);
    final _ = fixtureSource.copySync(p.join(lib.path, 'unsorted_imports.dart'));
    final files = import_files.dartFiles(packageRoot.path, const []);
    if (files.length != 1) {
      errors.add(
        'Nested import-sorter package fixture should scan one Dart file; '
        'found ${files.length}.',
      );

      return;
    }

    final fixture = files.values.single;
    if (!_hasUnsortedImports(fixture.readAsStringSync())) {
      errors.add(
        'Nested import-sorter package fixture no longer has unsorted imports.',
      );

      return;
    }
  } finally {
    packageRoot.deleteSync(recursive: true);
  }
  stdout.writeln('Nested package fixture: unsorted imports were detected.');
}

class _WorkspacePackage {
  const new({required this.name, required this.location});

  final String name;
  final String location;
}
