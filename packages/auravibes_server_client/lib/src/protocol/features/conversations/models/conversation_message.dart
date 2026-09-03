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

abstract class ConversationMessage implements _i1.SerializableModel {
  ConversationMessage._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.stableId,
    this.turnId,
    required this.role,
    required this.kind,
    required this.status,
    required this.content,
    this.metadataJson,
    this.pendingOrder,
    this.pendingAt,
    this.compactedThroughMessageId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationMessage({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    int? turnId,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    int? pendingOrder,
    DateTime? pendingAt,
    int? compactedThroughMessageId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationMessageImpl;

  factory ConversationMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationMessage(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      turnId: jsonSerialization['turnId'] as int?,
      role: jsonSerialization['role'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      content: jsonSerialization['content'] as String,
      metadataJson: jsonSerialization['metadataJson'] as String?,
      pendingOrder: jsonSerialization['pendingOrder'] as int?,
      pendingAt: jsonSerialization['pendingAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['pendingAt']),
      compactedThroughMessageId:
          jsonSerialization['compactedThroughMessageId'] as int?,
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

  String stableId;

  int? turnId;

  String role;

  String kind;

  String status;

  String content;

  String? metadataJson;

  int? pendingOrder;

  DateTime? pendingAt;

  int? compactedThroughMessageId;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationMessage copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    int? turnId,
    String? role,
    String? kind,
    String? status,
    String? content,
    String? metadataJson,
    int? pendingOrder,
    DateTime? pendingAt,
    int? compactedThroughMessageId,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationMessage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      if (turnId != null) 'turnId': turnId,
      'role': role,
      'kind': kind,
      'status': status,
      'content': content,
      if (metadataJson != null) 'metadataJson': metadataJson,
      if (pendingOrder != null) 'pendingOrder': pendingOrder,
      if (pendingAt != null) 'pendingAt': pendingAt?.toJson(),
      if (compactedThroughMessageId != null)
        'compactedThroughMessageId': compactedThroughMessageId,
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

class _ConversationMessageImpl extends ConversationMessage {
  _ConversationMessageImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    int? turnId,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    int? pendingOrder,
    DateTime? pendingAt,
    int? compactedThroughMessageId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         stableId: stableId,
         turnId: turnId,
         role: role,
         kind: kind,
         status: status,
         content: content,
         metadataJson: metadataJson,
         pendingOrder: pendingOrder,
         pendingAt: pendingAt,
         compactedThroughMessageId: compactedThroughMessageId,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationMessage copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    Object? turnId = _Undefined,
    String? role,
    String? kind,
    String? status,
    String? content,
    Object? metadataJson = _Undefined,
    Object? pendingOrder = _Undefined,
    Object? pendingAt = _Undefined,
    Object? compactedThroughMessageId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationMessage(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      turnId: turnId is int? ? turnId : this.turnId,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      content: content ?? this.content,
      metadataJson: metadataJson is String? ? metadataJson : this.metadataJson,
      pendingOrder: pendingOrder is int? ? pendingOrder : this.pendingOrder,
      pendingAt: pendingAt is DateTime? ? pendingAt : this.pendingAt,
      compactedThroughMessageId: compactedThroughMessageId is int?
          ? compactedThroughMessageId
          : this.compactedThroughMessageId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
