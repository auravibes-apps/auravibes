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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ConversationMutationResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationMutationResult._({
    this.turnId,
    required this.conversationId,
    required this.revision,
    required this.status,
  });

  factory ConversationMutationResult({
    String? turnId,
    required String conversationId,
    required int revision,
    required String status,
  }) = _ConversationMutationResultImpl;

  factory ConversationMutationResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationMutationResult(
      turnId: jsonSerialization['turnId'] as String?,
      conversationId: jsonSerialization['conversationId'] as String,
      revision: jsonSerialization['revision'] as int,
      status: jsonSerialization['status'] as String,
    );
  }

  String? turnId;

  String conversationId;

  int revision;

  String status;

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
  Map<String, dynamic> toJsonForProtocol() {
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

class _Undefined {}

class _ConversationMutationResultImpl extends ConversationMutationResult {
  _ConversationMutationResultImpl({
    String? turnId,
    required String conversationId,
    required int revision,
    required String status,
  }) : super._(
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
