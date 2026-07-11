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
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/jwt_refresh_endpoint.dart' as _i3;
import '../features/accounts/account_endpoint.dart' as _i4;
import '../features/workspaces/cloud_workspace_endpoint.dart' as _i5;
import 'package:auravibes_server/src/generated/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i6;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_workspace_members_request.dart'
    as _i7;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i8;
import 'package:auravibes_server/src/generated/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i9;
import 'package:auravibes_server/src/generated/features/workspaces/models/invite_workspace_member_request.dart'
    as _i10;
import 'package:auravibes_server/src/generated/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i11;
import 'package:auravibes_server/src/generated/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i12;
import 'package:auravibes_server/src/generated/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i13;
import 'package:auravibes_server/src/generated/features/workspaces/models/decline_workspace_invite_request.dart'
    as _i14;
import 'package:auravibes_server/src/generated/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i15;
import 'package:auravibes_server/src/generated/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i16;
import 'package:auravibes_server/src/generated/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i17;
import 'package:auravibes_server/src/generated/features/workspaces/models/update_workspace_member_role_request.dart'
    as _i18;
import 'package:auravibes_server/src/generated/features/workspaces/models/remove_workspace_member_request.dart'
    as _i19;
import 'package:auravibes_server/src/generated/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i20;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i21;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i22;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _i3.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'account': _i4.AccountEndpoint()
        ..initialize(
          server,
          'account',
          null,
        ),
      'cloudWorkspace': _i5.CloudWorkspaceEndpoint()
        ..initialize(
          server,
          'cloudWorkspace',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i3.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['account'] = _i1.EndpointConnector(
      name: 'account',
      endpoint: endpoints['account']!,
      methodConnectors: {
        'currentUser': _i1.MethodConnector(
          name: 'currentUser',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _i4.AccountEndpoint)
                  .currentUser(session),
        ),
      },
    );
    connectors['cloudWorkspace'] = _i1.EndpointConnector(
      name: 'cloudWorkspace',
      endpoint: endpoints['cloudWorkspace']!,
      methodConnectors: {
        'listAuthorizedWorkspaces': _i1.MethodConnector(
          name: 'listAuthorizedWorkspaces',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .listAuthorizedWorkspaces(session),
        ),
        'listPendingInvites': _i1.MethodConnector(
          name: 'listPendingInvites',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .listPendingInvites(session),
        ),
        'getWorkspaceDetail': _i1.MethodConnector(
          name: 'getWorkspaceDetail',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i6.GetCloudWorkspaceDetailRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .getWorkspaceDetail(
                        session,
                        params['request'],
                      ),
        ),
        'listMembers': _i1.MethodConnector(
          name: 'listMembers',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i7.ListWorkspaceMembersRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .listMembers(
                        session,
                        params['request'],
                      ),
        ),
        'listWorkspaceInvites': _i1.MethodConnector(
          name: 'listWorkspaceInvites',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i8.ListCloudWorkspaceInvitesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .listWorkspaceInvites(
                        session,
                        params['request'],
                      ),
        ),
        'createWorkspace': _i1.MethodConnector(
          name: 'createWorkspace',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i9.CreateCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .createWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'inviteMember': _i1.MethodConnector(
          name: 'inviteMember',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i10.InviteWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .inviteMember(
                        session,
                        params['request'],
                      ),
        ),
        'renewInvite': _i1.MethodConnector(
          name: 'renewInvite',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i11.RenewWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .renewInvite(
                        session,
                        params['request'],
                      ),
        ),
        'revokeInvite': _i1.MethodConnector(
          name: 'revokeInvite',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i12.RevokeWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .revokeInvite(
                        session,
                        params['request'],
                      ),
        ),
        'acceptInvite': _i1.MethodConnector(
          name: 'acceptInvite',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.AcceptWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .acceptInvite(
                        session,
                        params['request'],
                      ),
        ),
        'declineInvite': _i1.MethodConnector(
          name: 'declineInvite',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.DeclineWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .declineInvite(
                        session,
                        params['request'],
                      ),
        ),
        'renameWorkspace': _i1.MethodConnector(
          name: 'renameWorkspace',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i15.RenameCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .renameWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'leaveWorkspace': _i1.MethodConnector(
          name: 'leaveWorkspace',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i16.LeaveCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .leaveWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'transferOwnership': _i1.MethodConnector(
          name: 'transferOwnership',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i17.TransferCloudWorkspaceOwnershipRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .transferOwnership(
                        session,
                        params['request'],
                      ),
        ),
        'updateMemberRole': _i1.MethodConnector(
          name: 'updateMemberRole',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i18.UpdateWorkspaceMemberRoleRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .updateMemberRole(
                        session,
                        params['request'],
                      ),
        ),
        'removeMember': _i1.MethodConnector(
          name: 'removeMember',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.RemoveWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .removeMember(
                        session,
                        params['request'],
                      ),
        ),
        'deleteWorkspace': _i1.MethodConnector(
          name: 'deleteWorkspace',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i20.DeleteCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i5.CloudWorkspaceEndpoint)
                      .deleteWorkspace(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i21.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i22.Endpoints()
      ..initializeEndpoints(server);
  }
}
