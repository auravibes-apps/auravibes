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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ContinueTurnRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ContinueTurnRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.expectedConversationRevision,
  });

  factory ContinueTurnRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
  }) = _ContinueTurnRequestImpl;

  factory ContinueTurnRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContinueTurnRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedConversationRevision:
          jsonSerialization['expectedConversationRevision'] as int,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  int expectedConversationRevision;

  /// Returns a shallow copy of this [ContinueTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContinueTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedConversationRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContinueTurnRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedConversationRevision': expectedConversationRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ContinueTurnRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedConversationRevision': expectedConversationRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ContinueTurnRequestImpl extends ContinueTurnRequest {
  _ContinueTurnRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         expectedConversationRevision: expectedConversationRevision,
       );

  /// Returns a shallow copy of this [ContinueTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContinueTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedConversationRevision,
  }) {
    return ContinueTurnRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedConversationRevision:
          expectedConversationRevision ?? this.expectedConversationRevision,
    );
  }
}
