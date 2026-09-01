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

abstract class GetTurnRequest._({
  required var int workspaceId,
  required var String turnId,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String turnId,
  }) = _GetTurnRequestImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return GetTurnRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      turnId: jsonSerialization['turnId'] as String,
    );
  }

  /// Returns a shallow copy of this [GetTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GetTurnRequest copyWith({
    int? workspaceId,
    String? turnId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetTurnRequest',
      'workspaceId': workspaceId,
      'turnId': turnId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GetTurnRequestImpl({
  required int workspaceId,
  required String turnId,
}) extends GetTurnRequest {
  this
    : super._(
        workspaceId: workspaceId,
        turnId: turnId,
      );

  /// Returns a shallow copy of this [GetTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GetTurnRequest copyWith({
    int? workspaceId,
    String? turnId,
  }) {
    return GetTurnRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      turnId: turnId ?? this.turnId,
    );
  }
}
