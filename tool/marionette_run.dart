import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

const _defaultServerUrl = 'http://localhost:8080/';
final _vmServiceUriPattern = RegExp(r'ws://[^\s]+/ws');

Future<void> main(List<String> args) async {
  try {
    final options = _RunOptions.parse(args);
    await _runMarionetteApp(options);
  } on Object catch (error) {
    stderr.writeln('Marionette launch failed: $error');
    exitCode = 64;
  }
}

/// Extracts the VM service URI emitted by `flutter run`.
String? extractVmServiceUri(String output) {
  return _vmServiceUriPattern.firstMatch(output)?.group(0);
}

Future<void> _runMarionetteApp(_RunOptions options) async {
  final rootPath = Directory.current.path;
  final instanceId = options.instanceId ?? _newInstanceId();
  _validateInstanceId(instanceId);

  final manifestFile = File(
    p.join(
      rootPath,
      '.dart_tool',
      'marionette',
      'instances',
      '$instanceId.json',
    ),
  );
  if (manifestFile.existsSync()) {
    throw StateError(
      'Instance manifest already exists: ${manifestFile.path}. '
      'Choose a different --instance-id or remove the stale manifest.',
    );
  }

  final device = options.device;
  final flutterArguments = <String>[
    'flutter',
    'run',
    '--flavor',
    'dev',
    '--dart-define=AURAVIBES_SERVER_URL=$_defaultServerUrl',
    '--dart-define=DB_HASH_SOURCE=$rootPath',
    '--dart-define=ENABLE_MARIONETTE=true',
    '--dart-define=AURAVIBES_MARIONETTE_INSTANCE_ID=$instanceId',
    if (device != null) ...['-d', device],
  ];
  final process = await Process.start(
    'fvm',
    flutterArguments,
    workingDirectory: p.join(rootPath, 'apps', 'auravibes_app'),
  );

  manifestFile.parent.createSync(recursive: true);
  final startedAt = DateTime.now().toUtc().toIso8601String();
  String? vmServiceUri;
  _writeManifest(
    manifestFile: manifestFile,
    instanceId: instanceId,
    pid: process.pid,
    vmServiceUri: vmServiceUri,
    startedAt: startedAt,
  );

  stdout
    ..writeln('AURAVIBES_MARIONETTE_INSTANCE_ID=$instanceId')
    ..writeln('AURAVIBES_MARIONETTE_MANIFEST=${manifestFile.path}');

  var outputBuffer = '';
  final stdoutSubscription = process.stdout.transform(utf8.decoder).listen((
    chunk,
  ) {
    stdout.write(chunk);
    outputBuffer = '$outputBuffer$chunk';
    if (outputBuffer.length > 8192) {
      final codePoints = outputBuffer.runes.toList(growable: false);
      outputBuffer = String.fromCharCodes(
        codePoints.skip(codePoints.length - 8192),
      );
    }

    final uri = extractVmServiceUri(outputBuffer);
    if (uri == null || uri == vmServiceUri) return;

    vmServiceUri = uri;
    _writeManifest(
      manifestFile: manifestFile,
      instanceId: instanceId,
      pid: process.pid,
      vmServiceUri: uri,
      startedAt: startedAt,
    );
    stdout.writeln('AURAVIBES_MARIONETTE_VM_SERVICE_URI=$uri');
  });
  final stderrSubscription = process.stderr
      .transform(utf8.decoder)
      .listen(stderr.write);
  unawaited(stdin.pipe(process.stdin));

  try {
    exitCode = await process.exitCode;
  } finally {
    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();
    if (manifestFile.existsSync()) manifestFile.deleteSync();
  }
}

void _writeManifest({
  required File manifestFile,
  required String instanceId,
  required int pid,
  required String? vmServiceUri,
  required String startedAt,
}) {
  final manifest = <String, Object?>{
    'instanceId': instanceId,
    'pid': pid,
    'vmServiceUri': vmServiceUri,
    'startedAt': startedAt,
  };
  manifestFile.writeAsStringSync('${jsonEncode(manifest)}\n');
}

String _newInstanceId() {
  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
    36,
  );
  final nonce = Random.secure().nextInt(1 << 32).toRadixString(36);

  return 'agent-$timestamp-$nonce';
}

void _validateInstanceId(String instanceId) {
  final valid = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')
      .hasMatch(instanceId);
  if (!valid) {
    throw const FormatException(
      'Invalid instance ID. Use 1-64 letters, numbers, dot, underscore, '
      'or dash.',
    );
  }
}

class _RunOptions {
  const new({this.instanceId, this.device});

  factory parse(List<String> args) {
    String? instanceId;
    String? device;

    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      switch (argument) {
        case '--instance-id':
          instanceId = _nextValue(args, ++index, argument);
        case '--device':
          device = _nextValue(args, ++index, argument);
        case '--help':
          stdout.writeln(
            'Usage: dart run tool/marionette_run.dart '
            '[--instance-id ID] [--device DEVICE]',
          );
          exit(0);
        default:
          throw FormatException('Unknown argument: $argument');
      }
    }

    return .new(instanceId: instanceId, device: device);
  }

  final String? instanceId;
  final String? device;

  static String _nextValue(List<String> args, int index, String option) {
    if (index >= args.length || args[index].startsWith('--')) {
      throw FormatException('Missing value for $option.');
    }

    return args[index];
  }
}
