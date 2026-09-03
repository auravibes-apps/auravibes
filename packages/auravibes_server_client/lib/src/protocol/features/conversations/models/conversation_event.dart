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

import '../../../features/conversations/models/conversation_event_type.dart'
    as _i2;

abstract class ConversationEvent implements _i1.SerializableModel {
  ConversationEvent._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.sequence,
    required this.eventId,
    required this.actorUserId,
    required this.requestId,
    required this.kind,
    required this.payloadJson,
    required this.createdAt,
  });

  factory ConversationEvent({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int sequence,
    required String eventId,
    required String actorUserId,
    required String requestId,
    required _i2.ConversationEventType kind,
    required String payloadJson,
    required DateTime createdAt,
  }) = _ConversationEventImpl;

  factory ConversationEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationEvent(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      eventId: jsonSerialization['eventId'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      kind: _i2.ConversationEventType.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      payloadJson: jsonSerialization['payloadJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  int conversationId;

  int sequence;

  String eventId;

  String actorUserId;

  String requestId;

  _i2.ConversationEventType kind;

  String payloadJson;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConversationEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationEvent copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _i2.ConversationEventType? kind,
    String? payloadJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationEvent',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'sequence': sequence,
      'eventId': eventId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'kind': kind.toJson(),
      'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationEventImpl extends ConversationEvent {
  _ConversationEventImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int sequence,
    required String eventId,
    required String actorUserId,
    required String requestId,
    required _i2.ConversationEventType kind,
    required String payloadJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         sequence: sequence,
         eventId: eventId,
         actorUserId: actorUserId,
         requestId: requestId,
         kind: kind,
         payloadJson: payloadJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationEvent copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _i2.ConversationEventType? kind,
    String? payloadJson,
    DateTime? createdAt,
  }) {
    return ConversationEvent(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      sequence: sequence ?? this.sequence,
      eventId: eventId ?? this.eventId,
      actorUserId: actorUserId ?? this.actorUserId,
      requestId: requestId ?? this.requestId,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
