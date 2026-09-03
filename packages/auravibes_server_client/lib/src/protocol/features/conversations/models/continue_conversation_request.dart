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

abstract class ContinueConversationRequest implements _i1.SerializableModel {
  ContinueConversationRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.expectedProjectionRevision,
  });

  factory ContinueConversationRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) = _ContinueConversationRequestImpl;

  factory ContinueConversationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ContinueConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedProjectionRevision:
          jsonSerialization['expectedProjectionRevision'] as int,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  int expectedProjectionRevision;

  /// Returns a shallow copy of this [ContinueConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContinueConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContinueConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ContinueConversationRequestImpl extends ContinueConversationRequest {
  _ContinueConversationRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         expectedProjectionRevision: expectedProjectionRevision,
       );

  /// Returns a shallow copy of this [ContinueConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContinueConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
  }) {
    return ContinueConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedProjectionRevision:
          expectedProjectionRevision ?? this.expectedProjectionRevision,
    );
  }
}
