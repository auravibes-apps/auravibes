/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../../../features/workspace_state/models/workspace_patch_operation.dart'
    as _i2;
import '../../../features/workspace_state/models/workspace_secret_kind.dart'
    as _i3;
import '../../../features/workspace_state/models/workspace_secret_scope.dart'
    as _i4;
import 'package:auravibes_server/src/generated/protocol.dart' as _i5;

abstract class MutateWorkspaceCredentialRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MutateWorkspaceCredentialRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.resourceOperation,
    required this.secretKind,
    required this.scope,
    this.secret,
    required this.clearSecret,
    this.expectedSecretRevision,
  });

  factory MutateWorkspaceCredentialRequest({
    required int workspaceId,
    required String requestId,
    required _i2.WorkspacePatchOperation resourceOperation,
    required _i3.WorkspaceSecretKind secretKind,
    required _i4.WorkspaceSecretScope scope,
    String? secret,
    required bool clearSecret,
    int? expectedSecretRevision,
  }) = _MutateWorkspaceCredentialRequestImpl;

  factory MutateWorkspaceCredentialRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MutateWorkspaceCredentialRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      resourceOperation: _i5.Protocol()
          .deserialize<_i2.WorkspacePatchOperation>(
            jsonSerialization['resourceOperation'],
          ),
      secretKind: _i3.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _i4.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      secret: jsonSerialization['secret'] as String?,
      clearSecret: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['clearSecret'],
      ),
      expectedSecretRevision:
          jsonSerialization['expectedSecretRevision'] as int?,
    );
  }

  int workspaceId;

  String requestId;

  _i2.WorkspacePatchOperation resourceOperation;

  _i3.WorkspaceSecretKind secretKind;

  _i4.WorkspaceSecretScope scope;

  String? secret;

  bool clearSecret;

  int? expectedSecretRevision;

  /// Returns a shallow copy of this [MutateWorkspaceCredentialRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MutateWorkspaceCredentialRequest copyWith({
    int? workspaceId,
    String? requestId,
    _i2.WorkspacePatchOperation? resourceOperation,
    _i3.WorkspaceSecretKind? secretKind,
    _i4.WorkspaceSecretScope? scope,
    String? secret,
    bool? clearSecret,
    int? expectedSecretRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MutateWorkspaceCredentialRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'resourceOperation': resourceOperation.toJson(),
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      if (secret != null) 'secret': secret,
      'clearSecret': clearSecret,
      if (expectedSecretRevision != null)
        'expectedSecretRevision': expectedSecretRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MutateWorkspaceCredentialRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'resourceOperation': resourceOperation.toJsonForProtocol(),
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      if (secret != null) 'secret': secret,
      'clearSecret': clearSecret,
      if (expectedSecretRevision != null)
        'expectedSecretRevision': expectedSecretRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MutateWorkspaceCredentialRequestImpl
    extends MutateWorkspaceCredentialRequest {
  _MutateWorkspaceCredentialRequestImpl({
    required int workspaceId,
    required String requestId,
    required _i2.WorkspacePatchOperation resourceOperation,
    required _i3.WorkspaceSecretKind secretKind,
    required _i4.WorkspaceSecretScope scope,
    String? secret,
    required bool clearSecret,
    int? expectedSecretRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         resourceOperation: resourceOperation,
         secretKind: secretKind,
         scope: scope,
         secret: secret,
         clearSecret: clearSecret,
         expectedSecretRevision: expectedSecretRevision,
       );

  /// Returns a shallow copy of this [MutateWorkspaceCredentialRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MutateWorkspaceCredentialRequest copyWith({
    int? workspaceId,
    String? requestId,
    _i2.WorkspacePatchOperation? resourceOperation,
    _i3.WorkspaceSecretKind? secretKind,
    _i4.WorkspaceSecretScope? scope,
    Object? secret = _Undefined,
    bool? clearSecret,
    Object? expectedSecretRevision = _Undefined,
  }) {
    return MutateWorkspaceCredentialRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      resourceOperation: resourceOperation ?? this.resourceOperation.copyWith(),
      secretKind: secretKind ?? this.secretKind,
      scope: scope ?? this.scope,
      secret: secret is String? ? secret : this.secret,
      clearSecret: clearSecret ?? this.clearSecret,
      expectedSecretRevision: expectedSecretRevision is int?
          ? expectedSecretRevision
          : this.expectedSecretRevision,
    );
  }
}
