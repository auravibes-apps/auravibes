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

abstract class WorkspaceInvite._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var String email,
  required var String normalizedEmail,
  required var String role,
  required var String invitedByUserId,
  var String? acceptedByUserId,
  required var int revision,
  required var DateTime createdAt,
  required var DateTime updatedAt,
  var DateTime? expiresAt,
  var DateTime? acceptedAt,
  var DateTime? declinedAt,
  var DateTime? revokedAt,
  var String? pendingKey,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required String email,
    required String normalizedEmail,
    required String role,
    required String invitedByUserId,
    String? acceptedByUserId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  }) = _WorkspaceInviteImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceInvite(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      email: jsonSerialization['email'] as String,
      normalizedEmail: jsonSerialization['normalizedEmail'] as String,
      role: jsonSerialization['role'] as String,
      invitedByUserId: jsonSerialization['invitedByUserId'] as String,
      acceptedByUserId: jsonSerialization['acceptedByUserId'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      acceptedAt: jsonSerialization['acceptedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['acceptedAt']),
      declinedAt: jsonSerialization['declinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['declinedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      pendingKey: jsonSerialization['pendingKey'] as String?,
    );
  }

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceInvite copyWith({
    int? id,
    int? workspaceId,
    String? email,
    String? normalizedEmail,
    String? role,
    String? invitedByUserId,
    String? acceptedByUserId,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceInvite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'email': email,
      'normalizedEmail': normalizedEmail,
      'role': role,
      'invitedByUserId': invitedByUserId,
      if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt?.toJson(),
      if (declinedAt != null) 'declinedAt': declinedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      if (pendingKey != null) 'pendingKey': pendingKey,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceInviteImpl({
  int? id,
  required int workspaceId,
  required String email,
  required String normalizedEmail,
  required String role,
  required String invitedByUserId,
  String? acceptedByUserId,
  required int revision,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? expiresAt,
  DateTime? acceptedAt,
  DateTime? declinedAt,
  DateTime? revokedAt,
  String? pendingKey,
}) extends WorkspaceInvite {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        email: email,
        normalizedEmail: normalizedEmail,
        role: role,
        invitedByUserId: invitedByUserId,
        acceptedByUserId: acceptedByUserId,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
        expiresAt: expiresAt,
        acceptedAt: acceptedAt,
        declinedAt: declinedAt,
        revokedAt: revokedAt,
        pendingKey: pendingKey,
      );

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceInvite copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? email,
    String? normalizedEmail,
    String? role,
    String? invitedByUserId,
    Object? acceptedByUserId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? expiresAt = _Undefined,
    Object? acceptedAt = _Undefined,
    Object? declinedAt = _Undefined,
    Object? revokedAt = _Undefined,
    Object? pendingKey = _Undefined,
  }) {
    return WorkspaceInvite(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      email: email ?? this.email,
      normalizedEmail: normalizedEmail ?? this.normalizedEmail,
      role: role ?? this.role,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      acceptedByUserId: acceptedByUserId is String?
          ? acceptedByUserId
          : this.acceptedByUserId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      acceptedAt: acceptedAt is DateTime? ? acceptedAt : this.acceptedAt,
      declinedAt: declinedAt is DateTime? ? declinedAt : this.declinedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      pendingKey: pendingKey is String? ? pendingKey : this.pendingKey,
    );
  }
}
