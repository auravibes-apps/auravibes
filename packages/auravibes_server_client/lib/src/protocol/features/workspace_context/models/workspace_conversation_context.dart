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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class WorkspaceConversationContext
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceConversationContext._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.stableId,
    required this.actorUserId,
    this.selectionJson,
    required this.createdAt,
  });

  factory WorkspaceConversationContext({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String actorUserId,
    String? selectionJson,
    required DateTime createdAt,
  }) = _WorkspaceConversationContextImpl;

  factory WorkspaceConversationContext.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceConversationContext(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      selectionJson: jsonSerialization['selectionJson'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
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

  String stableId;

  String actorUserId;

  String? selectionJson;

  DateTime createdAt;

  /// Returns a shallow copy of this [WorkspaceConversationContext]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceConversationContext copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? actorUserId,
    String? selectionJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceConversationContext',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'actorUserId': actorUserId,
      if (selectionJson != null) 'selectionJson': selectionJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceConversationContext',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'actorUserId': actorUserId,
      if (selectionJson != null) 'selectionJson': selectionJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceConversationContextImpl extends WorkspaceConversationContext {
  _WorkspaceConversationContextImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String actorUserId,
    String? selectionJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         stableId: stableId,
         actorUserId: actorUserId,
         selectionJson: selectionJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceConversationContext]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceConversationContext copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? actorUserId,
    Object? selectionJson = _Undefined,
    DateTime? createdAt,
  }) {
    return WorkspaceConversationContext(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      actorUserId: actorUserId ?? this.actorUserId,
      selectionJson: selectionJson is String?
          ? selectionJson
          : this.selectionJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
