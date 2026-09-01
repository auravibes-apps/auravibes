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

abstract class CancelTurnRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String turnId,
  required var int expectedTurnRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String turnId,
    required int expectedTurnRevision,
  }) = _CancelTurnRequestImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return CancelTurnRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      turnId: jsonSerialization['turnId'] as String,
      expectedTurnRevision: jsonSerialization['expectedTurnRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [CancelTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CancelTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? turnId,
    int? expectedTurnRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CancelTurnRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'turnId': turnId,
      'expectedTurnRevision': expectedTurnRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CancelTurnRequestImpl({
  required int workspaceId,
  required String requestId,
  required String turnId,
  required int expectedTurnRevision,
}) extends CancelTurnRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        turnId: turnId,
        expectedTurnRevision: expectedTurnRevision,
      );

  /// Returns a shallow copy of this [CancelTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CancelTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? turnId,
    int? expectedTurnRevision,
  }) {
    return CancelTurnRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      turnId: turnId ?? this.turnId,
      expectedTurnRevision: expectedTurnRevision ?? this.expectedTurnRevision,
    );
  }
}
