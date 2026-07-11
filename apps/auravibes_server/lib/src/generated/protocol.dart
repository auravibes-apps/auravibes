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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'features/accounts/models/account_summary.dart' as _i5;
import 'features/workspaces/models/accept_workspace_invite_request.dart' as _i6;
import 'features/workspaces/models/cloud_workspace.dart' as _i7;
import 'features/workspaces/models/cloud_workspace_capabilities.dart' as _i8;
import 'features/workspaces/models/cloud_workspace_detail.dart' as _i9;
import 'features/workspaces/models/cloud_workspace_error_code.dart' as _i10;
import 'features/workspaces/models/cloud_workspace_exception.dart' as _i11;
import 'features/workspaces/models/cloud_workspace_invite_summary.dart' as _i12;
import 'features/workspaces/models/cloud_workspace_member_summary.dart' as _i13;
import 'features/workspaces/models/cloud_workspace_summary.dart' as _i14;
import 'features/workspaces/models/create_cloud_workspace_request.dart' as _i15;
import 'features/workspaces/models/decline_workspace_invite_request.dart'
    as _i16;
import 'features/workspaces/models/delete_cloud_workspace_request.dart' as _i17;
import 'features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i18;
import 'features/workspaces/models/invite_workspace_member_request.dart'
    as _i19;
import 'features/workspaces/models/leave_cloud_workspace_request.dart' as _i20;
import 'features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i21;
import 'features/workspaces/models/list_workspace_members_request.dart' as _i22;
import 'features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i23;
import 'features/workspaces/models/remove_workspace_member_request.dart'
    as _i24;
import 'features/workspaces/models/rename_cloud_workspace_request.dart' as _i25;
import 'features/workspaces/models/renew_workspace_invite_request.dart' as _i26;
import 'features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i27;
import 'features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i28;
import 'features/workspaces/models/update_workspace_member_role_request.dart'
    as _i29;
import 'features/workspaces/models/workspace_invite.dart' as _i30;
import 'features/workspaces/models/workspace_member.dart' as _i31;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_summary.dart'
    as _i32;
import 'package:auravibes_server/src/generated/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i33;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i34;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i35;
export 'features/accounts/models/account_summary.dart';
export 'features/workspaces/models/accept_workspace_invite_request.dart';
export 'features/workspaces/models/cloud_workspace.dart';
export 'features/workspaces/models/cloud_workspace_capabilities.dart';
export 'features/workspaces/models/cloud_workspace_detail.dart';
export 'features/workspaces/models/cloud_workspace_error_code.dart';
export 'features/workspaces/models/cloud_workspace_exception.dart';
export 'features/workspaces/models/cloud_workspace_invite_summary.dart';
export 'features/workspaces/models/cloud_workspace_member_summary.dart';
export 'features/workspaces/models/cloud_workspace_summary.dart';
export 'features/workspaces/models/create_cloud_workspace_request.dart';
export 'features/workspaces/models/decline_workspace_invite_request.dart';
export 'features/workspaces/models/delete_cloud_workspace_request.dart';
export 'features/workspaces/models/get_cloud_workspace_detail_request.dart';
export 'features/workspaces/models/invite_workspace_member_request.dart';
export 'features/workspaces/models/leave_cloud_workspace_request.dart';
export 'features/workspaces/models/list_cloud_workspace_invites_request.dart';
export 'features/workspaces/models/list_workspace_members_request.dart';
export 'features/workspaces/models/pending_workspace_invite_summary.dart';
export 'features/workspaces/models/remove_workspace_member_request.dart';
export 'features/workspaces/models/rename_cloud_workspace_request.dart';
export 'features/workspaces/models/renew_workspace_invite_request.dart';
export 'features/workspaces/models/revoke_workspace_invite_request.dart';
export 'features/workspaces/models/transfer_cloud_workspace_ownership_request.dart';
export 'features/workspaces/models/update_workspace_member_role_request.dart';
export 'features/workspaces/models/workspace_invite.dart';
export 'features/workspaces/models/workspace_member.dart';

class Protocol extends _i1.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'cloud_workspace',
      dartName: 'CloudWorkspace',
      schema: 'public',
      module: 'auravibes',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'ownerUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_invite',
      dartName: 'WorkspaceInvite',
      schema: 'public',
      module: 'auravibes',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'invitedByUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'acceptedByUserId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'acceptedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'declinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'revokedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'pendingKey',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_invite_pending_key_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'pendingKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_member',
      dartName: 'WorkspaceMember',
      schema: 'public',
      module: 'auravibes',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'removedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_member_workspace_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.AccountSummary) {
      return _i5.AccountSummary.fromJson(data) as T;
    }
    if (t == _i6.AcceptWorkspaceInviteRequest) {
      return _i6.AcceptWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i7.CloudWorkspace) {
      return _i7.CloudWorkspace.fromJson(data) as T;
    }
    if (t == _i8.CloudWorkspaceCapabilities) {
      return _i8.CloudWorkspaceCapabilities.fromJson(data) as T;
    }
    if (t == _i9.CloudWorkspaceDetail) {
      return _i9.CloudWorkspaceDetail.fromJson(data) as T;
    }
    if (t == _i10.CloudWorkspaceErrorCode) {
      return _i10.CloudWorkspaceErrorCode.fromJson(data) as T;
    }
    if (t == _i11.CloudWorkspaceException) {
      return _i11.CloudWorkspaceException.fromJson(data) as T;
    }
    if (t == _i12.CloudWorkspaceInviteSummary) {
      return _i12.CloudWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i13.CloudWorkspaceMemberSummary) {
      return _i13.CloudWorkspaceMemberSummary.fromJson(data) as T;
    }
    if (t == _i14.CloudWorkspaceSummary) {
      return _i14.CloudWorkspaceSummary.fromJson(data) as T;
    }
    if (t == _i15.CreateCloudWorkspaceRequest) {
      return _i15.CreateCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i16.DeclineWorkspaceInviteRequest) {
      return _i16.DeclineWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i17.DeleteCloudWorkspaceRequest) {
      return _i17.DeleteCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i18.GetCloudWorkspaceDetailRequest) {
      return _i18.GetCloudWorkspaceDetailRequest.fromJson(data) as T;
    }
    if (t == _i19.InviteWorkspaceMemberRequest) {
      return _i19.InviteWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i20.LeaveCloudWorkspaceRequest) {
      return _i20.LeaveCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i21.ListCloudWorkspaceInvitesRequest) {
      return _i21.ListCloudWorkspaceInvitesRequest.fromJson(data) as T;
    }
    if (t == _i22.ListWorkspaceMembersRequest) {
      return _i22.ListWorkspaceMembersRequest.fromJson(data) as T;
    }
    if (t == _i23.PendingWorkspaceInviteSummary) {
      return _i23.PendingWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i24.RemoveWorkspaceMemberRequest) {
      return _i24.RemoveWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i25.RenameCloudWorkspaceRequest) {
      return _i25.RenameCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i26.RenewWorkspaceInviteRequest) {
      return _i26.RenewWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i27.RevokeWorkspaceInviteRequest) {
      return _i27.RevokeWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i28.TransferCloudWorkspaceOwnershipRequest) {
      return _i28.TransferCloudWorkspaceOwnershipRequest.fromJson(data) as T;
    }
    if (t == _i29.UpdateWorkspaceMemberRoleRequest) {
      return _i29.UpdateWorkspaceMemberRoleRequest.fromJson(data) as T;
    }
    if (t == _i30.WorkspaceInvite) {
      return _i30.WorkspaceInvite.fromJson(data) as T;
    }
    if (t == _i31.WorkspaceMember) {
      return _i31.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AccountSummary?>()) {
      return (data != null ? _i5.AccountSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AcceptWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i6.AcceptWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i7.CloudWorkspace?>()) {
      return (data != null ? _i7.CloudWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.CloudWorkspaceCapabilities?>()) {
      return (data != null
              ? _i8.CloudWorkspaceCapabilities.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i9.CloudWorkspaceDetail?>()) {
      return (data != null ? _i9.CloudWorkspaceDetail.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.CloudWorkspaceErrorCode?>()) {
      return (data != null ? _i10.CloudWorkspaceErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.CloudWorkspaceException?>()) {
      return (data != null ? _i11.CloudWorkspaceException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.CloudWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i12.CloudWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.CloudWorkspaceMemberSummary?>()) {
      return (data != null
              ? _i13.CloudWorkspaceMemberSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.CloudWorkspaceSummary?>()) {
      return (data != null ? _i14.CloudWorkspaceSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.CreateCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i15.CreateCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.DeclineWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i16.DeclineWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.DeleteCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i17.DeleteCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i18.GetCloudWorkspaceDetailRequest?>()) {
      return (data != null
              ? _i18.GetCloudWorkspaceDetailRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i19.InviteWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i19.InviteWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.LeaveCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i20.LeaveCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.ListCloudWorkspaceInvitesRequest?>()) {
      return (data != null
              ? _i21.ListCloudWorkspaceInvitesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i22.ListWorkspaceMembersRequest?>()) {
      return (data != null
              ? _i22.ListWorkspaceMembersRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i23.PendingWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i23.PendingWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i24.RemoveWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i24.RemoveWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.RenameCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i25.RenameCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i26.RenewWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i26.RenewWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i27.RevokeWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i27.RevokeWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i28.TransferCloudWorkspaceOwnershipRequest?>()) {
      return (data != null
              ? _i28.TransferCloudWorkspaceOwnershipRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i29.UpdateWorkspaceMemberRoleRequest?>()) {
      return (data != null
              ? _i29.UpdateWorkspaceMemberRoleRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i30.WorkspaceInvite?>()) {
      return (data != null ? _i30.WorkspaceInvite.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.WorkspaceMember?>()) {
      return (data != null ? _i31.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i32.CloudWorkspaceSummary>) {
      return (data as List)
              .map((e) => deserialize<_i32.CloudWorkspaceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.PendingWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i33.PendingWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.CloudWorkspaceMemberSummary>) {
      return (data as List)
              .map((e) => deserialize<_i34.CloudWorkspaceMemberSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i35.CloudWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i35.CloudWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.AccountSummary => 'AccountSummary',
      _i6.AcceptWorkspaceInviteRequest => 'AcceptWorkspaceInviteRequest',
      _i7.CloudWorkspace => 'CloudWorkspace',
      _i8.CloudWorkspaceCapabilities => 'CloudWorkspaceCapabilities',
      _i9.CloudWorkspaceDetail => 'CloudWorkspaceDetail',
      _i10.CloudWorkspaceErrorCode => 'CloudWorkspaceErrorCode',
      _i11.CloudWorkspaceException => 'CloudWorkspaceException',
      _i12.CloudWorkspaceInviteSummary => 'CloudWorkspaceInviteSummary',
      _i13.CloudWorkspaceMemberSummary => 'CloudWorkspaceMemberSummary',
      _i14.CloudWorkspaceSummary => 'CloudWorkspaceSummary',
      _i15.CreateCloudWorkspaceRequest => 'CreateCloudWorkspaceRequest',
      _i16.DeclineWorkspaceInviteRequest => 'DeclineWorkspaceInviteRequest',
      _i17.DeleteCloudWorkspaceRequest => 'DeleteCloudWorkspaceRequest',
      _i18.GetCloudWorkspaceDetailRequest => 'GetCloudWorkspaceDetailRequest',
      _i19.InviteWorkspaceMemberRequest => 'InviteWorkspaceMemberRequest',
      _i20.LeaveCloudWorkspaceRequest => 'LeaveCloudWorkspaceRequest',
      _i21.ListCloudWorkspaceInvitesRequest =>
        'ListCloudWorkspaceInvitesRequest',
      _i22.ListWorkspaceMembersRequest => 'ListWorkspaceMembersRequest',
      _i23.PendingWorkspaceInviteSummary => 'PendingWorkspaceInviteSummary',
      _i24.RemoveWorkspaceMemberRequest => 'RemoveWorkspaceMemberRequest',
      _i25.RenameCloudWorkspaceRequest => 'RenameCloudWorkspaceRequest',
      _i26.RenewWorkspaceInviteRequest => 'RenewWorkspaceInviteRequest',
      _i27.RevokeWorkspaceInviteRequest => 'RevokeWorkspaceInviteRequest',
      _i28.TransferCloudWorkspaceOwnershipRequest =>
        'TransferCloudWorkspaceOwnershipRequest',
      _i29.UpdateWorkspaceMemberRoleRequest =>
        'UpdateWorkspaceMemberRoleRequest',
      _i30.WorkspaceInvite => 'WorkspaceInvite',
      _i31.WorkspaceMember => 'WorkspaceMember',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('auravibes.', '');
    }

    switch (data) {
      case _i5.AccountSummary():
        return 'AccountSummary';
      case _i6.AcceptWorkspaceInviteRequest():
        return 'AcceptWorkspaceInviteRequest';
      case _i7.CloudWorkspace():
        return 'CloudWorkspace';
      case _i8.CloudWorkspaceCapabilities():
        return 'CloudWorkspaceCapabilities';
      case _i9.CloudWorkspaceDetail():
        return 'CloudWorkspaceDetail';
      case _i10.CloudWorkspaceErrorCode():
        return 'CloudWorkspaceErrorCode';
      case _i11.CloudWorkspaceException():
        return 'CloudWorkspaceException';
      case _i12.CloudWorkspaceInviteSummary():
        return 'CloudWorkspaceInviteSummary';
      case _i13.CloudWorkspaceMemberSummary():
        return 'CloudWorkspaceMemberSummary';
      case _i14.CloudWorkspaceSummary():
        return 'CloudWorkspaceSummary';
      case _i15.CreateCloudWorkspaceRequest():
        return 'CreateCloudWorkspaceRequest';
      case _i16.DeclineWorkspaceInviteRequest():
        return 'DeclineWorkspaceInviteRequest';
      case _i17.DeleteCloudWorkspaceRequest():
        return 'DeleteCloudWorkspaceRequest';
      case _i18.GetCloudWorkspaceDetailRequest():
        return 'GetCloudWorkspaceDetailRequest';
      case _i19.InviteWorkspaceMemberRequest():
        return 'InviteWorkspaceMemberRequest';
      case _i20.LeaveCloudWorkspaceRequest():
        return 'LeaveCloudWorkspaceRequest';
      case _i21.ListCloudWorkspaceInvitesRequest():
        return 'ListCloudWorkspaceInvitesRequest';
      case _i22.ListWorkspaceMembersRequest():
        return 'ListWorkspaceMembersRequest';
      case _i23.PendingWorkspaceInviteSummary():
        return 'PendingWorkspaceInviteSummary';
      case _i24.RemoveWorkspaceMemberRequest():
        return 'RemoveWorkspaceMemberRequest';
      case _i25.RenameCloudWorkspaceRequest():
        return 'RenameCloudWorkspaceRequest';
      case _i26.RenewWorkspaceInviteRequest():
        return 'RenewWorkspaceInviteRequest';
      case _i27.RevokeWorkspaceInviteRequest():
        return 'RevokeWorkspaceInviteRequest';
      case _i28.TransferCloudWorkspaceOwnershipRequest():
        return 'TransferCloudWorkspaceOwnershipRequest';
      case _i29.UpdateWorkspaceMemberRoleRequest():
        return 'UpdateWorkspaceMemberRoleRequest';
      case _i30.WorkspaceInvite():
        return 'WorkspaceInvite';
      case _i31.WorkspaceMember():
        return 'WorkspaceMember';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AccountSummary') {
      return deserialize<_i5.AccountSummary>(data['data']);
    }
    if (dataClassName == 'AcceptWorkspaceInviteRequest') {
      return deserialize<_i6.AcceptWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'CloudWorkspace') {
      return deserialize<_i7.CloudWorkspace>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceCapabilities') {
      return deserialize<_i8.CloudWorkspaceCapabilities>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceDetail') {
      return deserialize<_i9.CloudWorkspaceDetail>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceErrorCode') {
      return deserialize<_i10.CloudWorkspaceErrorCode>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceException') {
      return deserialize<_i11.CloudWorkspaceException>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceInviteSummary') {
      return deserialize<_i12.CloudWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceMemberSummary') {
      return deserialize<_i13.CloudWorkspaceMemberSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceSummary') {
      return deserialize<_i14.CloudWorkspaceSummary>(data['data']);
    }
    if (dataClassName == 'CreateCloudWorkspaceRequest') {
      return deserialize<_i15.CreateCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'DeclineWorkspaceInviteRequest') {
      return deserialize<_i16.DeclineWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'DeleteCloudWorkspaceRequest') {
      return deserialize<_i17.DeleteCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'GetCloudWorkspaceDetailRequest') {
      return deserialize<_i18.GetCloudWorkspaceDetailRequest>(data['data']);
    }
    if (dataClassName == 'InviteWorkspaceMemberRequest') {
      return deserialize<_i19.InviteWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'LeaveCloudWorkspaceRequest') {
      return deserialize<_i20.LeaveCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'ListCloudWorkspaceInvitesRequest') {
      return deserialize<_i21.ListCloudWorkspaceInvitesRequest>(data['data']);
    }
    if (dataClassName == 'ListWorkspaceMembersRequest') {
      return deserialize<_i22.ListWorkspaceMembersRequest>(data['data']);
    }
    if (dataClassName == 'PendingWorkspaceInviteSummary') {
      return deserialize<_i23.PendingWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'RemoveWorkspaceMemberRequest') {
      return deserialize<_i24.RemoveWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'RenameCloudWorkspaceRequest') {
      return deserialize<_i25.RenameCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'RenewWorkspaceInviteRequest') {
      return deserialize<_i26.RenewWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'RevokeWorkspaceInviteRequest') {
      return deserialize<_i27.RevokeWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'TransferCloudWorkspaceOwnershipRequest') {
      return deserialize<_i28.TransferCloudWorkspaceOwnershipRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'UpdateWorkspaceMemberRoleRequest') {
      return deserialize<_i29.UpdateWorkspaceMemberRoleRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceInvite') {
      return deserialize<_i30.WorkspaceInvite>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i31.WorkspaceMember>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _i3.Protocol().registerHostProtocol('auravibes', this);
    _i4.Protocol().registerHostProtocol('auravibes', this);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i7.CloudWorkspace:
        return _i7.CloudWorkspace.t;
      case _i30.WorkspaceInvite:
        return _i30.WorkspaceInvite.t;
      case _i31.WorkspaceMember:
        return _i31.WorkspaceMember.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'auravibes';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
