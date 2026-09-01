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

abstract class ConversationTurn._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var int conversationId,
  required var String requestId,
  required var String requestHash,
  required var String initiatorUserId,
  var int? userMessageId,
  var int? assistantMessageId,
  required var String status,
  required var int revision,
  required var int acceptedSequence,
  var DateTime? cancellationRequestedAt,
  var DateTime? terminalAt,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String requestId,
    required String requestHash,
    required String initiatorUserId,
    int? userMessageId,
    int? assistantMessageId,
    required String status,
    required int revision,
    required int acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationTurnImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationTurn(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      initiatorUserId: jsonSerialization['initiatorUserId'] as String,
      userMessageId: jsonSerialization['userMessageId'] as int?,
      assistantMessageId: jsonSerialization['assistantMessageId'] as int?,
      status: jsonSerialization['status'] as String,
      revision: jsonSerialization['revision'] as int,
      acceptedSequence: jsonSerialization['acceptedSequence'] as int,
      cancellationRequestedAt:
          jsonSerialization['cancellationRequestedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['cancellationRequestedAt'],
            ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ConversationTurn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationTurn copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? requestId,
    String? requestHash,
    String? initiatorUserId,
    int? userMessageId,
    int? assistantMessageId,
    String? status,
    int? revision,
    int? acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationTurn',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'requestId': requestId,
      'requestHash': requestHash,
      'initiatorUserId': initiatorUserId,
      if (userMessageId != null) 'userMessageId': userMessageId,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'status': status,
      'revision': revision,
      'acceptedSequence': acceptedSequence,
      if (cancellationRequestedAt != null)
        'cancellationRequestedAt': cancellationRequestedAt?.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
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

class _ConversationTurnImpl({
  int? id,
  required int workspaceId,
  required int conversationId,
  required String requestId,
  required String requestHash,
  required String initiatorUserId,
  int? userMessageId,
  int? assistantMessageId,
  required String status,
  required int revision,
  required int acceptedSequence,
  DateTime? cancellationRequestedAt,
  DateTime? terminalAt,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ConversationTurn {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        conversationId: conversationId,
        requestId: requestId,
        requestHash: requestHash,
        initiatorUserId: initiatorUserId,
        userMessageId: userMessageId,
        assistantMessageId: assistantMessageId,
        status: status,
        revision: revision,
        acceptedSequence: acceptedSequence,
        cancellationRequestedAt: cancellationRequestedAt,
        terminalAt: terminalAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ConversationTurn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationTurn copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? requestId,
    String? requestHash,
    String? initiatorUserId,
    Object? userMessageId = _Undefined,
    Object? assistantMessageId = _Undefined,
    String? status,
    int? revision,
    int? acceptedSequence,
    Object? cancellationRequestedAt = _Undefined,
    Object? terminalAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationTurn(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      initiatorUserId: initiatorUserId ?? this.initiatorUserId,
      userMessageId: userMessageId is int? ? userMessageId : this.userMessageId,
      assistantMessageId: assistantMessageId is int?
          ? assistantMessageId
          : this.assistantMessageId,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      acceptedSequence: acceptedSequence ?? this.acceptedSequence,
      cancellationRequestedAt: cancellationRequestedAt is DateTime?
          ? cancellationRequestedAt
          : this.cancellationRequestedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
