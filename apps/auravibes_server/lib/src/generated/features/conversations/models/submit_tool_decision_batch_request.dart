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

import '../../../features/conversations/models/submit_tool_decision_batch_call.dart'
    as _i1i6ti7b;

abstract class SubmitToolDecisionBatchRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmitToolDecisionBatchRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.decision,
    required this.calls,
    this.a2uiSupportedComponents,
  });

  factory SubmitToolDecisionBatchRequest({
    required int workspaceId,
    required String requestId,
    required String decision,
    required List<_i1i6ti7b.SubmitToolDecisionBatchCall> calls,
    List<String>? a2uiSupportedComponents,
  }) = _SubmitToolDecisionBatchRequestImpl;

  factory SubmitToolDecisionBatchRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SubmitToolDecisionBatchRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      decision: jsonSerialization['decision'] as String,
      calls: _if5qez1k.Protocol()
          .deserialize<List<_i1i6ti7b.SubmitToolDecisionBatchCall>>(
            jsonSerialization['calls'],
          ),
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

  String decision;

  List<_i1i6ti7b.SubmitToolDecisionBatchCall> calls;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [SubmitToolDecisionBatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmitToolDecisionBatchRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? decision,
    List<_i1i6ti7b.SubmitToolDecisionBatchCall>? calls,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmitToolDecisionBatchRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'decision': decision,
      'calls': calls.toJson(valueToJson: (v) => v.toJson()),
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmitToolDecisionBatchRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'decision': decision,
      'calls': calls.toJson(valueToJson: (v) => v.toJsonForProtocol()),
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

class _SubmitToolDecisionBatchRequestImpl
    extends SubmitToolDecisionBatchRequest {
  _SubmitToolDecisionBatchRequestImpl({
    required int workspaceId,
    required String requestId,
    required String decision,
    required List<_i1i6ti7b.SubmitToolDecisionBatchCall> calls,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         decision: decision,
         calls: calls,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [SubmitToolDecisionBatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmitToolDecisionBatchRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? decision,
    List<_i1i6ti7b.SubmitToolDecisionBatchCall>? calls,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return SubmitToolDecisionBatchRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      decision: decision ?? this.decision,
      calls: calls ?? this.calls.map((e0) => e0.copyWith()).toList(),
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
