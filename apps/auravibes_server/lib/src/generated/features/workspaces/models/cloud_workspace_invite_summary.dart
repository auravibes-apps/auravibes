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

abstract class CloudWorkspaceInviteSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CloudWorkspaceInviteSummary._({
    required this.id,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    required this.revision,
    required this.createdAt,
    required this.expiresAt,
  });

  factory CloudWorkspaceInviteSummary({
    required int id,
    required String email,
    required String role,
    required String invitedByUserId,
    required int revision,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) = _CloudWorkspaceInviteSummaryImpl;

  factory CloudWorkspaceInviteSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceInviteSummary(
      id: jsonSerialization['id'] as int,
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      invitedByUserId: jsonSerialization['invitedByUserId'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  int id;

  String email;

  String role;

  String invitedByUserId;

  int revision;

  DateTime createdAt;

  DateTime expiresAt;

  /// Returns a shallow copy of this [CloudWorkspaceInviteSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspaceInviteSummary copyWith({
    int? id,
    String? email,
    String? role,
    String? invitedByUserId,
    int? revision,
    DateTime? createdAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceInviteSummary',
      'id': id,
      'email': email,
      'role': role,
      'invitedByUserId': invitedByUserId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CloudWorkspaceInviteSummary',
      'id': id,
      'email': email,
      'role': role,
      'invitedByUserId': invitedByUserId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CloudWorkspaceInviteSummaryImpl extends CloudWorkspaceInviteSummary {
  _CloudWorkspaceInviteSummaryImpl({
    required int id,
    required String email,
    required String role,
    required String invitedByUserId,
    required int revision,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         email: email,
         role: role,
         invitedByUserId: invitedByUserId,
         revision: revision,
         createdAt: createdAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [CloudWorkspaceInviteSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudWorkspaceInviteSummary copyWith({
    int? id,
    String? email,
    String? role,
    String? invitedByUserId,
    int? revision,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return CloudWorkspaceInviteSummary(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
