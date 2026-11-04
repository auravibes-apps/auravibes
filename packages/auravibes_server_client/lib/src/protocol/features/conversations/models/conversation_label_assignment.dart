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

abstract class ConversationLabelAssignment
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationLabelAssignment._({
    this.id,
    required this.workspaceId,
    required this.labelId,
    required this.conversationId,
    required this.createdAt,
  });

  factory ConversationLabelAssignment({
    int? id,
    required int workspaceId,
    required int labelId,
    required int conversationId,
    required DateTime createdAt,
  }) = _ConversationLabelAssignmentImpl;

  factory ConversationLabelAssignment.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationLabelAssignment(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      labelId: jsonSerialization['labelId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
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

  int labelId;

  int conversationId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConversationLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationLabelAssignment copyWith({
    int? id,
    int? workspaceId,
    int? labelId,
    int? conversationId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationLabelAssignment',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'labelId': labelId,
      'conversationId': conversationId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationLabelAssignment',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'labelId': labelId,
      'conversationId': conversationId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationLabelAssignmentImpl extends ConversationLabelAssignment {
  _ConversationLabelAssignmentImpl({
    int? id,
    required int workspaceId,
    required int labelId,
    required int conversationId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         labelId: labelId,
         conversationId: conversationId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationLabelAssignment copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? labelId,
    int? conversationId,
    DateTime? createdAt,
  }) {
    return ConversationLabelAssignment(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      labelId: labelId ?? this.labelId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
