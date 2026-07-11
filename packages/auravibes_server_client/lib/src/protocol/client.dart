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
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:auravibes_server_client/src/protocol/features/accounts/models/account_summary.dart'
    as _i5;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_summary.dart'
    as _i6;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i7;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_detail.dart'
    as _i8;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i9;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i10;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_workspace_members_request.dart'
    as _i11;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i12;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i13;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i14;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/invite_workspace_member_request.dart'
    as _i15;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i16;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i17;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i18;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/decline_workspace_invite_request.dart'
    as _i19;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i20;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i21;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i22;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/update_workspace_member_role_request.dart'
    as _i23;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/remove_workspace_member_request.dart'
    as _i24;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i25;
import 'package:http/http.dart' as _i26;
import 'protocol.dart' as _i27;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointAccount extends _i2.EndpointRef {
  EndpointAccount(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  _i3.Future<_i5.AccountSummary> currentUser() =>
      caller.callServerEndpoint<_i5.AccountSummary>(
        'account',
        'currentUser',
        {},
      );
}

/// {@category Endpoint}
class EndpointCloudWorkspace extends _i2.EndpointRef {
  EndpointCloudWorkspace(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudWorkspace';

  _i3.Future<List<_i6.CloudWorkspaceSummary>> listAuthorizedWorkspaces() =>
      caller.callServerEndpoint<List<_i6.CloudWorkspaceSummary>>(
        'cloudWorkspace',
        'listAuthorizedWorkspaces',
        {},
      );

  _i3.Future<List<_i7.PendingWorkspaceInviteSummary>> listPendingInvites() =>
      caller.callServerEndpoint<List<_i7.PendingWorkspaceInviteSummary>>(
        'cloudWorkspace',
        'listPendingInvites',
        {},
      );

  _i3.Future<_i8.CloudWorkspaceDetail> getWorkspaceDetail(
    _i9.GetCloudWorkspaceDetailRequest request,
  ) => caller.callServerEndpoint<_i8.CloudWorkspaceDetail>(
    'cloudWorkspace',
    'getWorkspaceDetail',
    {'request': request},
  );

  _i3.Future<List<_i10.CloudWorkspaceMemberSummary>> listMembers(
    _i11.ListWorkspaceMembersRequest request,
  ) => caller.callServerEndpoint<List<_i10.CloudWorkspaceMemberSummary>>(
    'cloudWorkspace',
    'listMembers',
    {'request': request},
  );

  _i3.Future<List<_i12.CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    _i13.ListCloudWorkspaceInvitesRequest request,
  ) => caller.callServerEndpoint<List<_i12.CloudWorkspaceInviteSummary>>(
    'cloudWorkspace',
    'listWorkspaceInvites',
    {'request': request},
  );

  _i3.Future<_i6.CloudWorkspaceSummary> createWorkspace(
    _i14.CreateCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_i6.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'createWorkspace',
    {'request': request},
  );

  _i3.Future<_i7.PendingWorkspaceInviteSummary> inviteMember(
    _i15.InviteWorkspaceMemberRequest request,
  ) => caller.callServerEndpoint<_i7.PendingWorkspaceInviteSummary>(
    'cloudWorkspace',
    'inviteMember',
    {'request': request},
  );

  _i3.Future<_i12.CloudWorkspaceInviteSummary> renewInvite(
    _i16.RenewWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_i12.CloudWorkspaceInviteSummary>(
    'cloudWorkspace',
    'renewInvite',
    {'request': request},
  );

  _i3.Future<void> revokeInvite(_i17.RevokeWorkspaceInviteRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'revokeInvite',
        {'request': request},
      );

  _i3.Future<_i6.CloudWorkspaceSummary> acceptInvite(
    _i18.AcceptWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_i6.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'acceptInvite',
    {'request': request},
  );

  _i3.Future<void> declineInvite(_i19.DeclineWorkspaceInviteRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'declineInvite',
        {'request': request},
      );

  _i3.Future<_i6.CloudWorkspaceSummary> renameWorkspace(
    _i20.RenameCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_i6.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'renameWorkspace',
    {'request': request},
  );

  _i3.Future<void> leaveWorkspace(_i21.LeaveCloudWorkspaceRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'leaveWorkspace',
        {'request': request},
      );

  _i3.Future<void> transferOwnership(
    _i22.TransferCloudWorkspaceOwnershipRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'transferOwnership',
    {'request': request},
  );

  _i3.Future<void> updateMemberRole(
    _i23.UpdateWorkspaceMemberRoleRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'updateMemberRole',
    {'request': request},
  );

  _i3.Future<void> removeMember(_i24.RemoveWorkspaceMemberRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'removeMember',
        {'request': request},
      );

  _i3.Future<void> deleteWorkspace(_i25.DeleteCloudWorkspaceRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'deleteWorkspace',
        {'request': request},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i26.Client? httpClientOverride,
  }) : super(
         host,
         _i27.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    account = EndpointAccount(this);
    cloudWorkspace = EndpointCloudWorkspace(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAccount account;

  late final EndpointCloudWorkspace cloudWorkspace;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'account': account,
    'cloudWorkspace': cloudWorkspace,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
