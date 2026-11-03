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
      await _save(workspaceId, settings);
    } on ScopedVerificationSettingsException {
      rethrow;
    } on WorkspaceTableException catch (error, stackTrace) {
      _throwSaveFailure(
        error.conflict
            ? LocaleKeys.verification_errors_conflict
            : LocaleKeys.verification_errors_save_failed,
        stackTrace,
      );
    } on Object catch (_, stackTrace) {
      _throwSaveFailure(LocaleKeys.verification_errors_save_failed, stackTrace);
    }
  }

  Future<void> _save(
    String workspaceId,
    ScopedVerificationSettings settings,
  ) async {
    await _ensureLocalWorkspace(workspaceId);
    if (settings.enabled) {
      final deadline = DateTime.now().toUtc().add(probeTimeout);
      await _validateEnabled(
        workspaceId,
        settings,
        deadline,
      ).timeout(probeTimeout);
    }
    await repository.saveSettings(workspaceId, settings);
  }

  Future<void> _ensureLocalWorkspace(String workspaceId) async {
    final isLocal =
        await WorkspaceVerificationReservationHelpers.isLocalVerificationWorkspace(
          repository.database,
          workspaceId,
        );
    if (!isLocal) {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_cloud_unavailable,
      );
    }
  }

  Future<void> _validateEnabled(
    String workspaceId,
    ScopedVerificationSettings settings,
    DateTime deadline,
  ) async {
    await _ensureBindings(workspaceId, settings);
    final capabilities = await _probeCapabilities(
      workspaceId,
      settings,
      deadline,
    );
    _ensureSupported(capabilities);
    await _ensureBindings(workspaceId, settings);
  }

  Future<void> _ensureBindings(
    String workspaceId,
    ScopedVerificationSettings settings,
  ) async {
    if (await validateBindings(workspaceId, settings)) return;
    throw const ScopedVerificationSettingsException(
      LocaleKeys.verification_errors_bindings,
    );
  }

  Future<ScopedVerificationCapabilities> _probeCapabilities(
    String workspaceId,
    ScopedVerificationSettings settings,
    DateTime deadline,
  ) async {
    try {
      final remaining = deadline.difference(DateTime.now().toUtc());
      if (remaining <= .zero) {
        throw TimeoutException('Verification probe expired.');
      }

      return await probeCapabilities(
        workspaceId,
        settings,
        deadline,
      ).timeout(remaining);
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const ScopedVerificationSettingsException(
          LocaleKeys.verification_errors_runner_unavailable,
        ),
        stackTrace,
      );
    }
  }

  void _ensureSupported(ScopedVerificationCapabilities capabilities) {
    if (!capabilities.supported) {
      throw const ScopedVerificationSettingsException(
        LocaleKeys.verification_errors_unsupported_runner,
      );
    }
  }

  Never _throwSaveFailure(String localeKey, StackTrace stackTrace) =>
      Error.throwWithStackTrace(
        ScopedVerificationSettingsException(localeKey),
        stackTrace,
      );
}
