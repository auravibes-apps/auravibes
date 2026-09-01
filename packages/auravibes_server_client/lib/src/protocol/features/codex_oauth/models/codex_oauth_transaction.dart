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

import 'dart:typed_data' as _i2;

abstract class CodexOAuthTransaction._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var String transactionId,
  required var int workspaceId,
  required var String connectionId,
  required var String userId,
  required var String stateHash,
  required var _i2.ByteData verifierCiphertext,
  required var _i2.ByteData verifierNonce,
  required var _i2.ByteData verifierAuthenticationTag,
  required var String redirectUri,
  required var DateTime expiresAt,
  var DateTime? consumedAt,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required String transactionId,
    required int workspaceId,
    required String connectionId,
    required String userId,
    required String stateHash,
    required _i2.ByteData verifierCiphertext,
    required _i2.ByteData verifierNonce,
    required _i2.ByteData verifierAuthenticationTag,
    required String redirectUri,
    required DateTime expiresAt,
    DateTime? consumedAt,
    required DateTime createdAt,
  }) = _CodexOAuthTransactionImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CodexOAuthTransaction(
      id: jsonSerialization['id'] as int?,
      transactionId: jsonSerialization['transactionId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      userId: jsonSerialization['userId'] as String,
      stateHash: jsonSerialization['stateHash'] as String,
      verifierCiphertext: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierCiphertext'],
      ),
      verifierNonce: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierNonce'],
      ),
      verifierAuthenticationTag: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierAuthenticationTag'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      consumedAt: jsonSerialization['consumedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['consumedAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CodexOAuthTransaction copyWith({
    int? id,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _i2.ByteData? verifierCiphertext,
    _i2.ByteData? verifierNonce,
    _i2.ByteData? verifierAuthenticationTag,
    String? redirectUri,
    DateTime? expiresAt,
    DateTime? consumedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CodexOAuthTransaction',
      if (id != null) 'id': id,
      'transactionId': transactionId,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'userId': userId,
      'stateHash': stateHash,
      'verifierCiphertext': verifierCiphertext.toJson(),
      'verifierNonce': verifierNonce.toJson(),
      'verifierAuthenticationTag': verifierAuthenticationTag.toJson(),
      'redirectUri': redirectUri,
      'expiresAt': expiresAt.toJson(),
      if (consumedAt != null) 'consumedAt': consumedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _CodexOAuthTransactionImpl({
  int? id,
  required String transactionId,
  required int workspaceId,
  required String connectionId,
  required String userId,
  required String stateHash,
  required _i2.ByteData verifierCiphertext,
  required _i2.ByteData verifierNonce,
  required _i2.ByteData verifierAuthenticationTag,
  required String redirectUri,
  required DateTime expiresAt,
  DateTime? consumedAt,
  required DateTime createdAt,
}) extends CodexOAuthTransaction {
  this
    : super._(
        id: id,
        transactionId: transactionId,
        workspaceId: workspaceId,
        connectionId: connectionId,
        userId: userId,
        stateHash: stateHash,
        verifierCiphertext: verifierCiphertext,
        verifierNonce: verifierNonce,
        verifierAuthenticationTag: verifierAuthenticationTag,
        redirectUri: redirectUri,
        expiresAt: expiresAt,
        consumedAt: consumedAt,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CodexOAuthTransaction copyWith({
    Object? id = _Undefined,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _i2.ByteData? verifierCiphertext,
    _i2.ByteData? verifierNonce,
    _i2.ByteData? verifierAuthenticationTag,
    String? redirectUri,
    DateTime? expiresAt,
    Object? consumedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return CodexOAuthTransaction(
      id: id is int? ? id : this.id,
      transactionId: transactionId ?? this.transactionId,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      userId: userId ?? this.userId,
      stateHash: stateHash ?? this.stateHash,
      verifierCiphertext: verifierCiphertext ?? this.verifierCiphertext.clone(),
      verifierNonce: verifierNonce ?? this.verifierNonce.clone(),
      verifierAuthenticationTag:
          verifierAuthenticationTag ?? this.verifierAuthenticationTag.clone(),
      redirectUri: redirectUri ?? this.redirectUri,
      expiresAt: expiresAt ?? this.expiresAt,
      consumedAt: consumedAt is DateTime? ? consumedAt : this.consumedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
