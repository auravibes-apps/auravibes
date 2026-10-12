import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stores and reads provider failure recovery values in the existing message
/// metadata envelope.
abstract final class ProviderRecoveryMetadata {
  static const String providerErrorKey = 'providerError';
  static const String providerRecoveryKey = 'providerRecovery';

  /// Whether a message carries provider failure provenance.
  static bool isProviderError(MessageEntity message) =>
      isProviderErrorMetadata(message.metadata?.modelMetadata);

  /// Whether a serialized message metadata map carries provider provenance.
  static bool isProviderErrorMetadata(Map<String, Object?>? modelMetadata) =>
      modelMetadata?[providerErrorKey] == true;

  /// Attaches provider recovery data while preserving other message metadata.
  static MessageMetadataEntity attach(
    MessageMetadataEntity? previous,
    ProviderFailureRecovery recovery,
  ) => (previous ?? const MessageMetadataEntity()).copyWith(
    modelMetadata: {
      ...?previous?.modelMetadata,
      providerErrorKey: true,
      providerRecoveryKey: recovery.toJson(),
    },
  );

  /// Reads a known category. Unknown or malformed values use generic guidance.
  static ProviderFailureCategory? categoryFor(MessageEntity message) {
    final recovery = message
        .metadata
        ?.modelMetadata[ProviderRecoveryMetadata.providerRecoveryKey];
    if (recovery is! Map<Object?, Object?>) return null;
    final classification = recovery['classification'];
    if (classification is! String) return null;

    for (final category in ProviderFailureCategory.values) {
      if (category.wireValue == classification) return category;
    }

    return null;
  }

  /// Keeps legacy retries except when provider recovery explicitly forbids one.
  static bool isRetryEligible(MessageEntity message) =>
      isRetryEligibleMetadata(message.metadata?.modelMetadata);

  /// Whether provider retry metadata allows a caller to dispatch another turn.
  static bool isRetryEligibleMetadata(Map<String, Object?>? modelMetadata) {
    final recovery = modelMetadata?[providerRecoveryKey];
    if (recovery is Map<Object?, Object?>) {
      return _retryEligibilityFor(recovery);
    }

    return !isProviderErrorMetadata(modelMetadata);
  }

  static bool _retryEligibilityFor(Map<Object?, Object?> recovery) =>
      switch (recovery['classification']) {
        'authentication' || 'configuration' || 'unknown' => false,
        'transient_outage' => recovery['retryable'] == true,
        'quota_rate_limit' =>
          recovery['retryable'] == true && _hasExplicitQuotaRetry(recovery),
        _ => false,
      };

  static bool _hasExplicitQuotaRetry(Map<Object?, Object?> recovery) {
    final retryAfterSeconds = recovery['retryAfterSeconds'];

    return retryAfterSeconds is int && retryAfterSeconds >= 0;
  }
}
