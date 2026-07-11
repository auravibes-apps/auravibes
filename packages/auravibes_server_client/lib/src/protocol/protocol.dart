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
import 'features/accounts/models/account_summary.dart' as _i2;
import 'features/workspaces/models/accept_workspace_invite_request.dart' as _i3;
import 'features/workspaces/models/cloud_workspace.dart' as _i4;
import 'features/workspaces/models/cloud_workspace_capabilities.dart' as _i5;
import 'features/workspaces/models/cloud_workspace_detail.dart' as _i6;
import 'features/workspaces/models/cloud_workspace_error_code.dart' as _i7;
import 'features/workspaces/models/cloud_workspace_exception.dart' as _i8;
import 'features/workspaces/models/cloud_workspace_invite_summary.dart' as _i9;
import 'features/workspaces/models/cloud_workspace_member_summary.dart' as _i10;
import 'features/workspaces/models/cloud_workspace_summary.dart' as _i11;
import 'features/workspaces/models/create_cloud_workspace_request.dart' as _i12;
import 'features/workspaces/models/decline_workspace_invite_request.dart'
    as _i13;
import 'features/workspaces/models/delete_cloud_workspace_request.dart' as _i14;
import 'features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i15;
import 'features/workspaces/models/invite_workspace_member_request.dart'
    as _i16;
import 'features/workspaces/models/leave_cloud_workspace_request.dart' as _i17;
import 'features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i18;
import 'features/workspaces/models/list_workspace_members_request.dart' as _i19;
import 'features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i20;
import 'features/workspaces/models/remove_workspace_member_request.dart'
    as _i21;
import 'features/workspaces/models/rename_cloud_workspace_request.dart' as _i22;
import 'features/workspaces/models/renew_workspace_invite_request.dart' as _i23;
import 'features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i24;
import 'features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i25;
import 'features/workspaces/models/update_workspace_member_role_request.dart'
    as _i26;
import 'features/workspaces/models/workspace_invite.dart' as _i27;
import 'features/workspaces/models/workspace_member.dart' as _i28;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_summary.dart'
    as _i29;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i30;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i31;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i32;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i33;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i34;
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
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

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

    if (t == _i2.AccountSummary) {
      return _i2.AccountSummary.fromJson(data) as T;
    }
    if (t == _i3.AcceptWorkspaceInviteRequest) {
      return _i3.AcceptWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i4.CloudWorkspace) {
      return _i4.CloudWorkspace.fromJson(data) as T;
    }
    if (t == _i5.CloudWorkspaceCapabilities) {
      return _i5.CloudWorkspaceCapabilities.fromJson(data) as T;
    }
    if (t == _i6.CloudWorkspaceDetail) {
      return _i6.CloudWorkspaceDetail.fromJson(data) as T;
    }
    if (t == _i7.CloudWorkspaceErrorCode) {
      return _i7.CloudWorkspaceErrorCode.fromJson(data) as T;
    }
    if (t == _i8.CloudWorkspaceException) {
      return _i8.CloudWorkspaceException.fromJson(data) as T;
    }
    if (t == _i9.CloudWorkspaceInviteSummary) {
      return _i9.CloudWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i10.CloudWorkspaceMemberSummary) {
      return _i10.CloudWorkspaceMemberSummary.fromJson(data) as T;
    }
    if (t == _i11.CloudWorkspaceSummary) {
      return _i11.CloudWorkspaceSummary.fromJson(data) as T;
    }
    if (t == _i12.CreateCloudWorkspaceRequest) {
      return _i12.CreateCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i13.DeclineWorkspaceInviteRequest) {
      return _i13.DeclineWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i14.DeleteCloudWorkspaceRequest) {
      return _i14.DeleteCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i15.GetCloudWorkspaceDetailRequest) {
      return _i15.GetCloudWorkspaceDetailRequest.fromJson(data) as T;
    }
    if (t == _i16.InviteWorkspaceMemberRequest) {
      return _i16.InviteWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i17.LeaveCloudWorkspaceRequest) {
      return _i17.LeaveCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i18.ListCloudWorkspaceInvitesRequest) {
      return _i18.ListCloudWorkspaceInvitesRequest.fromJson(data) as T;
    }
    if (t == _i19.ListWorkspaceMembersRequest) {
      return _i19.ListWorkspaceMembersRequest.fromJson(data) as T;
    }
    if (t == _i20.PendingWorkspaceInviteSummary) {
      return _i20.PendingWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i21.RemoveWorkspaceMemberRequest) {
      return _i21.RemoveWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i22.RenameCloudWorkspaceRequest) {
      return _i22.RenameCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i23.RenewWorkspaceInviteRequest) {
      return _i23.RenewWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i24.RevokeWorkspaceInviteRequest) {
      return _i24.RevokeWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i25.TransferCloudWorkspaceOwnershipRequest) {
      return _i25.TransferCloudWorkspaceOwnershipRequest.fromJson(data) as T;
    }
    if (t == _i26.UpdateWorkspaceMemberRoleRequest) {
      return _i26.UpdateWorkspaceMemberRoleRequest.fromJson(data) as T;
    }
    if (t == _i27.WorkspaceInvite) {
      return _i27.WorkspaceInvite.fromJson(data) as T;
    }
    if (t == _i28.WorkspaceMember) {
      return _i28.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AccountSummary?>()) {
      return (data != null ? _i2.AccountSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AcceptWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i3.AcceptWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i4.CloudWorkspace?>()) {
      return (data != null ? _i4.CloudWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.CloudWorkspaceCapabilities?>()) {
      return (data != null
              ? _i5.CloudWorkspaceCapabilities.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i6.CloudWorkspaceDetail?>()) {
      return (data != null ? _i6.CloudWorkspaceDetail.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.CloudWorkspaceErrorCode?>()) {
      return (data != null ? _i7.CloudWorkspaceErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.CloudWorkspaceException?>()) {
      return (data != null ? _i8.CloudWorkspaceException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.CloudWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i9.CloudWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i10.CloudWorkspaceMemberSummary?>()) {
      return (data != null
              ? _i10.CloudWorkspaceMemberSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.CloudWorkspaceSummary?>()) {
      return (data != null ? _i11.CloudWorkspaceSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.CreateCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i12.CreateCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.DeclineWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i13.DeclineWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.DeleteCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i14.DeleteCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.GetCloudWorkspaceDetailRequest?>()) {
      return (data != null
              ? _i15.GetCloudWorkspaceDetailRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.InviteWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i16.InviteWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.LeaveCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i17.LeaveCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i18.ListCloudWorkspaceInvitesRequest?>()) {
      return (data != null
              ? _i18.ListCloudWorkspaceInvitesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i19.ListWorkspaceMembersRequest?>()) {
      return (data != null
              ? _i19.ListWorkspaceMembersRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.PendingWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i20.PendingWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.RemoveWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i21.RemoveWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i22.RenameCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i22.RenameCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i23.RenewWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i23.RenewWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i24.RevokeWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i24.RevokeWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.TransferCloudWorkspaceOwnershipRequest?>()) {
      return (data != null
              ? _i25.TransferCloudWorkspaceOwnershipRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i26.UpdateWorkspaceMemberRoleRequest?>()) {
      return (data != null
              ? _i26.UpdateWorkspaceMemberRoleRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i27.WorkspaceInvite?>()) {
      return (data != null ? _i27.WorkspaceInvite.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.WorkspaceMember?>()) {
      return (data != null ? _i28.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i29.CloudWorkspaceSummary>) {
      return (data as List)
              .map((e) => deserialize<_i29.CloudWorkspaceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i30.PendingWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i30.PendingWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.CloudWorkspaceMemberSummary>) {
      return (data as List)
              .map((e) => deserialize<_i31.CloudWorkspaceMemberSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.CloudWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i32.CloudWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    try {
      return _i33.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i34.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AccountSummary => 'AccountSummary',
      _i3.AcceptWorkspaceInviteRequest => 'AcceptWorkspaceInviteRequest',
      _i4.CloudWorkspace => 'CloudWorkspace',
      _i5.CloudWorkspaceCapabilities => 'CloudWorkspaceCapabilities',
      _i6.CloudWorkspaceDetail => 'CloudWorkspaceDetail',
      _i7.CloudWorkspaceErrorCode => 'CloudWorkspaceErrorCode',
      _i8.CloudWorkspaceException => 'CloudWorkspaceException',
      _i9.CloudWorkspaceInviteSummary => 'CloudWorkspaceInviteSummary',
      _i10.CloudWorkspaceMemberSummary => 'CloudWorkspaceMemberSummary',
      _i11.CloudWorkspaceSummary => 'CloudWorkspaceSummary',
      _i12.CreateCloudWorkspaceRequest => 'CreateCloudWorkspaceRequest',
      _i13.DeclineWorkspaceInviteRequest => 'DeclineWorkspaceInviteRequest',
      _i14.DeleteCloudWorkspaceRequest => 'DeleteCloudWorkspaceRequest',
      _i15.GetCloudWorkspaceDetailRequest => 'GetCloudWorkspaceDetailRequest',
      _i16.InviteWorkspaceMemberRequest => 'InviteWorkspaceMemberRequest',
      _i17.LeaveCloudWorkspaceRequest => 'LeaveCloudWorkspaceRequest',
      _i18.ListCloudWorkspaceInvitesRequest =>
        'ListCloudWorkspaceInvitesRequest',
      _i19.ListWorkspaceMembersRequest => 'ListWorkspaceMembersRequest',
      _i20.PendingWorkspaceInviteSummary => 'PendingWorkspaceInviteSummary',
      _i21.RemoveWorkspaceMemberRequest => 'RemoveWorkspaceMemberRequest',
      _i22.RenameCloudWorkspaceRequest => 'RenameCloudWorkspaceRequest',
      _i23.RenewWorkspaceInviteRequest => 'RenewWorkspaceInviteRequest',
      _i24.RevokeWorkspaceInviteRequest => 'RevokeWorkspaceInviteRequest',
      _i25.TransferCloudWorkspaceOwnershipRequest =>
        'TransferCloudWorkspaceOwnershipRequest',
      _i26.UpdateWorkspaceMemberRoleRequest =>
        'UpdateWorkspaceMemberRoleRequest',
      _i27.WorkspaceInvite => 'WorkspaceInvite',
      _i28.WorkspaceMember => 'WorkspaceMember',
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
      case _i2.AccountSummary():
        return 'AccountSummary';
      case _i3.AcceptWorkspaceInviteRequest():
        return 'AcceptWorkspaceInviteRequest';
      case _i4.CloudWorkspace():
        return 'CloudWorkspace';
      case _i5.CloudWorkspaceCapabilities():
        return 'CloudWorkspaceCapabilities';
      case _i6.CloudWorkspaceDetail():
        return 'CloudWorkspaceDetail';
      case _i7.CloudWorkspaceErrorCode():
        return 'CloudWorkspaceErrorCode';
      case _i8.CloudWorkspaceException():
        return 'CloudWorkspaceException';
      case _i9.CloudWorkspaceInviteSummary():
        return 'CloudWorkspaceInviteSummary';
      case _i10.CloudWorkspaceMemberSummary():
        return 'CloudWorkspaceMemberSummary';
      case _i11.CloudWorkspaceSummary():
        return 'CloudWorkspaceSummary';
      case _i12.CreateCloudWorkspaceRequest():
        return 'CreateCloudWorkspaceRequest';
      case _i13.DeclineWorkspaceInviteRequest():
        return 'DeclineWorkspaceInviteRequest';
      case _i14.DeleteCloudWorkspaceRequest():
        return 'DeleteCloudWorkspaceRequest';
      case _i15.GetCloudWorkspaceDetailRequest():
        return 'GetCloudWorkspaceDetailRequest';
      case _i16.InviteWorkspaceMemberRequest():
        return 'InviteWorkspaceMemberRequest';
      case _i17.LeaveCloudWorkspaceRequest():
        return 'LeaveCloudWorkspaceRequest';
      case _i18.ListCloudWorkspaceInvitesRequest():
        return 'ListCloudWorkspaceInvitesRequest';
      case _i19.ListWorkspaceMembersRequest():
        return 'ListWorkspaceMembersRequest';
      case _i20.PendingWorkspaceInviteSummary():
        return 'PendingWorkspaceInviteSummary';
      case _i21.RemoveWorkspaceMemberRequest():
        return 'RemoveWorkspaceMemberRequest';
      case _i22.RenameCloudWorkspaceRequest():
        return 'RenameCloudWorkspaceRequest';
      case _i23.RenewWorkspaceInviteRequest():
        return 'RenewWorkspaceInviteRequest';
      case _i24.RevokeWorkspaceInviteRequest():
        return 'RevokeWorkspaceInviteRequest';
      case _i25.TransferCloudWorkspaceOwnershipRequest():
        return 'TransferCloudWorkspaceOwnershipRequest';
      case _i26.UpdateWorkspaceMemberRoleRequest():
        return 'UpdateWorkspaceMemberRoleRequest';
      case _i27.WorkspaceInvite():
        return 'WorkspaceInvite';
      case _i28.WorkspaceMember():
        return 'WorkspaceMember';
    }
    className = _i33.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _i34.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
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
      return deserialize<_i2.AccountSummary>(data['data']);
    }
    if (dataClassName == 'AcceptWorkspaceInviteRequest') {
      return deserialize<_i3.AcceptWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'CloudWorkspace') {
      return deserialize<_i4.CloudWorkspace>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceCapabilities') {
      return deserialize<_i5.CloudWorkspaceCapabilities>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceDetail') {
      return deserialize<_i6.CloudWorkspaceDetail>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceErrorCode') {
      return deserialize<_i7.CloudWorkspaceErrorCode>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceException') {
      return deserialize<_i8.CloudWorkspaceException>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceInviteSummary') {
      return deserialize<_i9.CloudWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceMemberSummary') {
      return deserialize<_i10.CloudWorkspaceMemberSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceSummary') {
      return deserialize<_i11.CloudWorkspaceSummary>(data['data']);
    }
    if (dataClassName == 'CreateCloudWorkspaceRequest') {
      return deserialize<_i12.CreateCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'DeclineWorkspaceInviteRequest') {
      return deserialize<_i13.DeclineWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'DeleteCloudWorkspaceRequest') {
      return deserialize<_i14.DeleteCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'GetCloudWorkspaceDetailRequest') {
      return deserialize<_i15.GetCloudWorkspaceDetailRequest>(data['data']);
    }
    if (dataClassName == 'InviteWorkspaceMemberRequest') {
      return deserialize<_i16.InviteWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'LeaveCloudWorkspaceRequest') {
      return deserialize<_i17.LeaveCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'ListCloudWorkspaceInvitesRequest') {
      return deserialize<_i18.ListCloudWorkspaceInvitesRequest>(data['data']);
    }
    if (dataClassName == 'ListWorkspaceMembersRequest') {
      return deserialize<_i19.ListWorkspaceMembersRequest>(data['data']);
    }
    if (dataClassName == 'PendingWorkspaceInviteSummary') {
      return deserialize<_i20.PendingWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'RemoveWorkspaceMemberRequest') {
      return deserialize<_i21.RemoveWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'RenameCloudWorkspaceRequest') {
      return deserialize<_i22.RenameCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'RenewWorkspaceInviteRequest') {
      return deserialize<_i23.RenewWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'RevokeWorkspaceInviteRequest') {
      return deserialize<_i24.RevokeWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'TransferCloudWorkspaceOwnershipRequest') {
      return deserialize<_i25.TransferCloudWorkspaceOwnershipRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'UpdateWorkspaceMemberRoleRequest') {
      return deserialize<_i26.UpdateWorkspaceMemberRoleRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceInvite') {
      return deserialize<_i27.WorkspaceInvite>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i28.WorkspaceMember>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i33.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i34.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _i33.Protocol().registerHostProtocol('auravibes', this);
    _i34.Protocol().registerHostProtocol('auravibes', this);
  }

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
      return _i33.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i34.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
