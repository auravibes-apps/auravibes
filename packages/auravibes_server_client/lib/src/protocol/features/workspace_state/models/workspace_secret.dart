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

import 'dart:typed_data' as _i4;

abstract class WorkspaceSecret._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var _i2.WorkspaceSecretKind secretKind,
  required var _i3.WorkspaceSecretScope scope,
  required var String ownerUserId,
  required var String resourceId,
  required var _i4.ByteData ciphertext,
  required var _i4.ByteData nonce,
  required var _i4.ByteData authenticationTag,
  required var String algorithm,
  required var int keyVersion,
  var String? displaySuffix,
  required var int revision,
  required var DateTime createdAt,
  required var DateTime updatedAt,
  var DateTime? deletedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceSecretKind secretKind,
    required _i3.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _i4.ByteData ciphertext,
    required _i4.ByteData nonce,
    required _i4.ByteData authenticationTag,
    required String algorithm,
    required int keyVersion,
    String? displaySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceSecretImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSecret(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      secretKind: _i2.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _i3.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      ciphertext: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['ciphertext'],
      ),
      nonce: _i1.ByteDataJsonExtension.fromJson(jsonSerialization['nonce']),
      authenticationTag: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['authenticationTag'],
      ),
      algorithm: jsonSerialization['algorithm'] as String,
      keyVersion: jsonSerialization['keyVersion'] as int,
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceSecret copyWith({
    int? id,
    int? workspaceId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _i4.ByteData? ciphertext,
    _i4.ByteData? nonce,
    _i4.ByteData? authenticationTag,
    String? algorithm,
    int? keyVersion,
    String? displaySuffix,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSecret',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      'ownerUserId': ownerUserId,
      'resourceId': resourceId,
      'ciphertext': ciphertext.toJson(),
      'nonce': nonce.toJson(),
      'authenticationTag': authenticationTag.toJson(),
      'algorithm': algorithm,
      'keyVersion': keyVersion,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceSecretImpl({
  int? id,
  required int workspaceId,
  required _i2.WorkspaceSecretKind secretKind,
  required _i3.WorkspaceSecretScope scope,
  required String ownerUserId,
  required String resourceId,
  required _i4.ByteData ciphertext,
  required _i4.ByteData nonce,
  required _i4.ByteData authenticationTag,
  required String algorithm,
  required int keyVersion,
  String? displaySuffix,
  required int revision,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? deletedAt,
}) extends WorkspaceSecret {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        secretKind: secretKind,
        scope: scope,
        ownerUserId: ownerUserId,
        resourceId: resourceId,
        ciphertext: ciphertext,
        nonce: nonce,
        authenticationTag: authenticationTag,
        algorithm: algorithm,
        keyVersion: keyVersion,
        displaySuffix: displaySuffix,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceSecret copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _i4.ByteData? ciphertext,
    _i4.ByteData? nonce,
    _i4.ByteData? authenticationTag,
    String? algorithm,
    int? keyVersion,
    Object? displaySuffix = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceSecret(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      secretKind: secretKind ?? this.secretKind,
      scope: scope ?? this.scope,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      resourceId: resourceId ?? this.resourceId,
      ciphertext: ciphertext ?? this.ciphertext.clone(),
      nonce: nonce ?? this.nonce.clone(),
      authenticationTag: authenticationTag ?? this.authenticationTag.clone(),
      algorithm: algorithm ?? this.algorithm,
      keyVersion: keyVersion ?? this.keyVersion,
      displaySuffix: displaySuffix is String?
          ? displaySuffix
          : this.displaySuffix,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
