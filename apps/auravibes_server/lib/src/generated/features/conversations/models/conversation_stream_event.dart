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

import '../../../features/conversations/models/conversation_event_type.dart'
    as _i2;

abstract class ConversationStreamEvent
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationStreamEvent._({
    required this.workspaceId,
    required this.conversationId,
    required this.sequence,
    required this.kind,
    required this.actorUserId,
    required this.payloadJson,
    this.transientTextDelta,
    required this.createdAt,
  });

  factory ConversationStreamEvent({
    required int workspaceId,
    required String conversationId,
    required int sequence,
    required _i2.ConversationEventType kind,
    required String actorUserId,
    required String payloadJson,
    String? transientTextDelta,
    required DateTime createdAt,
  }) = _ConversationStreamEventImpl;

  factory ConversationStreamEvent.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationStreamEvent(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      sequence: jsonSerialization['sequence'] as int,
      kind: _i2.ConversationEventType.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      actorUserId: jsonSerialization['actorUserId'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
      transientTextDelta: jsonSerialization['transientTextDelta'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int workspaceId;

  String conversationId;

  int sequence;

  _i2.ConversationEventType kind;

  String actorUserId;

  String payloadJson;

  String? transientTextDelta;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConversationStreamEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationStreamEvent copyWith({
    int? workspaceId,
    String? conversationId,
    int? sequence,
    _i2.ConversationEventType? kind,
    String? actorUserId,
    String? payloadJson,
    String? transientTextDelta,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationStreamEvent',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'sequence': sequence,
      'kind': kind.toJson(),
      'actorUserId': actorUserId,
      'payloadJson': payloadJson,
      if (transientTextDelta != null) 'transientTextDelta': transientTextDelta,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationStreamEvent',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'sequence': sequence,
      'kind': kind.toJson(),
      'actorUserId': actorUserId,
      'payloadJson': payloadJson,
      if (transientTextDelta != null) 'transientTextDelta': transientTextDelta,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationStreamEventImpl extends ConversationStreamEvent {
  _ConversationStreamEventImpl({
    required int workspaceId,
    required String conversationId,
    required int sequence,
    required _i2.ConversationEventType kind,
    required String actorUserId,
    required String payloadJson,
    String? transientTextDelta,
    required DateTime createdAt,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
         sequence: sequence,
         kind: kind,
         actorUserId: actorUserId,
         payloadJson: payloadJson,
         transientTextDelta: transientTextDelta,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationStreamEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationStreamEvent copyWith({
    int? workspaceId,
    String? conversationId,
    int? sequence,
    _i2.ConversationEventType? kind,
    String? actorUserId,
    String? payloadJson,
    Object? transientTextDelta = _Undefined,
    DateTime? createdAt,
  }) {
    return ConversationStreamEvent(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      sequence: sequence ?? this.sequence,
      kind: kind ?? this.kind,
      actorUserId: actorUserId ?? this.actorUserId,
      payloadJson: payloadJson ?? this.payloadJson,
      transientTextDelta: transientTextDelta is String?
          ? transientTextDelta
          : this.transientTextDelta,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
