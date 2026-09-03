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

abstract class WorkspaceEvent implements _i1.SerializableModel {
  WorkspaceEvent._({
    this.id,
    required this.eventId,
    required this.workspaceId,
    required this.sequence,
    required this.actorUserId,
    required this.kind,
    required this.resourceKind,
    this.resourceId,
    this.payloadJson,
    required this.createdAt,
    this.publishedAt,
  });

  factory WorkspaceEvent({
    int? id,
    required String eventId,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String kind,
    required String resourceKind,
    String? resourceId,
    String? payloadJson,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) = _WorkspaceEventImpl;

  factory WorkspaceEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceEvent(
      id: jsonSerialization['id'] as int?,
      eventId: jsonSerialization['eventId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      kind: jsonSerialization['kind'] as String,
      resourceKind: jsonSerialization['resourceKind'] as String,
      resourceId: jsonSerialization['resourceId'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String eventId;

  int workspaceId;

  int sequence;

  String actorUserId;

  String kind;

  String resourceKind;

  String? resourceId;

  String? payloadJson;

  DateTime createdAt;

  DateTime? publishedAt;

  /// Returns a shallow copy of this [WorkspaceEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceEvent copyWith({
    int? id,
    String? eventId,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? kind,
    String? resourceKind,
    String? resourceId,
    String? payloadJson,
    DateTime? createdAt,
    DateTime? publishedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceEvent',
      if (id != null) 'id': id,
      'eventId': eventId,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'kind': kind,
      'resourceKind': resourceKind,
      if (resourceId != null) 'resourceId': resourceId,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceEventImpl extends WorkspaceEvent {
  _WorkspaceEventImpl({
    int? id,
    required String eventId,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String kind,
    required String resourceKind,
    String? resourceId,
    String? payloadJson,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) : super._(
         id: id,
         eventId: eventId,
         workspaceId: workspaceId,
         sequence: sequence,
         actorUserId: actorUserId,
         kind: kind,
         resourceKind: resourceKind,
         resourceId: resourceId,
         payloadJson: payloadJson,
         createdAt: createdAt,
         publishedAt: publishedAt,
       );

  /// Returns a shallow copy of this [WorkspaceEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceEvent copyWith({
    Object? id = _Undefined,
    String? eventId,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? kind,
    String? resourceKind,
    Object? resourceId = _Undefined,
    Object? payloadJson = _Undefined,
    DateTime? createdAt,
    Object? publishedAt = _Undefined,
  }) {
    return WorkspaceEvent(
      id: id is int? ? id : this.id,
      eventId: eventId ?? this.eventId,
      workspaceId: workspaceId ?? this.workspaceId,
      sequence: sequence ?? this.sequence,
      actorUserId: actorUserId ?? this.actorUserId,
      kind: kind ?? this.kind,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId is String? ? resourceId : this.resourceId,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt is DateTime? ? publishedAt : this.publishedAt,
    );
  }
}
