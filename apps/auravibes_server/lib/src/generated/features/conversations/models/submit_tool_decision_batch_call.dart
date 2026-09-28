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

abstract class SubmitToolDecisionBatchCall
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmitToolDecisionBatchCall._({
    required this.conversationId,
    required this.turnId,
    required this.toolCallId,
    required this.argumentsDigest,
    required this.expectedTurnRevision,
    this.editedArgumentsJson,
  });

  factory SubmitToolDecisionBatchCall({
    required String conversationId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    String? editedArgumentsJson,
  }) = _SubmitToolDecisionBatchCallImpl;

  factory SubmitToolDecisionBatchCall.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SubmitToolDecisionBatchCall(
      conversationId: jsonSerialization['conversationId'] as String,
      turnId: jsonSerialization['turnId'] as String,
      toolCallId: jsonSerialization['toolCallId'] as String,
      argumentsDigest: jsonSerialization['argumentsDigest'] as String,
      expectedTurnRevision: jsonSerialization['expectedTurnRevision'] as int,
      editedArgumentsJson: jsonSerialization['editedArgumentsJson'] as String?,
    );
  }

  String conversationId;

  String turnId;

  String toolCallId;

  String argumentsDigest;

  int expectedTurnRevision;

  String? editedArgumentsJson;

  /// Returns a shallow copy of this [SubmitToolDecisionBatchCall]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmitToolDecisionBatchCall copyWith({
    String? conversationId,
    String? turnId,
    String? toolCallId,
    String? argumentsDigest,
    int? expectedTurnRevision,
    String? editedArgumentsJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmitToolDecisionBatchCall',
      'conversationId': conversationId,
      'turnId': turnId,
      'toolCallId': toolCallId,
      'argumentsDigest': argumentsDigest,
      'expectedTurnRevision': expectedTurnRevision,
      if (editedArgumentsJson != null)
        'editedArgumentsJson': editedArgumentsJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmitToolDecisionBatchCall',
      'conversationId': conversationId,
      'turnId': turnId,
      'toolCallId': toolCallId,
      'argumentsDigest': argumentsDigest,
      'expectedTurnRevision': expectedTurnRevision,
      if (editedArgumentsJson != null)
        'editedArgumentsJson': editedArgumentsJson,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmitToolDecisionBatchCallImpl extends SubmitToolDecisionBatchCall {
  _SubmitToolDecisionBatchCallImpl({
    required String conversationId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    String? editedArgumentsJson,
  }) : super._(
         conversationId: conversationId,
         turnId: turnId,
         toolCallId: toolCallId,
         argumentsDigest: argumentsDigest,
         expectedTurnRevision: expectedTurnRevision,
         editedArgumentsJson: editedArgumentsJson,
       );

  /// Returns a shallow copy of this [SubmitToolDecisionBatchCall]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmitToolDecisionBatchCall copyWith({
    String? conversationId,
    String? turnId,
    String? toolCallId,
    String? argumentsDigest,
    int? expectedTurnRevision,
    Object? editedArgumentsJson = _Undefined,
  }) {
    return SubmitToolDecisionBatchCall(
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId ?? this.turnId,
      toolCallId: toolCallId ?? this.toolCallId,
      argumentsDigest: argumentsDigest ?? this.argumentsDigest,
      expectedTurnRevision: expectedTurnRevision ?? this.expectedTurnRevision,
      editedArgumentsJson: editedArgumentsJson is String?
          ? editedArgumentsJson
          : this.editedArgumentsJson,
    );
  }
}
