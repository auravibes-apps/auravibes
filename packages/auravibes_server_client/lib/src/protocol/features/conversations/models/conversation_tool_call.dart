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

abstract class ConversationToolCall implements _i1.SerializableModel {
  ConversationToolCall._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.turnId,
    required this.messageId,
    required this.stableId,
    required this.name,
    required this.argumentsJson,
    required this.argumentsDigest,
    required this.status,
    this.decision,
    this.decisionByUserId,
    this.decisionAt,
    this.resultJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationToolCall({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int messageId,
    required String stableId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    required String status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationToolCallImpl;

  factory ConversationToolCall.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationToolCall(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int,
      messageId: jsonSerialization['messageId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      name: jsonSerialization['name'] as String,
      argumentsJson: jsonSerialization['argumentsJson'] as String,
      argumentsDigest: jsonSerialization['argumentsDigest'] as String,
      status: jsonSerialization['status'] as String,
      decision: jsonSerialization['decision'] as String?,
      decisionByUserId: jsonSerialization['decisionByUserId'] as String?,
      decisionAt: jsonSerialization['decisionAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['decisionAt']),
      resultJson: jsonSerialization['resultJson'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  int conversationId;

  int turnId;

  int messageId;

  String stableId;

  String name;

  String argumentsJson;

  String argumentsDigest;

  String status;

  String? decision;

  String? decisionByUserId;

  DateTime? decisionAt;

  String? resultJson;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationToolCall]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationToolCall copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? messageId,
    String? stableId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationToolCall',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'messageId': messageId,
      'stableId': stableId,
      'name': name,
      'argumentsJson': argumentsJson,
      'argumentsDigest': argumentsDigest,
      'status': status,
      if (decision != null) 'decision': decision,
      if (decisionByUserId != null) 'decisionByUserId': decisionByUserId,
      if (decisionAt != null) 'decisionAt': decisionAt?.toJson(),
      if (resultJson != null) 'resultJson': resultJson,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationToolCallImpl extends ConversationToolCall {
  _ConversationToolCallImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int messageId,
    required String stableId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    required String status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         turnId: turnId,
         messageId: messageId,
         stableId: stableId,
         name: name,
         argumentsJson: argumentsJson,
         argumentsDigest: argumentsDigest,
         status: status,
         decision: decision,
         decisionByUserId: decisionByUserId,
         decisionAt: decisionAt,
         resultJson: resultJson,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationToolCall]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationToolCall copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? messageId,
    String? stableId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    Object? decision = _Undefined,
    Object? decisionByUserId = _Undefined,
    Object? decisionAt = _Undefined,
    Object? resultJson = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationToolCall(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId ?? this.turnId,
      messageId: messageId ?? this.messageId,
      stableId: stableId ?? this.stableId,
      name: name ?? this.name,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      argumentsDigest: argumentsDigest ?? this.argumentsDigest,
      status: status ?? this.status,
      decision: decision is String? ? decision : this.decision,
      decisionByUserId: decisionByUserId is String?
          ? decisionByUserId
          : this.decisionByUserId,
      decisionAt: decisionAt is DateTime? ? decisionAt : this.decisionAt,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
