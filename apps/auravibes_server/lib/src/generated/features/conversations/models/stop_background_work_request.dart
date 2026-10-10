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

abstract class StopBackgroundWorkRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  StopBackgroundWorkRequest._({
    required this.requestId,
    required this.workspaceId,
    required this.conversationId,
    required this.workId,
  });

  factory StopBackgroundWorkRequest({
    required String requestId,
    required int workspaceId,
    required String conversationId,
    required String workId,
  }) = _StopBackgroundWorkRequestImpl;

  factory StopBackgroundWorkRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StopBackgroundWorkRequest(
      requestId: jsonSerialization['requestId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      workId: jsonSerialization['workId'] as String,
    );
  }

  String requestId;

  int workspaceId;

  String conversationId;

  String workId;

  /// Returns a shallow copy of this [StopBackgroundWorkRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StopBackgroundWorkRequest copyWith({
    String? requestId,
    int? workspaceId,
    String? conversationId,
    String? workId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StopBackgroundWorkRequest',
      'requestId': requestId,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'workId': workId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StopBackgroundWorkRequest',
      'requestId': requestId,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'workId': workId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _StopBackgroundWorkRequestImpl extends StopBackgroundWorkRequest {
  _StopBackgroundWorkRequestImpl({
    required String requestId,
    required int workspaceId,
    required String conversationId,
    required String workId,
  }) : super._(
         requestId: requestId,
         workspaceId: workspaceId,
         conversationId: conversationId,
         workId: workId,
       );

  /// Returns a shallow copy of this [StopBackgroundWorkRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StopBackgroundWorkRequest copyWith({
    String? requestId,
    int? workspaceId,
    String? conversationId,
    String? workId,
  }) {
    return StopBackgroundWorkRequest(
      requestId: requestId ?? this.requestId,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      workId: workId ?? this.workId,
    );
  }
}
