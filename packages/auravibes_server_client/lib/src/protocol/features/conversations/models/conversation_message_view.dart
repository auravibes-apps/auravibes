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

import '../../../features/conversations/models/conversation_tool_call_view.dart'
    as _i2;

import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i3;

abstract class ConversationMessageView implements _i1.SerializableModel {
  ConversationMessageView._({
    required this.id,
    required this.conversationId,
    this.turnId,
    this.turnRevision,
    required this.role,
    required this.kind,
    required this.status,
    required this.content,
    this.metadataJson,
    required this.toolCalls,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationMessageView({
    required String id,
    required String conversationId,
    String? turnId,
    int? turnRevision,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    required List<_i2.ConversationToolCallView> toolCalls,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationMessageViewImpl;

  factory ConversationMessageView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationMessageView(
      id: jsonSerialization['id'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      turnId: jsonSerialization['turnId'] as String?,
      turnRevision: jsonSerialization['turnRevision'] as int?,
      role: jsonSerialization['role'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      content: jsonSerialization['content'] as String,
      metadataJson: jsonSerialization['metadataJson'] as String?,
      toolCalls: _i3.Protocol().deserialize<List<_i2.ConversationToolCallView>>(
        jsonSerialization['toolCalls'],
      ),
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  String conversationId;

  String? turnId;

  int? turnRevision;

  String role;

  String kind;

  String status;

  String content;

  String? metadataJson;

  List<_i2.ConversationToolCallView> toolCalls;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationMessageView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationMessageView copyWith({
    String? id,
    String? conversationId,
    String? turnId,
    int? turnRevision,
    String? role,
    String? kind,
    String? status,
    String? content,
    String? metadataJson,
    List<_i2.ConversationToolCallView>? toolCalls,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationMessageView',
      'id': id,
      'conversationId': conversationId,
      if (turnId != null) 'turnId': turnId,
      if (turnRevision != null) 'turnRevision': turnRevision,
      'role': role,
      'kind': kind,
      'status': status,
      'content': content,
      if (metadataJson != null) 'metadataJson': metadataJson,
      'toolCalls': toolCalls.toJson(valueToJson: (v) => v.toJson()),
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

class _ConversationMessageViewImpl extends ConversationMessageView {
  _ConversationMessageViewImpl({
    required String id,
    required String conversationId,
    String? turnId,
    int? turnRevision,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    required List<_i2.ConversationToolCallView> toolCalls,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         conversationId: conversationId,
         turnId: turnId,
         turnRevision: turnRevision,
         role: role,
         kind: kind,
         status: status,
         content: content,
         metadataJson: metadataJson,
         toolCalls: toolCalls,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationMessageView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationMessageView copyWith({
    String? id,
    String? conversationId,
    Object? turnId = _Undefined,
    Object? turnRevision = _Undefined,
    String? role,
    String? kind,
    String? status,
    String? content,
    Object? metadataJson = _Undefined,
    List<_i2.ConversationToolCallView>? toolCalls,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationMessageView(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId is String? ? turnId : this.turnId,
      turnRevision: turnRevision is int? ? turnRevision : this.turnRevision,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      content: content ?? this.content,
      metadataJson: metadataJson is String? ? metadataJson : this.metadataJson,
      toolCalls:
          toolCalls ?? this.toolCalls.map((e0) => e0.copyWith()).toList(),
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
