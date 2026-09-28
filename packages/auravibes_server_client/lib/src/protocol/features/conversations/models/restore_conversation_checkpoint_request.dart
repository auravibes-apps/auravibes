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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class RestoreConversationCheckpointRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RestoreConversationCheckpointRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.checkpointMessageId,
    required this.expectedConversationRevision,
  });

  factory RestoreConversationCheckpointRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String checkpointMessageId,
    required int expectedConversationRevision,
  }) = _RestoreConversationCheckpointRequestImpl;

  factory RestoreConversationCheckpointRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RestoreConversationCheckpointRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      checkpointMessageId: jsonSerialization['checkpointMessageId'] as String,
      expectedConversationRevision:
          jsonSerialization['expectedConversationRevision'] as int,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  String checkpointMessageId;

  int expectedConversationRevision;

  /// Returns a shallow copy of this [RestoreConversationCheckpointRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RestoreConversationCheckpointRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? checkpointMessageId,
    int? expectedConversationRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RestoreConversationCheckpointRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'checkpointMessageId': checkpointMessageId,
      'expectedConversationRevision': expectedConversationRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RestoreConversationCheckpointRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'checkpointMessageId': checkpointMessageId,
      'expectedConversationRevision': expectedConversationRevision,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RestoreConversationCheckpointRequestImpl
    extends RestoreConversationCheckpointRequest {
  _RestoreConversationCheckpointRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String checkpointMessageId,
    required int expectedConversationRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         checkpointMessageId: checkpointMessageId,
         expectedConversationRevision: expectedConversationRevision,
       );

  /// Returns a shallow copy of this [RestoreConversationCheckpointRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RestoreConversationCheckpointRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? checkpointMessageId,
    int? expectedConversationRevision,
  }) {
    return RestoreConversationCheckpointRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      checkpointMessageId: checkpointMessageId ?? this.checkpointMessageId,
      expectedConversationRevision:
          expectedConversationRevision ?? this.expectedConversationRevision,
    );
  }
}
