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
import 'package:serverpod/serverpod.dart' as _is;

abstract class ConversationSummary
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ConversationSummary._({
    required this.id,
    required this.title,
    required this.isPinned,
    this.modelId,
    this.agentId,
    this.reasoningConfigJson,
    this.parentConversationId,
    this.forkSourceConversationId,
    this.forkSourceTitle,
    this.forkThroughMessageId,
    this.forkMaterializedAt,
    required this.revision,
    this.activeCompactionCheckpointId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationSummary({
    required String id,
    required String title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? parentConversationId,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    required int revision,
    String? activeCompactionCheckpointId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationSummaryImpl;

  factory ConversationSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationSummary(
      id: jsonSerialization['id'] as String,
      title: jsonSerialization['title'] as String,
      isPinned: _is.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      reasoningConfigJson: jsonSerialization['reasoningConfigJson'] as String?,
      parentConversationId:
          jsonSerialization['parentConversationId'] as String?,
      forkSourceConversationId:
          jsonSerialization['forkSourceConversationId'] as String?,
      forkSourceTitle: jsonSerialization['forkSourceTitle'] as String?,
      forkThroughMessageId:
          jsonSerialization['forkThroughMessageId'] as String?,
      forkMaterializedAt: jsonSerialization['forkMaterializedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['forkMaterializedAt'],
            ),
      revision: jsonSerialization['revision'] as int,
      activeCompactionCheckpointId:
          jsonSerialization['activeCompactionCheckpointId'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  String title;

  bool isPinned;

  String? modelId;

  String? agentId;

  String? reasoningConfigJson;

  String? parentConversationId;

  String? forkSourceConversationId;

  String? forkSourceTitle;

  String? forkThroughMessageId;

  DateTime? forkMaterializedAt;

  int revision;

  String? activeCompactionCheckpointId;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationSummary copyWith({
    String? id,
    String? title,
    bool? isPinned,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? parentConversationId,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    int? revision,
    String? activeCompactionCheckpointId,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationSummary',
      'id': id,
      'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (reasoningConfigJson != null)
        'reasoningConfigJson': reasoningConfigJson,
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
      if (forkSourceConversationId != null)
        'forkSourceConversationId': forkSourceConversationId,
      if (forkSourceTitle != null) 'forkSourceTitle': forkSourceTitle,
      if (forkThroughMessageId != null)
        'forkThroughMessageId': forkThroughMessageId,
      if (forkMaterializedAt != null)
        'forkMaterializedAt': forkMaterializedAt?.toJson(),
      'revision': revision,
      if (activeCompactionCheckpointId != null)
        'activeCompactionCheckpointId': activeCompactionCheckpointId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationSummary',
      'id': id,
      'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (reasoningConfigJson != null)
        'reasoningConfigJson': reasoningConfigJson,
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
      if (forkSourceConversationId != null)
        'forkSourceConversationId': forkSourceConversationId,
      if (forkSourceTitle != null) 'forkSourceTitle': forkSourceTitle,
      if (forkThroughMessageId != null)
        'forkThroughMessageId': forkThroughMessageId,
      if (forkMaterializedAt != null)
        'forkMaterializedAt': forkMaterializedAt?.toJson(),
      'revision': revision,
      if (activeCompactionCheckpointId != null)
        'activeCompactionCheckpointId': activeCompactionCheckpointId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationSummaryImpl extends ConversationSummary {
  _ConversationSummaryImpl({
    required String id,
    required String title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? parentConversationId,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    required int revision,
    String? activeCompactionCheckpointId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         title: title,
         isPinned: isPinned,
         modelId: modelId,
         agentId: agentId,
         reasoningConfigJson: reasoningConfigJson,
         parentConversationId: parentConversationId,
         forkSourceConversationId: forkSourceConversationId,
         forkSourceTitle: forkSourceTitle,
         forkThroughMessageId: forkThroughMessageId,
         forkMaterializedAt: forkMaterializedAt,
         revision: revision,
         activeCompactionCheckpointId: activeCompactionCheckpointId,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationSummary copyWith({
    String? id,
    String? title,
    bool? isPinned,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? reasoningConfigJson = _Undefined,
    Object? parentConversationId = _Undefined,
    Object? forkSourceConversationId = _Undefined,
    Object? forkSourceTitle = _Undefined,
    Object? forkThroughMessageId = _Undefined,
    Object? forkMaterializedAt = _Undefined,
    int? revision,
    Object? activeCompactionCheckpointId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      reasoningConfigJson: reasoningConfigJson is String?
          ? reasoningConfigJson
          : this.reasoningConfigJson,
      parentConversationId: parentConversationId is String?
          ? parentConversationId
          : this.parentConversationId,
      forkSourceConversationId: forkSourceConversationId is String?
          ? forkSourceConversationId
          : this.forkSourceConversationId,
      forkSourceTitle: forkSourceTitle is String?
          ? forkSourceTitle
          : this.forkSourceTitle,
      forkThroughMessageId: forkThroughMessageId is String?
          ? forkThroughMessageId
          : this.forkThroughMessageId,
      forkMaterializedAt: forkMaterializedAt is DateTime?
          ? forkMaterializedAt
          : this.forkMaterializedAt,
      revision: revision ?? this.revision,
      activeCompactionCheckpointId: activeCompactionCheckpointId is String?
          ? activeCompactionCheckpointId
          : this.activeCompactionCheckpointId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
