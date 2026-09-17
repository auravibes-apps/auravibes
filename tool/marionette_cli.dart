import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const _cliPackage = 'marionette_cli:marionette';
const _requiredAppFlavor = 'dev';
const _identityExtension = 'ext.flutter.auravibes.instanceIdentity';
const _localHosts = {'127.0.0.1', '::1', 'localhost'};
const _registryCommands = {'doctor', 'list', 'mcp', 'register', 'unregister'};
final _instanceIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$');

Future<void> main(List<String> args) async {
  MarionetteCliOptions? parsedOptions;
  try {
    final options = MarionetteCliOptions.parse(args);
    parsedOptions = options;
    if (options.showHelp) {
      stdout.writeln(
        'Usage: fvm dart run tool/marionette_cli.dart '
        '--instance-id ID COMMAND [ARGUMENTS]',
      );

      return;
    }

    final rootPath = Directory.current.path;
    final manifest = loadMarionetteInstanceManifest(
      rootPath,
      options.instanceId,
    );
    stderr.writeln(
      'Marionette CLI instance "${manifest.instanceId}" '
      'state=connecting uri=selected-manifest',
    );

    try {
      await verifyMarionetteInstance(manifest).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'Identity check timed out for instance "${manifest.instanceId}" '
          'at ${manifest.vmServiceUri}.',
        ),
      );
      final result = await runMarionetteCli(
        rootPath: rootPath,
        uri: manifest.vmServiceUri,
        commandArgs: options.commandArgs,
      );
      if (result != 0) {
        stderr.writeln(
          'Marionette CLI instance "${manifest.instanceId}" '
          'state=failed exitCode=$result',
        );
      }
      stderr.writeln(
        'Marionette CLI instance "${manifest.instanceId}" '
        'state=disconnected exitCode=$result',
      );
      exitCode = result;
    } on Object catch (error) {
      stderr
        ..writeln(
          'Marionette CLI instance "${manifest.instanceId}" '
          'state=failed: $error',
        )
        ..writeln(
          'Marionette CLI instance "${manifest.instanceId}" '
          'state=disconnected',
        );
      exitCode = 1;
    }
  } on FormatException catch (error) {
    _writeCliFailure(parsedOptions?.instanceId, error);
    exitCode = 64;
  } on Object catch (error) {
    _writeCliFailure(parsedOptions?.instanceId, error);
    exitCode = 64;
  }
}

class MarionetteCliOptions {
  const new({
    required this.instanceId,
    required this.commandArgs,
    this.showHelp = false,
  });

  factory parse(List<String> args) {
    if (args.length == 1 && args.firstOrNull == '--help') {
      return const .new(instanceId: '', commandArgs: [], showHelp: true);
    }

    String? instanceId;
    var commandArgs = <String>[];
    var index = 0;
    while (index < args.length) {
      final argument = args[index];
      if (argument == '--instance-id') {
        if (instanceId != null) {
          throw const FormatException('Only one --instance-id is allowed.');
        }
        if (++index >= args.length || args[index].startsWith('--')) {
          throw const FormatException('Missing value for --instance-id.');
        }
        instanceId = args[index];
        index++;
        continue;
      }
      commandArgs = argument == '--'
          ? args.sublist(index + 1)
          : args.sublist(index);
      break;
    }

    if (instanceId == null) {
      throw const FormatException(
        '--instance-id is required; the wrapper never discovers instances.',
      );
    }
    _validateInstanceId(instanceId);
    _validateCommand(commandArgs);

    return .new(instanceId: instanceId, commandArgs: commandArgs);
  }

  final String instanceId;
  final List<String> commandArgs;
  final bool showHelp;
}

class MarionetteInstanceManifest {
  const new({
    required this.instanceId,
    required this.pid,
    required this.appFlavor,
    required this.marionetteEnabled,
    required this.vmServiceUri,
  });

  factory fromJson(
    Map<String, dynamic> json, {
    required String expectedInstanceId,
  }) {
    final instanceId = json['instanceId'];
    if (instanceId is! String || instanceId != expectedInstanceId) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=rejected: '
        'manifest instanceId is "$instanceId".',
      );
    }

    final appFlavor = json['appFlavor'];
    final marionetteEnabled = json['marionetteEnabled'];
    if (appFlavor is! String || marionetteEnabled is! bool) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=rejected: '
        'manifest metadata is invalid.',
      );
    }
    if (appFlavor != _requiredAppFlavor || !marionetteEnabled) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=rejected: '
        'manifest is not an AuraVibes dev Marionette launch.',
      );
    }

    final pid = json['pid'];
    if (pid is! int || pid <= 0) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=rejected: '
        'manifest PID is invalid.',
      );
    }

    final vmServiceUri = json['vmServiceUri'];
    if (vmServiceUri is! String || vmServiceUri.isEmpty) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=starting: '
        'VM service URI is not available yet.',
      );
    }
    if (!_isLocalVmServiceUri(vmServiceUri)) {
      throw FormatException(
        'Marionette CLI instance "$expectedInstanceId" state=rejected: '
        'VM service URI must be a local ws:// dev endpoint.',
      );
    }

    return .new(
      instanceId: instanceId,
      pid: pid,
      appFlavor: appFlavor,
      marionetteEnabled: marionetteEnabled,
      vmServiceUri: vmServiceUri,
    );
  }

  final String instanceId;
  final int pid;
  final String appFlavor;
  final bool marionetteEnabled;
  final String vmServiceUri;
}

MarionetteInstanceManifest loadMarionetteInstanceManifest(
  String rootPath,
  String instanceId,
) {
  _validateInstanceId(instanceId);
  final manifestPath = p.join(
    rootPath,
    '.dart_tool',
    'marionette',
    'instances',
    '$instanceId.json',
  );
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    throw FormatException(
      'Marionette CLI instance "$instanceId" state=disconnected: '
      'manifest not found at $manifestPath.',
    );
  }

  final decoded = jsonDecode(manifestFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('manifest must contain a JSON object.');
  }

  return MarionetteInstanceManifest.fromJson(
    decoded,
    expectedInstanceId: instanceId,
  );
}

List<String> buildMarionetteCliArguments(String uri, List<String> commandArgs) {
  return ['run', _cliPackage, '--uri', uri, ...commandArgs];
}

Future<int> runMarionetteCli({
  required String rootPath,
  required String uri,
  required List<String> commandArgs,
}) async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    buildMarionetteCliArguments(uri, commandArgs),
    workingDirectory: rootPath,
    mode: .inheritStdio,
  );

  return await process.exitCode;
}

Future<void> verifyMarionetteInstance(
  MarionetteInstanceManifest manifest,
) async {
  final service = await vmServiceConnectUri(manifest.vmServiceUri);
  try {
    final isolateId = await _findIdentityIsolate(service);
    if (isolateId == null) {
      throw StateError(
        'selected URI does not expose the AuraVibes instance identity '
        'extension.',
      );
    }

    final response = await service.callServiceExtension(
      _identityExtension,
      isolateId: isolateId,
    );
    final actualInstanceId = response.json?['instanceId'];
    if (actualInstanceId != manifest.instanceId) {
      throw StateError(
        'instance identity mismatch: expected "${manifest.instanceId}", '
        'got "$actualInstanceId".',
      );
    }
  } finally {
    await service.dispose();
  }
}

Future<String?> _findIdentityIsolate(VmService service) async {
  final vm = await service.getVM();
  for (final isolateRef in vm.isolates ?? <IsolateRef>[]) {
    final isolateId = isolateRef.id;
    if (isolateId == null) continue;
    final isolate = await service.getIsolate(isolateId);
    if (isolate.extensionRPCs?.contains(_identityExtension) ?? false) {
      return isolateId;
    }
  }

  return null;
}

void _validateCommand(List<String> commandArgs) {
  final command = commandArgs.firstOrNull;
  if (command == null || command.startsWith('-')) {
    throw const FormatException('A Marionette command is required.');
  }
  if (_registryCommands.contains(command)) {
    throw FormatException(
      'The "$command" command is disabled; use the selected manifest '
      'instead of Marionette global instance discovery.',
    );
  }
  for (final argument in commandArgs.skip(1)) {
    if (argument == '--uri' ||
        argument.startsWith('--uri=') ||
        argument == '--instance' ||
        argument.startsWith('--instance=') ||
        argument == '-i') {
      throw const FormatException(
        'URI and instance overrides are disabled; use --instance-id.',
      );
    }
  }
}

void _validateInstanceId(String instanceId) {
  if (!_instanceIdPattern.hasMatch(instanceId)) {
    throw const FormatException(
      'Invalid instance ID. Use 1-64 letters, numbers, dot, underscore, '
      'or dash.',
    );
  }
}

bool _isLocalVmServiceUri(String value) {
  final uri = Uri.tryParse(value);

  return uri != null &&
      uri.scheme == 'ws' &&
      _localHosts.contains(uri.host) &&
      uri.path.endsWith('/ws');
}

void _writeCliFailure(String? instanceId, Object error) {
  if (instanceId == null) {
    stderr.writeln('Marionette CLI failed: $error');

    return;
  }

  stderr.writeln('Marionette CLI instance "$instanceId" state=failed: $error');
}
