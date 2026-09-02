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

abstract class ConversationSummary._({
  required var String id,
  required var String title,
  required var bool isPinned,
  var String? modelId,
  var String? agentId,
  var String? parentConversationId,
  required var int revision,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    required String id,
    required String title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationSummaryImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationSummary(
      id: jsonSerialization['id'] as String,
      title: jsonSerialization['title'] as String,
      isPinned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      parentConversationId:
          jsonSerialization['parentConversationId'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ConversationSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationSummary copyWith({
    String? id,
    String? title,
    bool? isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationId,
    int? revision,
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
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
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

class _Undefined;

class _ConversationSummaryImpl({
  required String id,
  required String title,
  required bool isPinned,
  String? modelId,
  String? agentId,
  String? parentConversationId,
  required int revision,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ConversationSummary {
  this
    : super._(
        id: id,
        title: title,
        isPinned: isPinned,
        modelId: modelId,
        agentId: agentId,
        parentConversationId: parentConversationId,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ConversationSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationSummary copyWith({
    String? id,
    String? title,
    bool? isPinned,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? parentConversationId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      parentConversationId: parentConversationId is String?
          ? parentConversationId
          : this.parentConversationId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
