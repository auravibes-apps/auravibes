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
import 'dart:typed_data' as _idt;

import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/workspace_state/models/workspace_secret_kind.dart'
    as _iffvdh0v;
import '../../../features/workspace_state/models/workspace_secret_scope.dart'
    as _iews8xwg;

abstract class WorkspaceSecret
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceSecret._({
    this.id,
    required this.workspaceId,
    required this.secretKind,
    required this.scope,
    required this.ownerUserId,
    required this.resourceId,
    required this.ciphertext,
    required this.nonce,
    required this.authenticationTag,
    required this.algorithm,
    required this.keyVersion,
    this.displaySuffix,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceSecret({
    int? id,
    required int workspaceId,
    required _iffvdh0v.WorkspaceSecretKind secretKind,
    required _iews8xwg.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _idt.ByteData ciphertext,
    required _idt.ByteData nonce,
    required _idt.ByteData authenticationTag,
    required String algorithm,
    required int keyVersion,
    String? displaySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceSecretImpl;

  factory WorkspaceSecret.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSecret(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      secretKind: _iffvdh0v.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _iews8xwg.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      ciphertext: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['ciphertext'],
      ),
      nonce: _isc.ByteDataJsonExtension.fromJson(jsonSerialization['nonce']),
      authenticationTag: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['authenticationTag'],
      ),
      algorithm: jsonSerialization['algorithm'] as String,
      keyVersion: jsonSerialization['keyVersion'] as int,
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  _iffvdh0v.WorkspaceSecretKind secretKind;

  _iews8xwg.WorkspaceSecretScope scope;

  String ownerUserId;

  String resourceId;

  _idt.ByteData ciphertext;

  _idt.ByteData nonce;

  _idt.ByteData authenticationTag;

  String algorithm;

  int keyVersion;

  String? displaySuffix;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceSecret copyWith({
    int? id,
    int? workspaceId,
    _iffvdh0v.WorkspaceSecretKind? secretKind,
    _iews8xwg.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _idt.ByteData? ciphertext,
    _idt.ByteData? nonce,
    _idt.ByteData? authenticationTag,
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
  Map<String, dynamic> toJsonForProtocol() {
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
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSecretImpl extends WorkspaceSecret {
  _WorkspaceSecretImpl({
    int? id,
    required int workspaceId,
    required _iffvdh0v.WorkspaceSecretKind secretKind,
    required _iews8xwg.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _idt.ByteData ciphertext,
    required _idt.ByteData nonce,
    required _idt.ByteData authenticationTag,
    required String algorithm,
    required int keyVersion,
    String? displaySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
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
  @_isc.useResult
  @override
  WorkspaceSecret copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _iffvdh0v.WorkspaceSecretKind? secretKind,
    _iews8xwg.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _idt.ByteData? ciphertext,
    _idt.ByteData? nonce,
    _idt.ByteData? authenticationTag,
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
