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

abstract class UpdateConversationSettingsRequest
    implements _i1.SerializableModel {
  UpdateConversationSettingsRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.expectedProjectionRevision,
    this.modelId,
    this.agentId,
  });

  factory UpdateConversationSettingsRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    String? modelId,
    String? agentId,
  }) = _UpdateConversationSettingsRequestImpl;

  factory UpdateConversationSettingsRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return UpdateConversationSettingsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedProjectionRevision:
          jsonSerialization['expectedProjectionRevision'] as int,
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  int expectedProjectionRevision;

  String? modelId;

  String? agentId;

  /// Returns a shallow copy of this [UpdateConversationSettingsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UpdateConversationSettingsRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? modelId,
    String? agentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UpdateConversationSettingsRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UpdateConversationSettingsRequestImpl
    extends UpdateConversationSettingsRequest {
  _UpdateConversationSettingsRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    String? modelId,
    String? agentId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         expectedProjectionRevision: expectedProjectionRevision,
         modelId: modelId,
         agentId: agentId,
       );

  /// Returns a shallow copy of this [UpdateConversationSettingsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UpdateConversationSettingsRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
  }) {
    return UpdateConversationSettingsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedProjectionRevision:
          expectedProjectionRevision ?? this.expectedProjectionRevision,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
    );
  }
}
