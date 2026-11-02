import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class const AgentLifecycleHookSourceInspector() {
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    if (!p.isAbsolute(sourcePath)) {
      throw const AgentLifecycleHookConfigException('source_not_absolute');
    }
    final canonicalPath = await File(sourcePath).resolveSymbolicLinks();
    final bytes = await _readBoundedFile(
      .new(canonicalPath), maxAgentLifecycleHookConfigBytes, 'config_too_large',
    );
    final config = parseAgentLifecycleHookConfig(utf8.decode(bytes));
    final sources = _HookSourceDigests(canonicalPath, bytes, config);
    await sources.readCommands();
    await sources.readSourceFiles();

    return sources.snapshot();
  }
}

class _HookSourceDigests {
  new(this.canonicalPath, this.configBytes, this.config)
      : _trustedSourceBytes = configBytes.length;

  final String canonicalPath;
  final Uint8List configBytes;
  final AgentLifecycleHookConfig config;
  final _commandPaths = <AgentLifecycleHookEvent, String>{};
  final _commandDigests = <String, String>{};
  final _sourceDigests = <String, String>{};
  final _sourceFilePaths = <String>[];
  int _trustedSourceBytes;

  Future<void> readCommands() async {
    for (final hook in config.hooks) {
      final resolved = await _resolve(hook.command);
      final file = File(resolved);
      if (!file.existsSync()) {
        throw const AgentLifecycleHookConfigException('command_missing');
      }
      final digest = await _readDigest(file, 'command_too_large');
      _commandPaths[hook.event] = resolved;
      _commandDigests[resolved] = digest;
    }
  }

  Future<void> readSourceFiles() async {
    for (final path in config.sourceFiles) {
      final resolved = await _resolve(path);
      final digest = await _readDigest(.new(resolved), 'source_too_large');
      _sourceDigests[resolved] = digest;
      _sourceFilePaths.add(resolved);
    }
  }

  Future<String> _resolve(String path) => File(
    p.isAbsolute(path) ? path : p.join(p.dirname(canonicalPath), path),
  ).resolveSymbolicLinks();

  Future<String> _readDigest(File file, String failureCode) async {
    final bytes = await _readBoundedFile(
      file, maxAgentLifecycleHookExecutableBytes, failureCode,
    );
    _trustedSourceBytes += bytes.length;
    if (_trustedSourceBytes > maxAgentLifecycleHookTrustedSourceBytes) {
      throw const AgentLifecycleHookConfigException('sources_too_large');
    }

    return sha256.convert(bytes).toString();
  }

  AgentLifecycleHookSourceSnapshot snapshot() => .new(
    canonicalPath: canonicalPath,
    digest: _fingerprint(),
    config: config,
    commandPaths: _commandPaths,
    sourceFilePaths: _sourceFilePaths,
  );

  String _fingerprint() => sha256.convert(utf8.encode(jsonEncode({
    'sourcePath': canonicalPath,
    'configDigest': sha256.convert(configBytes).toString(),
    'commands': _digestEntries(_commandDigests),
    'sourceFiles': _digestEntries(_sourceDigests),
  }))).toString();
}

List<Map<String, String?>> _digestEntries(Map<String, String> digests) => [
  for (final path in digests.keys.toList()..sort())
    {'path': path, 'digest': digests[path]},
];

Future<Uint8List> _readBoundedFile(File file, int maxBytes, String failureCode) async {
  final stat = file.statSync();
  if (stat.type != FileSystemEntityType.file || stat.size > maxBytes) {
    throw AgentLifecycleHookConfigException(failureCode);
  }
  final builder = BytesBuilder(copy: false);
  var totalBytes = 0;
  await for (final chunk in file.openRead()) {
    totalBytes += chunk.length;
    if (totalBytes > maxBytes) {
      throw AgentLifecycleHookConfigException(failureCode);
    }
    builder.add(chunk);
  }

  return builder.takeBytes();
}
