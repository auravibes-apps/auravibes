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
import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i2;

abstract class StartTurnRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String conversationId,
  required var int expectedConversationRevision,
  required var String clientMessageId,
  required var String content,
  required var List<String> attachmentIds,
  var String? modelSelectionId,
  var String? agentId,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? modelSelectionId,
    String? agentId,
  }) = _StartTurnRequestImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return StartTurnRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedConversationRevision:
          jsonSerialization['expectedConversationRevision'] as int,
      clientMessageId: jsonSerialization['clientMessageId'] as String,
      content: jsonSerialization['content'] as String,
      attachmentIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['attachmentIds'],
      ),
      modelSelectionId: jsonSerialization['modelSelectionId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
    );
  }

  /// Returns a shallow copy of this [StartTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StartTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedConversationRevision,
    String? clientMessageId,
    String? content,
    List<String>? attachmentIds,
    String? modelSelectionId,
    String? agentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StartTurnRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedConversationRevision': expectedConversationRevision,
      'clientMessageId': clientMessageId,
      'content': content,
      'attachmentIds': attachmentIds.toJson(),
      if (modelSelectionId != null) 'modelSelectionId': modelSelectionId,
      if (agentId != null) 'agentId': agentId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _StartTurnRequestImpl({
  required int workspaceId,
  required String requestId,
  required String conversationId,
  required int expectedConversationRevision,
  required String clientMessageId,
  required String content,
  required List<String> attachmentIds,
  String? modelSelectionId,
  String? agentId,
}) extends StartTurnRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
        modelSelectionId: modelSelectionId,
        agentId: agentId,
      );

  /// Returns a shallow copy of this [StartTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StartTurnRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedConversationRevision,
    String? clientMessageId,
    String? content,
    List<String>? attachmentIds,
    Object? modelSelectionId = _Undefined,
    Object? agentId = _Undefined,
  }) {
    return StartTurnRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedConversationRevision:
          expectedConversationRevision ?? this.expectedConversationRevision,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      content: content ?? this.content,
      attachmentIds:
          attachmentIds ?? this.attachmentIds.map((e0) => e0).toList(),
      modelSelectionId: modelSelectionId is String?
          ? modelSelectionId
          : this.modelSelectionId,
      agentId: agentId is String? ? agentId : this.agentId,
    );
  }
}
