import 'dart:convert';

import 'package:auravibes_engine/src/scoped_verification.dart';
import 'package:auravibes_engine/src/scoped_verification_json.dart';
import 'package:auravibes_engine/src/scoped_verification_paths.dart';

enum ScopedVerificationOutcome { pass, fail, skipped, cancelled, incomplete }

/// Bounded check feedback. A tool's mutation outcome remains independent.
final class ScopedVerificationResult {
  factory ScopedVerificationResult({
    required ScopedVerificationOutcome outcome,
    required String reason,
    String output = '',
    int maxOutputBytes = 16 * 1024,
    int? originalOutputBytes,
    bool outputTruncated = false,
    List<String> checkIds = const [],
    List<String> paths = const [],
    int repairAttemptsRemaining = 0,
  }) {
    final safeCheckIds = verificationStrings(
      checkIds,
      maxEntries: 8,
      maxBytes: 64,
    );
    final safePaths = normalizeScopedVerificationPaths(paths);
    final _ = verificationString(reason, maxBytes: 128);
    final _ = verificationInteger(
      maxOutputBytes,
      min: 1,
      max: ScopedVerificationLimits.maxOutputBytes,
    );
    final _ = verificationInteger(repairAttemptsRemaining, min: 0, max: 2);
    final bytes = utf8.encode(output);
    final originalBytes = originalOutputBytes ?? bytes.length;
    if (originalBytes < bytes.length) {
      throw const FormatException('Invalid verification output byte count.');
    }
    final retained = _boundedOutput(bytes, maxOutputBytes);
    return ScopedVerificationResult._(
      outcome: outcome,
      reason: reason,
      checkIds: safeCheckIds,
      paths: safePaths,
      output: retained,
      originalOutputBytes: originalBytes,
      outputTruncated:
          outputTruncated || originalBytes > utf8.encode(retained).length,
      repairAttemptsRemaining: repairAttemptsRemaining,
    );
  }

  const new _({
    required this.outcome,
    required this.reason,
    required this.checkIds,
    required this.paths,
    required this.output,
    required this.originalOutputBytes,
    required this.outputTruncated,
    required this.repairAttemptsRemaining,
  });

  factory fromJson(Object? value) {
    final json = verificationObject(value, const {
      'state',
      'reason',
      'checkIds',
      'paths',
      'output',
      'outputTruncated',
      'originalOutputBytes',
      'repairAllowed',
      'repairAttemptsRemaining',
    });
    final state = json['state'];
    final outcome = ScopedVerificationOutcome.values
        .where((candidate) => candidate.name == state)
        .firstOrNull;
    final output = json['output'];
    final truncated = json['outputTruncated'];
    if (outcome == null || output is! String || truncated is! bool) {
      throw const FormatException('Invalid verification result.');
    }
    if (output.length > ScopedVerificationLimits.maxOutputBytes ||
        utf8.encode(output).length > ScopedVerificationLimits.maxOutputBytes) {
      throw const FormatException('Verification output exceeded the limit.');
    }
    final result = ScopedVerificationResult(
      outcome: outcome,
      reason: verificationString(json['reason'], maxBytes: 128),
      checkIds: verificationStrings(
        json['checkIds'],
        maxEntries: 8,
        maxBytes: 64,
      ),
      paths: verificationStrings(
        json['paths'],
        maxEntries: 128,
        maxBytes: 4096,
      ),
      output: output,
      maxOutputBytes: ScopedVerificationLimits.maxOutputBytes,
      originalOutputBytes: verificationInteger(
        json['originalOutputBytes'],
        min: 0,
        max: 0x1fffffffffffff,
      ),
      outputTruncated: truncated,
      repairAttemptsRemaining: verificationInteger(
        json['repairAttemptsRemaining'],
        min: 0,
        max: 2,
      ),
    );
    if (result.repairAllowed != json['repairAllowed'] ||
        result.outputTruncated != truncated) {
      throw const FormatException('Contradictory verification result.');
    }

    return result;
  }

  final ScopedVerificationOutcome outcome;
  final String reason;
  final List<String> checkIds;
  final List<String> paths;
  final int repairAttemptsRemaining;
  final String output;
  final int originalOutputBytes;
  final bool outputTruncated;

  bool get repairAllowed => outcome == .fail && repairAttemptsRemaining > 0;

  Map<String, Object?> toJson() => {
    'state': outcome.name,
    'reason': reason,
    'checkIds': checkIds,
    'paths': paths,
    'output': output,
    'outputTruncated': outputTruncated,
    'originalOutputBytes': originalOutputBytes,
    'repairAllowed': repairAllowed,
    'repairAttemptsRemaining': repairAttemptsRemaining,
  };
}

String _boundedOutput(List<int> bytes, int maxBytes) {
  if (bytes.length <= maxBytes) return utf8.decode(bytes);
  var end = maxBytes;
  while (end > 0 && (bytes[end] & 0xc0) == 0x80) {
    end--;
  }

  return utf8.decode(bytes.sublist(0, end));
}
