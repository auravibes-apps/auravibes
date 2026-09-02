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

import '../../../../features/sync/stream/models/workspace_stream_envelope_kind.dart'
    as _i2;

abstract class WorkspaceStreamEnvelope._({
  required var _i2.WorkspaceStreamEnvelopeKind kind,
  required var int workspaceId,
  required var int sequence,
  required var String eventId,
  required var String eventKind,
  required var String resourceKind,
  var String? resourceId,
  var String? payloadJson,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    required _i2.WorkspaceStreamEnvelopeKind kind,
    required int workspaceId,
    required int sequence,
    required String eventId,
    required String eventKind,
    required String resourceKind,
    String? resourceId,
    String? payloadJson,
    required DateTime createdAt,
  }) = _WorkspaceStreamEnvelopeImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceStreamEnvelope(
      kind: _i2.WorkspaceStreamEnvelopeKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      workspaceId: jsonSerialization['workspaceId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      eventId: jsonSerialization['eventId'] as String,
      eventKind: jsonSerialization['eventKind'] as String,
      resourceKind: jsonSerialization['resourceKind'] as String,
      resourceId: jsonSerialization['resourceId'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [WorkspaceStreamEnvelope]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceStreamEnvelope copyWith({
    _i2.WorkspaceStreamEnvelopeKind? kind,
    int? workspaceId,
    int? sequence,
    String? eventId,
    String? eventKind,
    String? resourceKind,
    String? resourceId,
    String? payloadJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceStreamEnvelope',
      'kind': kind.toJson(),
      'workspaceId': workspaceId,
      'sequence': sequence,
      'eventId': eventId,
      'eventKind': eventKind,
      'resourceKind': resourceKind,
      if (resourceId != null) 'resourceId': resourceId,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceStreamEnvelopeImpl({
  required _i2.WorkspaceStreamEnvelopeKind kind,
  required int workspaceId,
  required int sequence,
  required String eventId,
  required String eventKind,
  required String resourceKind,
  String? resourceId,
  String? payloadJson,
  required DateTime createdAt,
}) extends WorkspaceStreamEnvelope {
  this
    : super._(
        kind: kind,
        workspaceId: workspaceId,
        sequence: sequence,
        eventId: eventId,
        eventKind: eventKind,
        resourceKind: resourceKind,
        resourceId: resourceId,
        payloadJson: payloadJson,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [WorkspaceStreamEnvelope]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceStreamEnvelope copyWith({
    _i2.WorkspaceStreamEnvelopeKind? kind,
    int? workspaceId,
    int? sequence,
    String? eventId,
    String? eventKind,
    String? resourceKind,
    Object? resourceId = _Undefined,
    Object? payloadJson = _Undefined,
    DateTime? createdAt,
  }) {
    return WorkspaceStreamEnvelope(
      kind: kind ?? this.kind,
      workspaceId: workspaceId ?? this.workspaceId,
      sequence: sequence ?? this.sequence,
      eventId: eventId ?? this.eventId,
      eventKind: eventKind ?? this.eventKind,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId is String? ? resourceId : this.resourceId,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
