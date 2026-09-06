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

abstract class CodexOAuthTransaction
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CodexOAuthTransaction._({
    this.id,
    required this.transactionId,
    required this.workspaceId,
    required this.connectionId,
    required this.userId,
    required this.stateHash,
    required this.verifierCiphertext,
    required this.verifierNonce,
    required this.verifierAuthenticationTag,
    required this.redirectUri,
    required this.expiresAt,
    this.consumedAt,
    required this.createdAt,
  });

  factory CodexOAuthTransaction({
    int? id,
    required String transactionId,
    required int workspaceId,
    required String connectionId,
    required String userId,
    required String stateHash,
    required _idt.ByteData verifierCiphertext,
    required _idt.ByteData verifierNonce,
    required _idt.ByteData verifierAuthenticationTag,
    required String redirectUri,
    required DateTime expiresAt,
    DateTime? consumedAt,
    required DateTime createdAt,
  }) = _CodexOAuthTransactionImpl;

  factory CodexOAuthTransaction.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CodexOAuthTransaction(
      id: jsonSerialization['id'] as int?,
      transactionId: jsonSerialization['transactionId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      userId: jsonSerialization['userId'] as String,
      stateHash: jsonSerialization['stateHash'] as String,
      verifierCiphertext: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierCiphertext'],
      ),
      verifierNonce: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierNonce'],
      ),
      verifierAuthenticationTag: _isc.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierAuthenticationTag'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      consumedAt: jsonSerialization['consumedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['consumedAt'],
            ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String transactionId;

  int workspaceId;

  String connectionId;

  String userId;

  String stateHash;

  _idt.ByteData verifierCiphertext;

  _idt.ByteData verifierNonce;

  _idt.ByteData verifierAuthenticationTag;

  String redirectUri;

  DateTime expiresAt;

  DateTime? consumedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CodexOAuthTransaction copyWith({
    int? id,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _idt.ByteData? verifierCiphertext,
    _idt.ByteData? verifierNonce,
    _idt.ByteData? verifierAuthenticationTag,
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
  Map<String, dynamic> toJsonForProtocol() {
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
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CodexOAuthTransactionImpl extends CodexOAuthTransaction {
  _CodexOAuthTransactionImpl({
    int? id,
    required String transactionId,
    required int workspaceId,
    required String connectionId,
    required String userId,
    required String stateHash,
    required _idt.ByteData verifierCiphertext,
    required _idt.ByteData verifierNonce,
    required _idt.ByteData verifierAuthenticationTag,
    required String redirectUri,
    required DateTime expiresAt,
    DateTime? consumedAt,
    required DateTime createdAt,
  }) : super._(
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
  @_isc.useResult
  @override
  CodexOAuthTransaction copyWith({
    Object? id = _Undefined,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _idt.ByteData? verifierCiphertext,
    _idt.ByteData? verifierNonce,
    _idt.ByteData? verifierAuthenticationTag,
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
