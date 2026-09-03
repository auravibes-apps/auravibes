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

abstract class PendingWorkspaceInviteSummary implements _i1.SerializableModel {
  PendingWorkspaceInviteSummary._({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.email,
    required this.role,
    required this.revision,
    required this.createdAt,
  });

  factory PendingWorkspaceInviteSummary({
    required int id,
    required int workspaceId,
    required String workspaceName,
    required String email,
    required String role,
    required int revision,
    required DateTime createdAt,
  }) = _PendingWorkspaceInviteSummaryImpl;

  factory PendingWorkspaceInviteSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PendingWorkspaceInviteSummary(
      id: jsonSerialization['id'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      workspaceName: jsonSerialization['workspaceName'] as String,
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  int workspaceId;

  String workspaceName;

  String email;

  String role;

  int revision;

  DateTime createdAt;

  /// Returns a shallow copy of this [PendingWorkspaceInviteSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PendingWorkspaceInviteSummary copyWith({
    int? id,
    int? workspaceId,
    String? workspaceName,
    String? email,
    String? role,
    int? revision,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PendingWorkspaceInviteSummary',
      'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'email': email,
      'role': role,
      'revision': revision,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PendingWorkspaceInviteSummaryImpl extends PendingWorkspaceInviteSummary {
  _PendingWorkspaceInviteSummaryImpl({
    required int id,
    required int workspaceId,
    required String workspaceName,
    required String email,
    required String role,
    required int revision,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         workspaceName: workspaceName,
         email: email,
         role: role,
         revision: revision,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PendingWorkspaceInviteSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PendingWorkspaceInviteSummary copyWith({
    int? id,
    int? workspaceId,
    String? workspaceName,
    String? email,
    String? role,
    int? revision,
    DateTime? createdAt,
  }) {
    return PendingWorkspaceInviteSummary(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      email: email ?? this.email,
      role: role ?? this.role,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
