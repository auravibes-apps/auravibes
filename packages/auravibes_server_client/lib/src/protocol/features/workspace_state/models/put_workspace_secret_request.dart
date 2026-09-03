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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

import '../../../features/workspace_state/models/workspace_secret_kind.dart'
    as _i2;
import '../../../features/workspace_state/models/workspace_secret_scope.dart'
    as _i3;

abstract class PutWorkspaceSecretRequest implements _i1.SerializableModel {
  PutWorkspaceSecretRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.secretKind,
    required this.scope,
    required this.resourceId,
    this.secret,
    this.expectedRevision,
  });

  factory PutWorkspaceSecretRequest({
    required int workspaceId,
    required String requestId,
    required _i2.WorkspaceSecretKind secretKind,
    required _i3.WorkspaceSecretScope scope,
    required String resourceId,
    String? secret,
    int? expectedRevision,
  }) = _PutWorkspaceSecretRequestImpl;

  factory PutWorkspaceSecretRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PutWorkspaceSecretRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      secretKind: _i2.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _i3.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      secret: jsonSerialization['secret'] as String?,
      expectedRevision: jsonSerialization['expectedRevision'] as int?,
    );
  }

  int workspaceId;

  String requestId;

  _i2.WorkspaceSecretKind secretKind;

  _i3.WorkspaceSecretScope scope;

  String resourceId;

  String? secret;

  int? expectedRevision;

  /// Returns a shallow copy of this [PutWorkspaceSecretRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PutWorkspaceSecretRequest copyWith({
    int? workspaceId,
    String? requestId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? resourceId,
    String? secret,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PutWorkspaceSecretRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      'resourceId': resourceId,
      if (secret != null) 'secret': secret,
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PutWorkspaceSecretRequestImpl extends PutWorkspaceSecretRequest {
  _PutWorkspaceSecretRequestImpl({
    required int workspaceId,
    required String requestId,
    required _i2.WorkspaceSecretKind secretKind,
    required _i3.WorkspaceSecretScope scope,
    required String resourceId,
    String? secret,
    int? expectedRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         secretKind: secretKind,
         scope: scope,
         resourceId: resourceId,
         secret: secret,
         expectedRevision: expectedRevision,
       );

  /// Returns a shallow copy of this [PutWorkspaceSecretRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PutWorkspaceSecretRequest copyWith({
    int? workspaceId,
    String? requestId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? resourceId,
    Object? secret = _Undefined,
    Object? expectedRevision = _Undefined,
  }) {
    return PutWorkspaceSecretRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      secretKind: secretKind ?? this.secretKind,
      scope: scope ?? this.scope,
      resourceId: resourceId ?? this.resourceId,
      secret: secret is String? ? secret : this.secret,
      expectedRevision: expectedRevision is int?
          ? expectedRevision
          : this.expectedRevision,
    );
  }
}
