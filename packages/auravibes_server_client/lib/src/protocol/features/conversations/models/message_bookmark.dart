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

abstract class MessageBookmark
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MessageBookmark._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.messageId,
    required this.createdAt,
  });

  factory MessageBookmark({
    int? id,
    required int workspaceId,
    required String userId,
    required int messageId,
    required DateTime createdAt,
  }) = _MessageBookmarkImpl;

  factory MessageBookmark.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessageBookmark(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      messageId: jsonSerialization['messageId'] as int,
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

  String userId;

  int messageId;

  DateTime createdAt;

  /// Returns a shallow copy of this [MessageBookmark]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MessageBookmark copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    int? messageId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageBookmark',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MessageBookmark',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageBookmarkImpl extends MessageBookmark {
  _MessageBookmarkImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required int messageId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         messageId: messageId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessageBookmark]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MessageBookmark copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    int? messageId,
    DateTime? createdAt,
  }) {
    return MessageBookmark(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
