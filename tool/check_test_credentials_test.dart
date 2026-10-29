import 'dart:io';

import 'package:test/test.dart';

void main() {
  final root = Directory.current.absolute.path;
  final server = Directory.systemTemp.createTempSync('server-credentials-');

  setUp(() {
    Directory('${server.path}/config').createSync(recursive: true);
    File('${server.path}/config/test.yaml').writeAsStringSync('');
  });
  tearDown(() => server.deleteSync(recursive: true));

  Future<ProcessResult> check({Map<String, String> environment = const {}}) {
    return Process.run(
      Platform.resolvedExecutable,
      [
        '--packages=$root/.dart_tool/package_config.json',
        '$root/apps/auravibes_server/tool/check_test_credentials.dart',
      ],
      workingDirectory: server.path,
      includeParentEnvironment: false,
      environment: environment,
    );
  }

  test('missing credentials fail with an actionable message', () async {
    final result = await check();
    expect(result.exitCode, 2);
    expect(result.stderr, contains('Missing test database credential'));
  });

  test(
    'test overrides shared credentials through the Serverpod loader',
    () async {
      File('${server.path}/config/passwords.yaml').writeAsStringSync(
        'shared:\n  database: shared-secret\ntest:\n  database: ""\n',
      );
      expect((await check()).exitCode, 2);
      File('${server.path}/config/passwords.yaml').writeAsStringSync(
        'shared:\n  database: shared-secret\ntest:\n  database: test-secret\n',
      );
      final result = await check();
      expect(result.exitCode, 0);
      expect('${result.stdout}${result.stderr}', isEmpty);
    },
  );

  test(
    'both Serverpod environment overrides work without a password file',
    () async {
      for (final key in [
        'SERVERPOD_DATABASE_PASSWORD',
        'SERVERPOD_PASSWORD_database',
      ]) {
        final result = await check(environment: {key: 'environment-secret'});
        expect(result.exitCode, 0);
        expect('${result.stdout}${result.stderr}', isEmpty);
      }
    },
  );

  test('custom override takes precedence over the standard override', () async {
    final result = await check(
      environment: {
        'SERVERPOD_DATABASE_PASSWORD': 'standard-secret',
        'SERVERPOD_PASSWORD_database': '',
      },
    );
    expect(result.exitCode, 2);
    expect(
      '${result.stdout}${result.stderr}',
      isNot(contains('standard-secret')),
    );
  });

  test(
    'malformed configuration hides source text even with an override',
    () async {
      File('${server.path}/config/passwords.yaml')
          .writeAsStringSync('test:\n  database: [secret-source-text\n');
      final result = await check(
        environment: {'SERVERPOD_PASSWORD_database': 'override-secret'},
      );
      expect(result.exitCode, 2);
      expect(result.stderr, contains('Cannot load test credentials'));
      expect(
        '${result.stdout}${result.stderr}',
        isNot(contains('secret-source-text')),
      );
      expect(
        '${result.stdout}${result.stderr}',
        isNot(contains('override-secret')),
      );
    },
  );

  test('invalid credential type hides values', () async {
    File('${server.path}/config/passwords.yaml')
        .writeAsStringSync('test:\n  database: [secret-value]\n');
    final result = await check();
    expect(result.exitCode, 2);
    expect('${result.stdout}${result.stderr}', isNot(contains('secret-value')));
  });

  test('wrong package fails before loading configuration', () async {
    File('${server.path}/config/test.yaml').deleteSync();
    final result = await check();
    expect(result.exitCode, 2);
    expect(result.stderr, contains('Run the integration entrypoint'));
  });
}
