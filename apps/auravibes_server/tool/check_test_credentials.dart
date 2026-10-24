// Serverpod owns password precedence; reuse its pinned password loader.

import 'dart:io';

import 'package:serverpod_shared/serverpod_shared.dart';

/// Checks configuration without constructing Serverpod, which can hide errors.
int checkTestCredentials(String serverDirectory) {
  try {
    final passwords = PasswordManager(runMode: 'test').loadPasswords(
      serverDir: serverDirectory,
    );
    if (passwords['database']?.trim().isNotEmpty ?? false) return 0;
    stderr.writeln(
      'Missing test database credential. Set test.database in '
      'config/passwords.yaml or a Serverpod database password environment override.',
    );
  } catch (_) {
    // YAML exceptions may include secret-bearing source lines.
    stderr.writeln(
      'Cannot load test credentials. Check config/passwords.yaml structure '
      'and file permissions; configuration contents are withheld.',
    );
  }
  return 2;
}

void main() {
  if (!File('config/test.yaml').existsSync()) {
    stderr.writeln('Run the integration entrypoint from this worktree.');
    exitCode = 2;
    return;
  }
  exitCode = checkTestCredentials(Directory.current.path);
}
