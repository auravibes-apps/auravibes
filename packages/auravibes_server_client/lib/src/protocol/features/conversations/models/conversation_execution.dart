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

abstract class ConversationExecution._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var int conversationId,
  required var String stableId,
  required var String status,
  required var String settingsJson,
  required var String claimedMessageIdsJson,
  var int? assistantMessageId,
  required var int attempt,
  required var String createdByUserId,
  required var DateTime createdAt,
  required var DateTime updatedAt,
  var DateTime? terminalAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String status,
    required String settingsJson,
    required String claimedMessageIdsJson,
    int? assistantMessageId,
    required int attempt,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? terminalAt,
  }) = _ConversationExecutionImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationExecution(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      status: jsonSerialization['status'] as String,
      settingsJson: jsonSerialization['settingsJson'] as String,
      claimedMessageIdsJson:
          jsonSerialization['claimedMessageIdsJson'] as String,
      assistantMessageId: jsonSerialization['assistantMessageId'] as int?,
      attempt: jsonSerialization['attempt'] as int,
      createdByUserId: jsonSerialization['createdByUserId'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
    );
  }

  /// Returns a shallow copy of this [ConversationExecution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationExecution copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? status,
    String? settingsJson,
    String? claimedMessageIdsJson,
    int? assistantMessageId,
    int? attempt,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? terminalAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationExecution',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'status': status,
      'settingsJson': settingsJson,
      'claimedMessageIdsJson': claimedMessageIdsJson,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'attempt': attempt,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ConversationExecutionImpl({
  int? id,
  required int workspaceId,
  required int conversationId,
  required String stableId,
  required String status,
  required String settingsJson,
  required String claimedMessageIdsJson,
  int? assistantMessageId,
  required int attempt,
  required String createdByUserId,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? terminalAt,
}) extends ConversationExecution {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        conversationId: conversationId,
        stableId: stableId,
        status: status,
        settingsJson: settingsJson,
        claimedMessageIdsJson: claimedMessageIdsJson,
        assistantMessageId: assistantMessageId,
        attempt: attempt,
        createdByUserId: createdByUserId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        terminalAt: terminalAt,
      );

  /// Returns a shallow copy of this [ConversationExecution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationExecution copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? status,
    String? settingsJson,
    String? claimedMessageIdsJson,
    Object? assistantMessageId = _Undefined,
    int? attempt,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? terminalAt = _Undefined,
  }) {
    return ConversationExecution(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      status: status ?? this.status,
      settingsJson: settingsJson ?? this.settingsJson,
      claimedMessageIdsJson:
          claimedMessageIdsJson ?? this.claimedMessageIdsJson,
      assistantMessageId: assistantMessageId is int?
          ? assistantMessageId
          : this.assistantMessageId,
      attempt: attempt ?? this.attempt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
    );
  }
}
