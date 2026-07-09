import 'dart:io';

void main() {
  final violations = <String>[];

  _checkFiles(
    roots: const [
      'packages/auravibes_engine/lib',
      'packages/auravibes_engine/test',
    ],
    forbidden: const [
      'package:flutter',
      'package:hooks_riverpod',
      'package:riverpod',
      'package:drift',
      'package:auravibes_app',
      'package:auravibes_ui',
      'LocaleKeys',
      '.tr(',
    ],
    reason: 'Engine must stay pure Dart and app-neutral.',
    violations: violations,
  );

  _checkFiles(
    roots: const [
      'packages/auravibes_ui/lib',
      'packages/auravibes_ui/test',
    ],
    forbidden: const [
      'package:auravibes_app',
      'package:auravibes_engine',
      'LocaleKeys',
      '.tr(',
      'Repository',
      'Usecase',
      'ProviderRef',
      'WidgetRef',
    ],
    reason: 'UI package must stay domain-agnostic.',
    violations: violations,
  );

  _checkBarrel(
    path: 'packages/auravibes_engine/lib/auravibes_engine.dart',
    violations: violations,
  );

  if (violations.isEmpty) {
    stdout.writeln('Architecture boundaries OK.');

    return;
  }

  stderr.writeln('Architecture boundary violations:');
  for (final violation in violations) {
    stderr.writeln('- $violation');
  }
  exitCode = 1;
}

void _checkFiles({
  required List<String> roots,
  required List<String> forbidden,
  required String reason,
  required List<String> violations,
}) {
  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        for (final token in forbidden) {
          if (!line.contains(token)) {
            continue;
          }
          violations.add(
            '${entity.path}:${index + 1}: `$token` forbidden. $reason',
          );
        }
      }
    }
  }
}

void _checkBarrel({
  required String path,
  required List<String> violations,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    return;
  }

  final lines = file.readAsLinesSync();
  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    if (!line.contains('.freezed.dart') && !line.contains('.g.dart')) {
      continue;
    }
    violations.add(
      '$path:${index + 1}: generated files must not be public exports.',
    );
  }
}
