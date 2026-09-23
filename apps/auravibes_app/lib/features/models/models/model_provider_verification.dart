import 'dart:convert';

import 'package:auravibes_app/features/models/models/model_provider_verification_request.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/v7.dart';

export 'package:auravibes_app/features/models/models/model_provider_verification_request.dart';

class const ModelProviderVerification({
  required final String id,
  required final ModelProviderVerificationIdentity identity,
  required final List<String> modelIds,
  required final DateTime expiresAt,
  final String? serverReceipt,
}) {
  static const lifetime = Duration(minutes: 5);

  factory fromRequest({
    required ModelProviderVerificationRequest request,
    required List<String> modelIds,
    String? serverReceipt,
  }) => ModelProviderVerification(
    id: const UuidV7().generate(),
    identity: .fromRequest(request),
    modelIds: List<String>.unmodifiable(modelIds),
    expiresAt: DateTime.now().toUtc().add(lifetime),
    serverReceipt: serverReceipt,
  );

  int get modelCount => modelIds.length;

  bool get isExpired => !DateTime.now().toUtc().isBefore(expiresAt);

  bool matches(ModelProviderVerificationRequest request) =>
      !isExpired && identity.matches(request);

  void requireMatch(ModelProviderVerificationRequest request) {
    if (isExpired) throw const ProviderVerificationExpiredException();
    if (!identity.matches(request)) {
      throw const ProviderVerificationMismatchException();
    }
  }

  static String digestKey(String? key) =>
      sha256.convert(utf8.encode(key?.trim() ?? '')).toString();
}

class const ModelProviderVerificationIdentity({
  required final String workspaceId,
  required final String providerId,
  required final String? connectionId,
  required final int? expectedRevision,
  required final String? url,
  required final String keyDigest,
}) {
  factory fromRequest(ModelProviderVerificationRequest request) => .new(
    workspaceId: request.workspaceId,
    providerId: request.providerId,
    connectionId: request.connectionId,
    expectedRevision: request.expectedRevision,
    url: _normalizedUrl(request.url),
    keyDigest: ModelProviderVerification.digestKey(request.key),
  );

  bool matches(ModelProviderVerificationRequest request) =>
      workspaceId == request.workspaceId &&
      providerId == request.providerId &&
      connectionId == request.connectionId &&
      expectedRevision == request.expectedRevision &&
      url == _normalizedUrl(request.url) &&
      keyDigest == ModelProviderVerification.digestKey(request.key);
}

String? _normalizedUrl(String? url) {
  final value = url?.trim();

  return value == null || value.isEmpty ? null : value;
}

class const ProviderVerificationRequiredException() implements Exception;

class const ProviderVerificationExpiredException() implements Exception;

class const ProviderVerificationMismatchException() implements Exception;
