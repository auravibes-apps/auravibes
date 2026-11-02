import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

AgentLifecycleHookRuntime createAgentLifecycleHookRuntime() =>
    const AgentLifecycleHookRuntimeIo();

class const AgentLifecycleHookRuntimeIo() implements AgentLifecycleHookRuntime {
  @override
  bool get isSupported =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    if (!isSupported) {
      throw const AgentLifecycleHookConfigException('unsupported_platform');
    }

    final rawConfigFile = File(sourcePath);
    if (!p.isAbsolute(sourcePath)) {
      throw const AgentLifecycleHookConfigException('source_not_absolute');
    }
    final canonicalPath = await rawConfigFile.resolveSymbolicLinks();
    final configBytes = await _readBoundedFile(
      File(canonicalPath),
      maxAgentLifecycleHookConfigBytes,
      'config_too_large',
    );
    final source = utf8.decode(configBytes);
    final config = parseAgentLifecycleHookConfig(source);
    final commandPaths = <AgentLifecycleHookEvent, String>{};
    final commandDigests = <String, String>{};
    final sourceDigests = <String, String>{};
    final sourceFilePaths = <String>[];
    var trustedSourceBytes = configBytes.length;

    for (final hook in config.hooks) {
      final unresolved = p.isAbsolute(hook.command)
          ? hook.command
          : p.join(p.dirname(canonicalPath), hook.command);
      final resolved = await File(unresolved).resolveSymbolicLinks();
      final commandFile = File(resolved);
      if (!commandFile.existsSync()) {
        throw const AgentLifecycleHookConfigException('command_missing');
      }
      final commandBytes = await _readBoundedFile(
        commandFile,
        maxAgentLifecycleHookExecutableBytes,
        'command_too_large',
      );
      trustedSourceBytes += commandBytes.length;
      if (trustedSourceBytes > maxAgentLifecycleHookTrustedSourceBytes) {
        throw const AgentLifecycleHookConfigException('sources_too_large');
      }
      commandPaths[hook.event] = resolved;
      commandDigests[resolved] = sha256.convert(commandBytes).toString();
    }

    for (final sourceFilePath in config.sourceFiles) {
      final unresolved = p.isAbsolute(sourceFilePath)
          ? sourceFilePath
          : p.join(p.dirname(canonicalPath), sourceFilePath);
      final resolved = await File(unresolved).resolveSymbolicLinks();
      final sourceBytes = await _readBoundedFile(
        File(resolved),
        maxAgentLifecycleHookExecutableBytes,
        'source_too_large',
      );
      trustedSourceBytes += sourceBytes.length;
      if (trustedSourceBytes > maxAgentLifecycleHookTrustedSourceBytes) {
        throw const AgentLifecycleHookConfigException('sources_too_large');
      }
      sourceDigests[resolved] = sha256.convert(sourceBytes).toString();
      sourceFilePaths.add(resolved);
    }

    final digestSource = jsonEncode({
      'sourcePath': canonicalPath,
      'configDigest': sha256.convert(configBytes).toString(),
      'commands': [
        for (final path in commandDigests.keys.toList()..sort())
          {'path': path, 'digest': commandDigests[path]},
      ],
      'sourceFiles': [
        for (final path in sourceDigests.keys.toList()..sort())
          {'path': path, 'digest': sourceDigests[path]},
      ],
    });

    return AgentLifecycleHookSourceSnapshot(
      canonicalPath: canonicalPath,
      digest: sha256.convert(utf8.encode(digestSource)).toString(),
      config: config,
      commandPaths: commandPaths,
      sourceFilePaths: sourceFilePaths,
    );
  }

  @override
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    Future<bool> Function()? isStillTrusted,
  }) async {
    if (!isSupported) {
      return const AgentLifecycleHookInvocationResult(outcome: .unavailable);
    }
    if (isCancellationRequested(conversationId)) {
      return const AgentLifecycleHookInvocationResult(outcome: .cancelled);
    }
    if (input.length > maxAgentLifecycleHookInputBytes) {
      return const AgentLifecycleHookInvocationResult(
        outcome: .outputLimitExceeded,
      );
    }
    final inputBytes = utf8.encode(input);
    if (inputBytes.length > maxAgentLifecycleHookInputBytes) {
      return const AgentLifecycleHookInvocationResult(
        outcome: .outputLimitExceeded,
      );
    }

    AgentLifecycleHookSourceSnapshot current;
    try {
      current = await inspect(snapshot.canonicalPath);
    } on Object {
      return const AgentLifecycleHookInvocationResult(outcome: .failed);
    }
    if (current.digest != snapshot.digest) {
      return const AgentLifecycleHookInvocationResult(outcome: .unavailable);
    }
    final currentHook = current.config.hookFor(hook.event);
    final commandPath = current.commandPaths[hook.event];
    if (currentHook == null ||
        commandPath == null ||
        currentHook.command != hook.command ||
        !_sameArguments(currentHook.args, hook.args)) {
      return const AgentLifecycleHookInvocationResult(outcome: .unavailable);
    }
    try {
      if (isStillTrusted != null && !await isStillTrusted()) {
        return const AgentLifecycleHookInvocationResult(outcome: .unavailable);
      }
    } on Object {
      return const AgentLifecycleHookInvocationResult(outcome: .failed);
    }
    if (isCancellationRequested(conversationId)) {
      return const AgentLifecycleHookInvocationResult(outcome: .cancelled);
    }

    Process process;
    try {
      process = await Process.start(
        commandPath,
        hook.args,
        workingDirectory: p.dirname(current.canonicalPath),
        environment: const {},
        includeParentEnvironment: false,
      );
    } on Object {
      return const AgentLifecycleHookInvocationResult(outcome: .failed);
    }

    final outputBuilder = BytesBuilder(copy: false);
    final outputDone = Completer<void>();
    final errorDone = Completer<void>();
    var outputBytes = 0;
    var outcome = AgentToolHookOutcome.success;
    var processExited = false;
    Future<int> trackExit() async {
      final code = await process.exitCode;
      processExited = true;

      return code;
    }
    final exitCodeFuture = trackExit();
    Future<void>? termination;

    Future<void> terminateProcess() => termination ??= () async {
      if (processExited) return;
      try {
        final _ = process.kill();
      } on Object {
        // Continue to the forced termination attempt below.
      }
      try {
        final _ = await exitCodeFuture.timeout(const Duration(milliseconds: 150));

        return;
      } on TimeoutException {
        if (processExited) return;
      }
      try {
        final _ = process.kill(.sigkill);
      } on Object {
        // Some platforms only support terminating the direct child.
      }
      try {
        final _ = await exitCodeFuture.timeout(const Duration(milliseconds: 250));
      } on TimeoutException {
        // The invocation still returns within its hard runtime bound.
      }
    }();

    void fail(AgentToolHookOutcome failure) {
      if (outcome != AgentToolHookOutcome.success) return;
      outcome = failure;
      unawaited(terminateProcess());
    }

    void consume(List<int> chunk, {required bool capture}) {
      if (outcome != AgentToolHookOutcome.success) return;
      outputBytes += chunk.length;
      if (outputBytes > maxAgentLifecycleHookOutputBytes) {
        fail(.outputLimitExceeded);

        return;
      }
      if (capture) outputBuilder.add(chunk);
    }

    final stdoutSubscription = process.stdout.listen(
      (chunk) => consume(chunk, capture: true),
      onError: (Object _) => fail(.failed),
      onDone: outputDone.complete,
      cancelOnError: false,
    );
    final stderrSubscription = process.stderr.listen(
      (chunk) => consume(chunk, capture: false),
      onError: (Object _) => fail(.failed),
      onDone: errorDone.complete,
      cancelOnError: false,
    );
    unawaited(_writeInput(process, inputBytes));

    final timeoutTimer = Timer(agentLifecycleHookTimeout, () {
      fail(.timedOut);
    });
    final cancellationTimer = Timer.periodic(const Duration(milliseconds: 25), (
      _,
    ) {
      if (outcome != AgentToolHookOutcome.success ||
          !isCancellationRequested(conversationId)) {
        return;
      }
      fail(.cancelled);
    });

    int exitCode;
    try {
      exitCode = await exitCodeFuture.timeout(
        agentLifecycleHookTimeout + const Duration(milliseconds: 250),
        onTimeout: () async {
          if (outcome == AgentToolHookOutcome.success) {
            outcome = AgentToolHookOutcome.timedOut;
          }
          await terminateProcess();

          return -1;
        },
      );
    } on Object {
      fail(.failed);
      await terminateProcess();
      exitCode = -1;
    } finally {
      timeoutTimer.cancel();
      cancellationTimer.cancel();
    }

    try {
      final _ = await Future.wait([outputDone.future, errorDone.future])
          .timeout(const Duration(milliseconds: 100));
    } on Object {
      fail(.failed);
      final _ = await stdoutSubscription.cancel();
      final _ = await stderrSubscription.cancel();
    }
    if (outcome == AgentToolHookOutcome.success && exitCode != 0) {
      outcome = AgentToolHookOutcome.failed;
    }
    if (outcome == AgentToolHookOutcome.success &&
        isCancellationRequested(conversationId)) {
      outcome = AgentToolHookOutcome.cancelled;
    }
    if (outcome != AgentToolHookOutcome.success) {
      return AgentLifecycleHookInvocationResult(outcome: outcome);
    }

    try {
      return AgentLifecycleHookInvocationResult(
        outcome: .success,
        stdout: utf8.decode(outputBuilder.takeBytes()),
      );
    } on FormatException {
      return const AgentLifecycleHookInvocationResult(outcome: .failed);
    }
  }
}

Future<Uint8List> _readBoundedFile(
  File file,
  int maxBytes,
  String failureCode,
) async {
  final stat = file.statSync();
  if (stat.type != FileSystemEntityType.file) {
    throw AgentLifecycleHookConfigException(failureCode);
  }
  if (stat.size > maxBytes) {
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

Future<void> _writeInput(Process process, List<int> inputBytes) async {
  try {
    process.stdin.add(inputBytes);
    final _ = await process.stdin.flush();
    final _ = await process.stdin.close();
  } on Object {
    // A hook may exit before consuming its bounded input.
  }
}

bool _sameArguments(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }

  return true;
}
