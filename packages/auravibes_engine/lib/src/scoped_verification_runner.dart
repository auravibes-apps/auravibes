import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/src/scoped_verification.dart';
import 'package:auravibes_engine/src/scoped_verification_json.dart';
import 'package:auravibes_engine/src/scoped_verification_paths.dart';

abstract interface class ScopedVerificationRunner {
  Future<ScopedVerificationCapabilities> capabilities();
  Future<ScopedVerificationJob> start(ScopedVerificationRequest request);
  Future<ScopedVerificationJob> poll(String operationId);
  Future<ScopedVerificationJob> cancel(String operationId);
}

/// Optional ownership for host adapters with a dedicated transport client.
abstract interface class ScopedVerificationRunnerLifecycle {
  void close();
}

final class ScopedVerificationCapabilities {
  new({required this.protocol, required Set<String> features})
    : features = Set.unmodifiable(features);

  static const requiredFeatures = {
    'scopedPaths',
    'canonicalContainment',
    'sandboxedCommands',
    'boundedOutput',
    'deadline',
    'cancellation',
    'idempotentStart',
    'cancellationTombstones',
    'nonInteractive',
  };
  final String protocol;
  final Set<String> features;

  factory fromJson(Object? value) {
    final json = verificationObject(value, const {'protocol', 'capabilities'});
    final flags = verificationObject(json['capabilities'], requiredFeatures);
    if (flags.values.any((flag) => flag is! bool)) {
      throw const FormatException('Invalid verification capabilities.');
    }

    return ScopedVerificationCapabilities(
      protocol: verificationString(json['protocol']),
      features: {
        for (final entry in flags.entries)
          if (entry.value == true) entry.key,
      },
    );
  }

  bool get supported =>
      protocol == ScopedVerificationLimits.protocol &&
      features.containsAll(requiredFeatures);
}

final class ScopedVerificationRequest {
  new({
    required this.operationId,
    required this.workspaceRoot,
    required DateTime deadline,
    required List<ScopedVerificationSelection> selections,
    this.maxOutputBytes = 16 * 1024,
  }) : deadline = deadline.toUtc(),
       selections = List.unmodifiable(selections) {
    final _ = verificationString(operationId);
    final _ = verificationString(workspaceRoot);
    final _ = verificationInteger(
      maxOutputBytes,
      min: 1,
      max: ScopedVerificationLimits.maxOutputBytes,
    );
    if (selections.length > ScopedVerificationLimits.maxChecks ||
        selections.map((selection) => selection.check.id).toSet().length !=
            selections.length ||
        selections.any((selection) => selection.paths.isEmpty)) {
      throw const FormatException('Invalid verification selection.');
    }
    final _ = normalizeScopedVerificationPaths(
      selections.expand((selection) => selection.paths).toSet().toList(),
    );
  }

  final String operationId;
  final String workspaceRoot;
  final DateTime deadline;
  final List<ScopedVerificationSelection> selections;
  final int maxOutputBytes;

  Map<String, Object?> toJson() => {
    'protocol': ScopedVerificationLimits.protocol,
    'operationId': operationId,
    'workspaceRoot': workspaceRoot,
    'deadlineMs': deadline.millisecondsSinceEpoch,
    'maxOutputBytes': maxOutputBytes,
    'checks': selections
        .map(
          (selection) => {
            'id': selection.check.id,
            'executable': selection.check.executable,
            'arguments': selection.check.arguments,
            'paths': selection.paths,
          },
        )
        .toList(),
  };
}

enum ScopedVerificationJobState { running, completed, cancelled }

final class ScopedVerificationJob {
  new({
    required this.operationId,
    required this.workspaceRoot,
    required this.state,
    required this.scopeValidated,
    required this.originalOutputBytes,
    Map<String, int> exitCodes = const {},
    this.output = '',
    this.outputTruncated = false,
    this.cancellationRecorded = false,
  }) : exitCodes = Map.unmodifiable(exitCodes) {
    final retainedBytes = utf8.encode(output).length;
    if (exitCodes.length > ScopedVerificationLimits.maxChecks ||
        output.length > ScopedVerificationLimits.maxOutputBytes ||
        retainedBytes > ScopedVerificationLimits.maxOutputBytes ||
        originalOutputBytes < retainedBytes ||
        outputTruncated != (originalOutputBytes > retainedBytes) ||
        (state == .cancelled && !cancellationRecorded)) {
      throw const FormatException('Invalid verification job bounds.');
    }
  }

  final String operationId;
  final String workspaceRoot;
  final ScopedVerificationJobState state;
  final bool scopeValidated;
  final Map<String, int> exitCodes;
  final String output;
  final bool outputTruncated;
  final int originalOutputBytes;

  /// Confirms a durable tombstone that also prevents a delayed start.
  final bool cancellationRecorded;

  factory fromJson(Object? value) {
    final json = verificationObject(value, const {
      'protocol',
      'operationId',
      'workspaceRoot',
      'state',
      'scopeValidated',
      'checks',
      'output',
      'outputTruncated',
      'originalOutputBytes',
      'cancellationRecorded',
    });
    final state = ScopedVerificationJobState.values
        .where((state) => state.name == json['state'])
        .firstOrNull;
    final scope = json['scopeValidated'];
    final output = json['output'];
    final truncated = json['outputTruncated'];
    final checks = json['checks'];
    final cancellationRecorded = json['cancellationRecorded'] ?? false;
    if (json['protocol'] != ScopedVerificationLimits.protocol ||
        state == null ||
        scope is! bool ||
        output is! String ||
        truncated is! bool ||
        checks is! List<Object?> ||
        checks.length > ScopedVerificationLimits.maxChecks ||
        cancellationRecorded is! bool) {
      throw const FormatException('Invalid verification job.');
    }
    final exits = <String, int>{};
    for (final item in checks) {
      final check = verificationObject(item, const {'id', 'exitCode'});
      final id = verificationString(check['id'], maxBytes: 64);
      if (exits.containsKey(id))
        throw const FormatException('Duplicate verification check.');
      exits[id] = verificationInteger(
        check['exitCode'],
        min: -0x80000000,
        max: 0x7fffffff,
      );
    }

    return ScopedVerificationJob(
      operationId: verificationString(json['operationId']),
      workspaceRoot: verificationString(json['workspaceRoot']),
      state: state,
      scopeValidated: scope,
      exitCodes: exits,
      output: output,
      outputTruncated: truncated,
      cancellationRecorded: cancellationRecorded,
      originalOutputBytes: verificationInteger(
        json['originalOutputBytes'],
        min: 0,
        max: 0x1fffffffffffff,
      ),
    );
  }
}

/// Clock and cancellable timer boundary for the verification lifecycle.
abstract interface class ScopedVerificationClock {
  DateTime now();
  Timer schedule(Duration duration, void Function() callback);
}
