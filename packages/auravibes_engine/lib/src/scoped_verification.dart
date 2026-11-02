import 'dart:convert';

import 'package:auravibes_engine/src/scoped_verification_check.dart';
import 'package:auravibes_engine/src/scoped_verification_json.dart';

/// Configuration limits enforced independently of connected tool output.
abstract final class ScopedVerificationLimits {
  static const protocol = 'auravibes.scoped-verification/1';
  static const maxSettingsBytes = 32 * 1024;
  static const maxChecks = 8;
  static const maxPaths = 128;
  static const maxPathBytes = 4096;
  static const maxOutputBytes = 64 * 1024;
  static const maxTimeout = Duration(seconds: 120);
  static const maxRepairAttempts = 2;
}

/// Saved workspace policy. Constructing or decoding it does not run commands.
final class ScopedVerificationSettings {
  new({
    this.enabled = false,
    this.revision = 0,
    this.runnerToolId = '',
    this.mcpServerId = '',
    this.workspaceRoot = '',
    Set<String> editToolIds = const {},
    List<ScopedVerificationCheck> checks = const [],
    this.timeout = const Duration(seconds: 30),
    this.maxOutputBytes = 16 * 1024,
    this.maxRepairAttempts = 1,
  }) : editToolIds = Set.unmodifiable(editToolIds),
       checks = List.unmodifiable(checks) {
    _validateSettings(this);
  }

  factory decode(String source) {
    if (source.length > ScopedVerificationLimits.maxSettingsBytes ||
        utf8.encode(source).length >
            ScopedVerificationLimits.maxSettingsBytes) {
      throw const FormatException('Verification settings exceeded the limit.');
    }
    final json = verificationObject(jsonDecode(source), _settingsKeys);
    final enabled = json['enabled'];
    if (enabled is! bool) {
      throw const FormatException('Invalid verification enabled state.');
    }
    final rawChecks = json['checks'];
    if (rawChecks is! List<Object?> ||
        rawChecks.length > ScopedVerificationLimits.maxChecks) {
      throw const FormatException('Invalid verification checks.');
    }

    return ScopedVerificationSettings(
      enabled: enabled,
      revision: verificationInteger(json['revision'], min: 0, max: 0x7fffffff),
      runnerToolId: _optionalBinding(json['runnerToolId']),
      mcpServerId: _optionalBinding(json['mcpServerId']),
      workspaceRoot: _optionalBinding(json['workspaceRoot']),
      editToolIds: verificationStrings(
        json['editToolIds'],
        maxEntries: 128,
      ).toSet(),
      checks: rawChecks.map(ScopedVerificationCheck.fromJson).toList(),
      timeout: Duration(
        milliseconds: verificationInteger(
          json['timeoutMs'],
          min: 1,
          max: 120000,
        ),
      ),
      maxOutputBytes: verificationInteger(
        json['maxOutputBytes'],
        min: 1,
        max: 65536,
      ),
      maxRepairAttempts: verificationInteger(
        json['maxRepairAttempts'],
        min: 0,
        max: 2,
      ),
    );
  }

  final bool enabled;
  final int revision;
  final String runnerToolId;
  final String mcpServerId;

  /// Opaque runner-owned root identity, never an AuraVibes host path.
  final String workspaceRoot;
  final Set<String> editToolIds;
  final List<ScopedVerificationCheck> checks;
  final Duration timeout;
  final int maxOutputBytes;
  final int maxRepairAttempts;

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'revision': revision,
    'runnerToolId': runnerToolId,
    'mcpServerId': mcpServerId,
    'workspaceRoot': workspaceRoot,
    'editToolIds': editToolIds.toList(),
    'checks': checks.map((check) => check.toJson()).toList(),
    'timeoutMs': timeout.inMilliseconds,
    'maxOutputBytes': maxOutputBytes,
    'maxRepairAttempts': maxRepairAttempts,
  };
}

const _settingsKeys = {
  'enabled',
  'revision',
  'runnerToolId',
  'mcpServerId',
  'workspaceRoot',
  'editToolIds',
  'checks',
  'timeoutMs',
  'maxOutputBytes',
  'maxRepairAttempts',
};

String _optionalBinding(Object? value) {
  if (value is! String) {
    throw const FormatException('Invalid verification binding.');
  }
  validateVerificationString(value, maxBytes: 512);

  return value;
}

void _validateSettings(ScopedVerificationSettings settings) {
  final _ = verificationInteger(settings.revision, min: 0, max: 0x7fffffff);
  final _ = verificationInteger(
    settings.timeout.inMicroseconds,
    min: 1000,
    max: 120000000,
  );
  final _ = verificationInteger(settings.maxOutputBytes, min: 1, max: 65536);
  final _ = verificationInteger(settings.maxRepairAttempts, min: 0, max: 2);
  if (settings.timeout.inMicroseconds % 1000 != 0) {
    throw const FormatException(
      'Verification timeout needs whole milliseconds.',
    );
  }
  for (final binding in [
    settings.runnerToolId,
    settings.mcpServerId,
    settings.workspaceRoot,
  ]) {
    final _ = _optionalBinding(binding);
  }
  final _ = verificationStrings(settings.editToolIds.toList(), maxEntries: 128);
  if (settings.checks.length > ScopedVerificationLimits.maxChecks ||
      settings.checks.map((check) => check.id).toSet().length !=
          settings.checks.length ||
      settings.editToolIds.contains(settings.runnerToolId)) {
    throw const FormatException('Invalid verification check or edit binding.');
  }
  if (settings.enabled &&
      (settings.runnerToolId.isEmpty ||
          settings.mcpServerId.isEmpty ||
          settings.workspaceRoot.isEmpty ||
          settings.editToolIds.isEmpty ||
          settings.checks.isEmpty)) {
    throw const FormatException(
      'Enabled verification needs explicit configuration.',
    );
  }
  if (utf8.encode(settings.encode()).length >
      ScopedVerificationLimits.maxSettingsBytes) {
    throw const FormatException('Verification settings exceeded the limit.');
  }
}
