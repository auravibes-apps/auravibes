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

abstract class DetachToolCallRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DetachToolCallRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.toolCallId,
  });

  factory DetachToolCallRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String toolCallId,
  }) = _DetachToolCallRequestImpl;

  factory DetachToolCallRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DetachToolCallRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      toolCallId: jsonSerialization['toolCallId'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  String toolCallId;

  /// Returns a shallow copy of this [DetachToolCallRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DetachToolCallRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? toolCallId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DetachToolCallRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'toolCallId': toolCallId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DetachToolCallRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'toolCallId': toolCallId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DetachToolCallRequestImpl extends DetachToolCallRequest {
  _DetachToolCallRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String toolCallId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         toolCallId: toolCallId,
       );

  /// Returns a shallow copy of this [DetachToolCallRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DetachToolCallRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? toolCallId,
  }) {
    return DetachToolCallRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      toolCallId: toolCallId ?? this.toolCallId,
    );
  }
}
