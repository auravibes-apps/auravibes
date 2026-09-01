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

abstract class ConversationJob._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var int conversationId,
  var int? turnId,
  required var String requestId,
  required var String kind,
  required var String status,
  var String? payloadJson,
  required var int attempt,
  required var int maxAttempts,
  required var DateTime availableAt,
  var String? leaseOwner,
  var String? leaseToken,
  var DateTime? leaseExpiresAt,
  var String? checkpointJson,
  var String? lastErrorCode,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required int conversationId,
    int? turnId,
    required String requestId,
    required String kind,
    required String status,
    String? payloadJson,
    required int attempt,
    required int maxAttempts,
    required DateTime availableAt,
    String? leaseOwner,
    String? leaseToken,
    DateTime? leaseExpiresAt,
    String? checkpointJson,
    String? lastErrorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationJobImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationJob(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int?,
      requestId: jsonSerialization['requestId'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      attempt: jsonSerialization['attempt'] as int,
      maxAttempts: jsonSerialization['maxAttempts'] as int,
      availableAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['availableAt'],
      ),
      leaseOwner: jsonSerialization['leaseOwner'] as String?,
      leaseToken: jsonSerialization['leaseToken'] as String?,
      leaseExpiresAt: jsonSerialization['leaseExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['leaseExpiresAt'],
            ),
      checkpointJson: jsonSerialization['checkpointJson'] as String?,
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ConversationJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationJob copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    String? requestId,
    String? kind,
    String? status,
    String? payloadJson,
    int? attempt,
    int? maxAttempts,
    DateTime? availableAt,
    String? leaseOwner,
    String? leaseToken,
    DateTime? leaseExpiresAt,
    String? checkpointJson,
    String? lastErrorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationJob',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (turnId != null) 'turnId': turnId,
      'requestId': requestId,
      'kind': kind,
      'status': status,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'attempt': attempt,
      'maxAttempts': maxAttempts,
      'availableAt': availableAt.toJson(),
      if (leaseOwner != null) 'leaseOwner': leaseOwner,
      if (leaseToken != null) 'leaseToken': leaseToken,
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (checkpointJson != null) 'checkpointJson': checkpointJson,
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ConversationJobImpl({
  int? id,
  required int workspaceId,
  required int conversationId,
  int? turnId,
  required String requestId,
  required String kind,
  required String status,
  String? payloadJson,
  required int attempt,
  required int maxAttempts,
  required DateTime availableAt,
  String? leaseOwner,
  String? leaseToken,
  DateTime? leaseExpiresAt,
  String? checkpointJson,
  String? lastErrorCode,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ConversationJob {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        conversationId: conversationId,
        turnId: turnId,
        requestId: requestId,
        kind: kind,
        status: status,
        payloadJson: payloadJson,
        attempt: attempt,
        maxAttempts: maxAttempts,
        availableAt: availableAt,
        leaseOwner: leaseOwner,
        leaseToken: leaseToken,
        leaseExpiresAt: leaseExpiresAt,
        checkpointJson: checkpointJson,
        lastErrorCode: lastErrorCode,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ConversationJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationJob copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    Object? turnId = _Undefined,
    String? requestId,
    String? kind,
    String? status,
    Object? payloadJson = _Undefined,
    int? attempt,
    int? maxAttempts,
    DateTime? availableAt,
    Object? leaseOwner = _Undefined,
    Object? leaseToken = _Undefined,
    Object? leaseExpiresAt = _Undefined,
    Object? checkpointJson = _Undefined,
    Object? lastErrorCode = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationJob(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId is int? ? turnId : this.turnId,
      requestId: requestId ?? this.requestId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      attempt: attempt ?? this.attempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      availableAt: availableAt ?? this.availableAt,
      leaseOwner: leaseOwner is String? ? leaseOwner : this.leaseOwner,
      leaseToken: leaseToken is String? ? leaseToken : this.leaseToken,
      leaseExpiresAt: leaseExpiresAt is DateTime?
          ? leaseExpiresAt
          : this.leaseExpiresAt,
      checkpointJson: checkpointJson is String?
          ? checkpointJson
          : this.checkpointJson,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
