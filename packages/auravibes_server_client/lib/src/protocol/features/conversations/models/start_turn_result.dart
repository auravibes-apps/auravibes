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

abstract class StartTurnResult implements _i1.SerializableModel {
  StartTurnResult._({
    required this.turnId,
    required this.userMessageId,
    required this.assistantMessageId,
    required this.acceptedSequence,
    required this.turnRevision,
    required this.status,
  });

  factory StartTurnResult({
    required String turnId,
    required String userMessageId,
    required String assistantMessageId,
    required int acceptedSequence,
    required int turnRevision,
    required String status,
  }) = _StartTurnResultImpl;

  factory StartTurnResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return StartTurnResult(
      turnId: jsonSerialization['turnId'] as String,
      userMessageId: jsonSerialization['userMessageId'] as String,
      assistantMessageId: jsonSerialization['assistantMessageId'] as String,
      acceptedSequence: jsonSerialization['acceptedSequence'] as int,
      turnRevision: jsonSerialization['turnRevision'] as int,
      status: jsonSerialization['status'] as String,
    );
  }

  String turnId;

  String userMessageId;

  String assistantMessageId;

  int acceptedSequence;

  int turnRevision;

  String status;

  /// Returns a shallow copy of this [StartTurnResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StartTurnResult copyWith({
    String? turnId,
    String? userMessageId,
    String? assistantMessageId,
    int? acceptedSequence,
    int? turnRevision,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StartTurnResult',
      'turnId': turnId,
      'userMessageId': userMessageId,
      'assistantMessageId': assistantMessageId,
      'acceptedSequence': acceptedSequence,
      'turnRevision': turnRevision,
      'status': status,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StartTurnResultImpl extends StartTurnResult {
  _StartTurnResultImpl({
    required String turnId,
    required String userMessageId,
    required String assistantMessageId,
    required int acceptedSequence,
    required int turnRevision,
    required String status,
  }) : super._(
         turnId: turnId,
         userMessageId: userMessageId,
         assistantMessageId: assistantMessageId,
         acceptedSequence: acceptedSequence,
         turnRevision: turnRevision,
         status: status,
       );

  /// Returns a shallow copy of this [StartTurnResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StartTurnResult copyWith({
    String? turnId,
    String? userMessageId,
    String? assistantMessageId,
    int? acceptedSequence,
    int? turnRevision,
    String? status,
  }) {
    return StartTurnResult(
      turnId: turnId ?? this.turnId,
      userMessageId: userMessageId ?? this.userMessageId,
      assistantMessageId: assistantMessageId ?? this.assistantMessageId,
      acceptedSequence: acceptedSequence ?? this.acceptedSequence,
      turnRevision: turnRevision ?? this.turnRevision,
      status: status ?? this.status,
    );
  }
}
