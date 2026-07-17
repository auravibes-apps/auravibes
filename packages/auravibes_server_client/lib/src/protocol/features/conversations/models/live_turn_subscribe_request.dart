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

abstract class LiveTurnSubscribeRequest implements _i1.SerializableModel {
  LiveTurnSubscribeRequest._({
    required this.workspaceId,
    required this.turnId,
  });

  factory LiveTurnSubscribeRequest({
    required int workspaceId,
    required String turnId,
  }) = _LiveTurnSubscribeRequestImpl;

  factory LiveTurnSubscribeRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LiveTurnSubscribeRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      turnId: jsonSerialization['turnId'] as String,
    );
  }

  int workspaceId;

  String turnId;

  /// Returns a shallow copy of this [LiveTurnSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LiveTurnSubscribeRequest copyWith({
    int? workspaceId,
    String? turnId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveTurnSubscribeRequest',
      'workspaceId': workspaceId,
      'turnId': turnId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _LiveTurnSubscribeRequestImpl extends LiveTurnSubscribeRequest {
  _LiveTurnSubscribeRequestImpl({
    required int workspaceId,
    required String turnId,
  }) : super._(
         workspaceId: workspaceId,
         turnId: turnId,
       );

  /// Returns a shallow copy of this [LiveTurnSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LiveTurnSubscribeRequest copyWith({
    int? workspaceId,
    String? turnId,
  }) {
    return LiveTurnSubscribeRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      turnId: turnId ?? this.turnId,
    );
  }
}
