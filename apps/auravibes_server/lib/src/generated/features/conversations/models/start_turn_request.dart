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
import 'package:auravibes_server/src/generated/protocol.dart' as _i2;

abstract class StartTurnRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StartTurnRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.expectedConversationRevision,
    required this.clientMessageId,
    required this.content,
    required this.attachmentIds,
    this.modelSelectionId,
    this.agentId,
    this.a2uiSupportedComponents,
  });

  factory StartTurnRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? modelSelectionId,
    String? agentId,
    List<String>? a2uiSupportedComponents,
  }) = _StartTurnRequestImpl;

  factory StartTurnRequest.fromJson(Map<String, dynamic> jsonSerialization) {
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
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  int expectedConversationRevision;

  String clientMessageId;

  String content;

  List<String> attachmentIds;

  String? modelSelectionId;

  String? agentId;

  List<String>? a2uiSupportedComponents;

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
    List<String>? a2uiSupportedComponents,
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
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
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
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StartTurnRequestImpl extends StartTurnRequest {
  _StartTurnRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? modelSelectionId,
    String? agentId,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         expectedConversationRevision: expectedConversationRevision,
         clientMessageId: clientMessageId,
         content: content,
         attachmentIds: attachmentIds,
         modelSelectionId: modelSelectionId,
         agentId: agentId,
         a2uiSupportedComponents: a2uiSupportedComponents,
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
    Object? a2uiSupportedComponents = _Undefined,
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
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
