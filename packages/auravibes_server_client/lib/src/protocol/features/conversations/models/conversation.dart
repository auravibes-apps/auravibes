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

abstract class Conversation implements _i1.SerializableModel {
  Conversation._({
    this.id,
    required this.workspaceId,
    required this.stableId,
    this.title,
    required this.isPinned,
    this.modelId,
    this.agentId,
    this.parentConversationStableId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Conversation({
    int? id,
    required int workspaceId,
    required String stableId,
    String? title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ConversationImpl;

  factory Conversation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Conversation(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      title: jsonSerialization['title'] as String?,
      isPinned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      parentConversationStableId:
          jsonSerialization['parentConversationStableId'] as String?,
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String stableId;

  String? title;

  bool isPinned;

  String? modelId;

  String? agentId;

  String? parentConversationStableId;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Conversation copyWith({
    int? id,
    int? workspaceId,
    String? stableId,
    String? title,
    bool? isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Conversation',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      if (title != null) 'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (parentConversationStableId != null)
        'parentConversationStableId': parentConversationStableId,
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

class _Undefined {}

class _ConversationImpl extends Conversation {
  _ConversationImpl({
    int? id,
    required int workspaceId,
    required String stableId,
    String? title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         stableId: stableId,
         title: title,
         isPinned: isPinned,
         modelId: modelId,
         agentId: agentId,
         parentConversationStableId: parentConversationStableId,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Conversation copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? stableId,
    Object? title = _Undefined,
    bool? isPinned,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? parentConversationStableId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return Conversation(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      stableId: stableId ?? this.stableId,
      title: title is String? ? title : this.title,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      parentConversationStableId: parentConversationStableId is String?
          ? parentConversationStableId
          : this.parentConversationStableId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
