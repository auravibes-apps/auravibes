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

abstract class ConversationUsage implements _i1.SerializableModel {
  ConversationUsage._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.turnId,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.createdAt,
  });

  factory ConversationUsage({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
    required DateTime createdAt,
  }) = _ConversationUsageImpl;

  factory ConversationUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationUsage(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int,
      inputTokens: jsonSerialization['inputTokens'] as int,
      outputTokens: jsonSerialization['outputTokens'] as int,
      totalTokens: jsonSerialization['totalTokens'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
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

  int inputTokens;

  int outputTokens;

  int totalTokens;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConversationUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationUsage copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationUsage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationUsageImpl extends ConversationUsage {
  _ConversationUsageImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         turnId: turnId,
         inputTokens: inputTokens,
         outputTokens: outputTokens,
         totalTokens: totalTokens,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationUsage copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    DateTime? createdAt,
  }) {
    return ConversationUsage(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId ?? this.turnId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
