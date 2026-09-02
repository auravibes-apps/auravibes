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

abstract class ConversationMutationResult._({
  var String? turnId,
  required var String conversationId,
  required var int revision,
  required var String status,
}) implements _i1.SerializableModel {
  factory({
    String? turnId,
    required String conversationId,
    required int revision,
    required String status,
  }) = _ConversationMutationResultImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationMutationResult(
      turnId: jsonSerialization['turnId'] as String?,
      conversationId: jsonSerialization['conversationId'] as String,
      revision: jsonSerialization['revision'] as int,
      status: jsonSerialization['status'] as String,
    );
  }

  /// Returns a shallow copy of this [ConversationMutationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationMutationResult copyWith({
    String? turnId,
    String? conversationId,
    int? revision,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationMutationResult',
      if (turnId != null) 'turnId': turnId,
      'conversationId': conversationId,
      'revision': revision,
      'status': status,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ConversationMutationResultImpl({
  String? turnId,
  required String conversationId,
  required int revision,
  required String status,
}) extends ConversationMutationResult {
  this
    : super._(
        turnId: turnId,
        conversationId: conversationId,
        revision: revision,
        status: status,
      );

  /// Returns a shallow copy of this [ConversationMutationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationMutationResult copyWith({
    Object? turnId = _Undefined,
    String? conversationId,
    int? revision,
    String? status,
  }) {
    return ConversationMutationResult(
      turnId: turnId is String? ? turnId : this.turnId,
      conversationId: conversationId ?? this.conversationId,
      revision: revision ?? this.revision,
      status: status ?? this.status,
    );
  }
}
