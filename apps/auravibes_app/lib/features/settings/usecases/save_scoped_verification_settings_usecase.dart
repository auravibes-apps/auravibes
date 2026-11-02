import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_reservations.dart';
import 'package:auravibes_app/domain/exceptions/scoped_verification_settings_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Saving enabled policy probes capabilities only; it never starts a command.
class const SaveScopedVerificationSettingsUsecase({
  required final WorkspaceVerificationRepository repository,
  required final Future<bool> Function(
    String workspaceId,
    ScopedVerificationSettings settings,
  )
  validateBindings,
  required final Future<ScopedVerificationCapabilities> Function(
    String workspaceId,
    ScopedVerificationSettings settings,
    DateTime deadline,
  )
  probeCapabilities,
  final Duration probeTimeout = const Duration(seconds: 10),
}) {
  Future<void> call({
    required String workspaceId,
    required ScopedVerificationSettings settings,
  }) async {
    try {
      if (!await isLocalVerificationWorkspace(
        repository.database,
        workspaceId,
      )) {
        throw const ScopedVerificationSettingsException(
          LocaleKeys.verification_cloud_unavailable,
        );
      }
      if (settings.enabled) {
        final deadline = DateTime.now().toUtc().add(probeTimeout);
        await _validateEnabled(
          workspaceId,
          settings,
          deadline,
        ).timeout(probeTimeout);
      }
      await repository.saveSettings(workspaceId, settings);
    } on ScopedVerificationSettingsException {
      rethrow;
    } on WorkspaceTableException catch (error) {
      throw ScopedVerificationSettingsException(
        error.conflict
            ? LocaleKeys.verification_errors_conflict
            : LocaleKeys.verification_errors_save_failed,
      );
    } on Object {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_save_failed,
      );
    }
  }

  Future<void> _validateEnabled(
    String workspaceId,
    ScopedVerificationSettings settings,
    DateTime deadline,
  ) async {
    if (!await validateBindings(workspaceId, settings)) {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_bindings,
      );
    }
    final ScopedVerificationCapabilities capabilities;
    try {
      final remaining = deadline.difference(DateTime.now().toUtc());
      if (remaining <= Duration.zero)
        throw TimeoutException('Verification probe expired.');
      capabilities = await probeCapabilities(
        workspaceId,
        settings,
        deadline,
      ).timeout(remaining);
    } on Object {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_runner_unavailable,
      );
    }
    if (!capabilities.supported) {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_unsupported_runner,
      );
    }
    if (!await validateBindings(workspaceId, settings)) {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_bindings,
      );
    }
  }
}
