import 'dart:convert';
import 'dart:io';

import 'package:import_sorter/files.dart' as import_files;
import 'package:import_sorter/sort.dart' as import_sorter;
import 'package:path/path.dart' as p;

const _nestedFixturePath =
    'tool/fixtures/import_sorter_workspace/packages/'
    'nested_import_sorter_fixture';
const _nestedFixturePackageName = 'nested_import_sorter_fixture';
const _generatedPluginRegistrant = 'lib/generated_plugin_registrant.dart';
// Keep checks aligned with the repository's separator-free import style.
const _noImportGroupComments = true;

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
      final result = import_sorter.sortImports(
        entry.value.readAsLinesSync(),
        package.name,
        false,
        false,
        _noImportGroupComments,
      );
      if (result.updated) {
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

List<_WorkspacePackage> _workspacePackages(
  Directory root,
  List<String> errors,
) {
  final result = Process.runSync('dart', const [
    'run',
    'melos',
    'list',
    '--json',
    '--relative-paths',
  ], workingDirectory: root.path);
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
    final result = import_sorter.sortImports(
      fixture.readAsLinesSync(),
      _nestedFixturePackageName,
      false,
      false,
      _noImportGroupComments,
    );
    if (!result.updated) {
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
