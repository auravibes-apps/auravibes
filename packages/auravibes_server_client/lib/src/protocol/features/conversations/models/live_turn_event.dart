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
import '../../../features/conversations/models/live_turn_event_kind.dart'
    as _i2;

abstract class LiveTurnEvent implements _i1.SerializableModel {
  LiveTurnEvent._({
    required this.workspaceId,
    required this.turnId,
    required this.sequence,
    required this.kind,
    this.text,
    this.messageId,
    this.errorCode,
  });

  factory LiveTurnEvent({
    required int workspaceId,
    required String turnId,
    required int sequence,
    required _i2.LiveTurnEventKind kind,
    String? text,
    String? messageId,
    String? errorCode,
  }) = _LiveTurnEventImpl;

  factory LiveTurnEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveTurnEvent(
      workspaceId: jsonSerialization['workspaceId'] as int,
      turnId: jsonSerialization['turnId'] as String,
      sequence: jsonSerialization['sequence'] as int,
      kind: _i2.LiveTurnEventKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      text: jsonSerialization['text'] as String?,
      messageId: jsonSerialization['messageId'] as String?,
      errorCode: jsonSerialization['errorCode'] as String?,
    );
  }

  int workspaceId;

  String turnId;

  int sequence;

  _i2.LiveTurnEventKind kind;

  String? text;

  String? messageId;

  String? errorCode;

  /// Returns a shallow copy of this [LiveTurnEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LiveTurnEvent copyWith({
    int? workspaceId,
    String? turnId,
    int? sequence,
    _i2.LiveTurnEventKind? kind,
    String? text,
    String? messageId,
    String? errorCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveTurnEvent',
      'workspaceId': workspaceId,
      'turnId': turnId,
      'sequence': sequence,
      'kind': kind.toJson(),
      if (text != null) 'text': text,
      if (messageId != null) 'messageId': messageId,
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveTurnEventImpl extends LiveTurnEvent {
  _LiveTurnEventImpl({
    required int workspaceId,
    required String turnId,
    required int sequence,
    required _i2.LiveTurnEventKind kind,
    String? text,
    String? messageId,
    String? errorCode,
  }) : super._(
         workspaceId: workspaceId,
         turnId: turnId,
         sequence: sequence,
         kind: kind,
         text: text,
         messageId: messageId,
         errorCode: errorCode,
       );

  /// Returns a shallow copy of this [LiveTurnEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LiveTurnEvent copyWith({
    int? workspaceId,
    String? turnId,
    int? sequence,
    _i2.LiveTurnEventKind? kind,
    Object? text = _Undefined,
    Object? messageId = _Undefined,
    Object? errorCode = _Undefined,
  }) {
    return LiveTurnEvent(
      workspaceId: workspaceId ?? this.workspaceId,
      turnId: turnId ?? this.turnId,
      sequence: sequence ?? this.sequence,
      kind: kind ?? this.kind,
      text: text is String? ? text : this.text,
      messageId: messageId is String? ? messageId : this.messageId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
    );
  }
}
