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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

abstract class SubmitToolDecisionRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmitToolDecisionRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.turnId,
    required this.toolCallId,
    required this.argumentsDigest,
    required this.expectedTurnRevision,
    required this.decision,
    bool? stopAll,
    this.editedArgumentsJson,
    this.a2uiSupportedComponents,
  }) : stopAll = stopAll ?? false;

  factory SubmitToolDecisionRequest({
    required int workspaceId,
    required String requestId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    required String decision,
    bool? stopAll,
    String? editedArgumentsJson,
    List<String>? a2uiSupportedComponents,
  }) = _SubmitToolDecisionRequestImpl;

  factory SubmitToolDecisionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SubmitToolDecisionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      turnId: jsonSerialization['turnId'] as String,
      toolCallId: jsonSerialization['toolCallId'] as String,
      argumentsDigest: jsonSerialization['argumentsDigest'] as String,
      expectedTurnRevision: jsonSerialization['expectedTurnRevision'] as int,
      decision: jsonSerialization['decision'] as String,
      stopAll: jsonSerialization['stopAll'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['stopAll']),
      editedArgumentsJson: jsonSerialization['editedArgumentsJson'] as String?,
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _if5qez1k.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String requestId;

  String turnId;

  String toolCallId;

  String argumentsDigest;

  int expectedTurnRevision;

  String decision;

  bool stopAll;

  String? editedArgumentsJson;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [SubmitToolDecisionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmitToolDecisionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? turnId,
    String? toolCallId,
    String? argumentsDigest,
    int? expectedTurnRevision,
    String? decision,
    bool? stopAll,
    String? editedArgumentsJson,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmitToolDecisionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'turnId': turnId,
      'toolCallId': toolCallId,
      'argumentsDigest': argumentsDigest,
      'expectedTurnRevision': expectedTurnRevision,
      'decision': decision,
      'stopAll': stopAll,
      if (editedArgumentsJson != null)
        'editedArgumentsJson': editedArgumentsJson,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmitToolDecisionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'turnId': turnId,
      'toolCallId': toolCallId,
      'argumentsDigest': argumentsDigest,
      'expectedTurnRevision': expectedTurnRevision,
      'decision': decision,
      'stopAll': stopAll,
      if (editedArgumentsJson != null)
        'editedArgumentsJson': editedArgumentsJson,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmitToolDecisionRequestImpl extends SubmitToolDecisionRequest {
  _SubmitToolDecisionRequestImpl({
    required int workspaceId,
    required String requestId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    required String decision,
    bool? stopAll,
    String? editedArgumentsJson,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         turnId: turnId,
         toolCallId: toolCallId,
         argumentsDigest: argumentsDigest,
         expectedTurnRevision: expectedTurnRevision,
         decision: decision,
         stopAll: stopAll,
         editedArgumentsJson: editedArgumentsJson,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [SubmitToolDecisionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmitToolDecisionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? turnId,
    String? toolCallId,
    String? argumentsDigest,
    int? expectedTurnRevision,
    String? decision,
    bool? stopAll,
    Object? editedArgumentsJson = _Undefined,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return SubmitToolDecisionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      turnId: turnId ?? this.turnId,
      toolCallId: toolCallId ?? this.toolCallId,
      argumentsDigest: argumentsDigest ?? this.argumentsDigest,
      expectedTurnRevision: expectedTurnRevision ?? this.expectedTurnRevision,
      decision: decision ?? this.decision,
      stopAll: stopAll ?? this.stopAll,
      editedArgumentsJson: editedArgumentsJson is String?
          ? editedArgumentsJson
          : this.editedArgumentsJson,
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
