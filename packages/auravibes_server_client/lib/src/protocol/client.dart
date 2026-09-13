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
import 'dart:async' as _ida;

import 'package:auravibes_server_client/src/protocol/features/accounts/models/account_summary.dart'
    as _i5884lvh;
import 'package:auravibes_server_client/src/protocol/features/agents/models/agent_catalog_page.dart'
    as _i7fng6wf;
import 'package:auravibes_server_client/src/protocol/features/agents/models/get_agent_resources_request.dart'
    as _ilf9sz6u;
import 'package:auravibes_server_client/src/protocol/features/agents/models/list_agents_request.dart'
    as _ix3w0365;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/complete_codex_oauth_request.dart'
    as _irjpqi75;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/complete_codex_oauth_result.dart'
    as _iynqi7ry;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/start_codex_oauth_request.dart'
    as _ijrb3tyt;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/start_codex_oauth_result.dart'
    as _i614hct4;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/cancel_turn_request.dart'
    as _icy1uco6;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/compact_conversation_request.dart'
    as _ix997bpm;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/continue_conversation_request.dart'
    as _iikp15t9;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/continue_turn_request.dart'
    as _ivlxpbcf;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_message_view.dart'
    as _isubclmd;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_mutation_result.dart'
    as _iyn6xv3g;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_page.dart'
    as _igpxqyyq;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_snapshot.dart'
    as _i0ao9hou;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_stream_event.dart'
    as _itqk7c7m;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_subscribe_request.dart'
    as _imiup13v;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_summary.dart'
    as _i54dvwkh;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/create_conversation_request.dart'
    as _ij3epthu;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/delete_conversation_request.dart'
    as _ik9usty6;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/edit_pending_conversation_message_request.dart'
    as _i4hkj4ob;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/get_conversation_request.dart'
    as _i3j9438n;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/get_turn_request.dart'
    as _inh22t6z;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/list_conversation_messages_request.dart'
    as _ikmnkbtb;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/list_conversations_request.dart'
    as _it3m8kdz;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/queue_conversation_message_request.dart'
    as _iia9quot;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/remove_pending_conversation_message_request.dart'
    as _i2sc9nxe;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/reorder_pending_conversation_message_request.dart'
    as _i28kt77m;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/start_turn_request.dart'
    as _iewqezs8;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/start_turn_result.dart'
    as _iwmr2a61;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/stop_conversation_request.dart'
    as _ijtzjq4c;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/submit_tool_decision_request.dart'
    as _iqbrsea4;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/turn_snapshot.dart'
    as _i2p4k8hs;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/update_conversation_request.dart'
    as _irx2op5d;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/update_conversation_settings_request.dart'
    as _ia7au4nd;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/create_mcp_server_request.dart'
    as _iqrnkkwp;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/create_mcp_server_result.dart'
    as _i3f0a4jf;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/delete_mcp_server_request.dart'
    as _iaph0vb0;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/discover_mcp_server_request.dart'
    as _ie29eho8;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/discover_mcp_server_result.dart'
    as _iar1xj2j;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model.dart'
    as _iuloe217;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model_provider.dart'
    as _ipos6eci;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/create_model_connection_request.dart'
    as _ic02wlnp;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/delete_model_connection_request.dart'
    as _im3xu94m;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/list_model_connections_request.dart'
    as _if6l4bkm;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/list_workspace_model_selections_request.dart'
    as _ibbwb4vv;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/model_connection_view.dart'
    as _i5hnstsl;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/model_sync_result.dart'
    as _idbs8oqc;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _i5neyvt3;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/update_model_connection_request.dart'
    as _ip0z8mdx;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/workspace_model_selection_view.dart'
    as _i9qkc4pk;
import 'package:auravibes_server_client/src/protocol/features/objects/models/begin_upload_request.dart'
    as _ibypbne4;
import 'package:auravibes_server_client/src/protocol/features/objects/models/begin_upload_result.dart'
    as _irr65imu;
import 'package:auravibes_server_client/src/protocol/features/objects/models/complete_upload_request.dart'
    as _igedz0kd;
import 'package:auravibes_server_client/src/protocol/features/objects/models/delete_object_request.dart'
    as _i65avykf;
import 'package:auravibes_server_client/src/protocol/features/objects/models/get_download_request.dart'
    as _ijxvxgh5;
import 'package:auravibes_server_client/src/protocol/features/objects/models/get_download_result.dart'
    as _ixm7fyok;
import 'package:auravibes_server_client/src/protocol/features/objects/models/object_result.dart'
    as _iw6nkrbk;
import 'package:auravibes_server_client/src/protocol/features/sync/stream/models/workspace_stream_envelope.dart'
    as _ifwc6wsw;
import 'package:auravibes_server_client/src/protocol/features/sync/stream/models/workspace_subscribe_request.dart'
    as _ihte0iyb;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _i2aip5sd;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/mutate_workspace_credential_response.dart'
    as _i6eu5eia;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/patch_workspace_state_request.dart'
    as _i4jm10bd;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/patch_workspace_state_response.dart'
    as _inzhu3sh;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/put_workspace_secret_request.dart'
    as _itmt72kp;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/put_workspace_secret_response.dart'
    as _itpf1yx8;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/read_workspace_state_request.dart'
    as _i7oqzoiv;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/read_workspace_state_response.dart'
    as _i3s0ysat;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/workspace_resource.dart'
    as _iar0fwau;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i0tihsii;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_detail.dart'
    as _i91wh5vy;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _iin9r2cd;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i8ggzj4z;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_summary.dart'
    as _ib73r5sl;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/create_cloud_workspace_request.dart'
    as _iki8or32;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/decline_workspace_invite_request.dart'
    as _iieqdqzc;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _ied6jb7p;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _ic69zisf;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/invite_workspace_member_request.dart'
    as _i9cbq6bg;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i84g5apv;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _iikpogvi;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_workspace_members_request.dart'
    as _iae6pyx0;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _ieuc8ihm;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/remove_workspace_member_request.dart'
    as _iyrw5hwx;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _idlpsnny;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i6br37rg;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _ic8yezfe;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _irp4u0sh;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/update_workspace_member_role_request.dart'
    as _iyq4n2w8;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

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
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
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
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
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
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
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
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
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
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
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
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
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
  _ida.Future<void> finishPasswordReset({
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
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
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
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// {@category Endpoint}
class EndpointAccount extends _isc.EndpointRef {
  EndpointAccount(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  _ida.Future<_i5884lvh.AccountSummary> currentUser() =>
      caller.callServerEndpoint<_i5884lvh.AccountSummary>(
        'account',
        'currentUser',
        {},
      );
}

/// {@category Endpoint}
class EndpointAgentCatalog extends _isc.EndpointRef {
  EndpointAgentCatalog(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agentCatalog';

  _ida.Future<_i7fng6wf.AgentCatalogPage> list(
    _ix3w0365.ListAgentsRequest request,
  ) => caller.callServerEndpoint<_i7fng6wf.AgentCatalogPage>(
    'agentCatalog',
    'list',
    {'request': request},
  );

  _ida.Future<List<_iar0fwau.WorkspaceResource>> getResources(
    _ilf9sz6u.GetAgentResourcesRequest request,
  ) => caller.callServerEndpoint<List<_iar0fwau.WorkspaceResource>>(
    'agentCatalog',
    'getResources',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointCodexOAuth extends _isc.EndpointRef {
  EndpointCodexOAuth(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'codexOAuth';

  _ida.Future<_i614hct4.StartCodexOAuthResult> start(
    _ijrb3tyt.StartCodexOAuthRequest request,
  ) => caller.callServerEndpoint<_i614hct4.StartCodexOAuthResult>(
    'codexOAuth',
    'start',
    {'request': request},
  );

  _ida.Future<_iynqi7ry.CompleteCodexOAuthResult> complete(
    _irjpqi75.CompleteCodexOAuthRequest request,
  ) => caller.callServerEndpoint<_iynqi7ry.CompleteCodexOAuthResult>(
    'codexOAuth',
    'complete',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointConversation extends _isc.EndpointRef {
  EndpointConversation(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'conversation';

  _ida.Future<_i54dvwkh.ConversationSummary> create(
    _ij3epthu.CreateConversationRequest request,
  ) => caller.callServerEndpoint<_i54dvwkh.ConversationSummary>(
    'conversation',
    'create',
    {'request': request},
  );

  _ida.Future<List<_i54dvwkh.ConversationSummary>> list(
    _it3m8kdz.ListConversationsRequest request,
  ) => caller.callServerEndpoint<List<_i54dvwkh.ConversationSummary>>(
    'conversation',
    'list',
    {'request': request},
  );

  _ida.Future<_igpxqyyq.ConversationPage> listPage(
    _it3m8kdz.ListConversationsRequest request,
  ) => caller.callServerEndpoint<_igpxqyyq.ConversationPage>(
    'conversation',
    'listPage',
    {'request': request},
  );

  _ida.Future<_i54dvwkh.ConversationSummary> get(
    _i3j9438n.GetConversationRequest request,
  ) => caller.callServerEndpoint<_i54dvwkh.ConversationSummary>(
    'conversation',
    'get',
    {'request': request},
  );

  _ida.Future<List<_isubclmd.ConversationMessageView>> listMessages(
    _ikmnkbtb.ListConversationMessagesRequest request,
  ) => caller.callServerEndpoint<List<_isubclmd.ConversationMessageView>>(
    'conversation',
    'listMessages',
    {'request': request},
  );

  _ida.Future<_i54dvwkh.ConversationSummary> update(
    _irx2op5d.UpdateConversationRequest request,
  ) => caller.callServerEndpoint<_i54dvwkh.ConversationSummary>(
    'conversation',
    'update',
    {'request': request},
  );

  _ida.Future<void> delete(_ik9usty6.DeleteConversationRequest request) =>
      caller.callServerEndpoint<void>(
        'conversation',
        'delete',
        {'request': request},
      );

  _ida.Future<_iwmr2a61.StartTurnResult> startTurn(
    _iewqezs8.StartTurnRequest request,
  ) => caller.callServerEndpoint<_iwmr2a61.StartTurnResult>(
    'conversation',
    'startTurn',
    {'request': request},
  );

  _ida.Future<_iyn6xv3g.ConversationMutationResult> continueTurn(
    _ivlxpbcf.ContinueTurnRequest request,
  ) => caller.callServerEndpoint<_iyn6xv3g.ConversationMutationResult>(
    'conversation',
    'continueTurn',
    {'request': request},
  );

  _ida.Future<_i2p4k8hs.TurnSnapshot> getTurn(
    _inh22t6z.GetTurnRequest request,
  ) => caller.callServerEndpoint<_i2p4k8hs.TurnSnapshot>(
    'conversation',
    'getTurn',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> getConversationSnapshot(
    _i3j9438n.GetConversationRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'getConversationSnapshot',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> queueConversationMessage(
    _iia9quot.QueueConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'queueConversationMessage',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> continueConversation(
    _iikp15t9.ContinueConversationRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'continueConversation',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> stopConversation(
    _ijtzjq4c.StopConversationRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'stopConversation',
    {'request': request},
  );

  _ida.Stream<_itqk7c7m.ConversationStreamEvent> subscribeConversation(
    _imiup13v.ConversationSubscribeRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_itqk7c7m.ConversationStreamEvent>,
        _itqk7c7m.ConversationStreamEvent
      >(
        'conversation',
        'subscribeConversation',
        {'request': request},
        {},
      );

  _ida.Future<_i0ao9hou.ConversationSnapshot> editPendingConversationMessage(
    _i4hkj4ob.EditPendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'editPendingConversationMessage',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> reorderPendingConversationMessage(
    _i28kt77m.ReorderPendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'reorderPendingConversationMessage',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> removePendingConversationMessage(
    _i2sc9nxe.RemovePendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'removePendingConversationMessage',
    {'request': request},
  );

  _ida.Future<_i0ao9hou.ConversationSnapshot> updateConversationSettings(
    _ia7au4nd.UpdateConversationSettingsRequest request,
  ) => caller.callServerEndpoint<_i0ao9hou.ConversationSnapshot>(
    'conversation',
    'updateConversationSettings',
    {'request': request},
  );

  _ida.Future<_iyn6xv3g.ConversationMutationResult> submitToolDecision(
    _iqbrsea4.SubmitToolDecisionRequest request,
  ) => caller.callServerEndpoint<_iyn6xv3g.ConversationMutationResult>(
    'conversation',
    'submitToolDecision',
    {'request': request},
  );

  _ida.Future<_iyn6xv3g.ConversationMutationResult> cancelTurn(
    _icy1uco6.CancelTurnRequest request,
  ) => caller.callServerEndpoint<_iyn6xv3g.ConversationMutationResult>(
    'conversation',
    'cancelTurn',
    {'request': request},
  );

  _ida.Future<_iyn6xv3g.ConversationMutationResult> compact(
    _ix997bpm.CompactConversationRequest request,
  ) => caller.callServerEndpoint<_iyn6xv3g.ConversationMutationResult>(
    'conversation',
    'compact',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointMcpServer extends _isc.EndpointRef {
  EndpointMcpServer(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mcpServer';

  _ida.Future<_i3f0a4jf.CreateMcpServerResult> create(
    _iqrnkkwp.CreateMcpServerRequest request,
  ) => caller.callServerEndpoint<_i3f0a4jf.CreateMcpServerResult>(
    'mcpServer',
    'create',
    {'request': request},
  );

  _ida.Future<void> delete(_iaph0vb0.DeleteMcpServerRequest request) =>
      caller.callServerEndpoint<void>(
        'mcpServer',
        'delete',
        {'request': request},
      );

  _ida.Future<_iar1xj2j.DiscoverMcpServerResult> discoverAndCheck(
    _ie29eho8.DiscoverMcpServerRequest request,
  ) => caller.callServerEndpoint<_iar1xj2j.DiscoverMcpServerResult>(
    'mcpServer',
    'discoverAndCheck',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointModelConnection extends _isc.EndpointRef {
  EndpointModelConnection(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'modelConnection';

  _ida.Future<List<_ipos6eci.ApiModelProvider>> listCatalogProviders() =>
      caller.callServerEndpoint<List<_ipos6eci.ApiModelProvider>>(
        'modelConnection',
        'listCatalogProviders',
        {},
      );

  _ida.Future<List<_iuloe217.ApiModel>> listCatalogModels({
    String? providerId,
  }) => caller.callServerEndpoint<List<_iuloe217.ApiModel>>(
    'modelConnection',
    'listCatalogModels',
    {'providerId': providerId},
  );

  _ida.Future<_i5hnstsl.ModelConnectionView> create(
    _ic02wlnp.CreateModelConnectionRequest request,
  ) => caller.callServerEndpoint<_i5hnstsl.ModelConnectionView>(
    'modelConnection',
    'create',
    {'request': request},
  );

  _ida.Future<List<_i5hnstsl.ModelConnectionView>> list(
    _if6l4bkm.ListModelConnectionsRequest request,
  ) => caller.callServerEndpoint<List<_i5hnstsl.ModelConnectionView>>(
    'modelConnection',
    'list',
    {'request': request},
  );

  _ida.Future<_i5hnstsl.ModelConnectionView> update(
    _ip0z8mdx.UpdateModelConnectionRequest request,
  ) => caller.callServerEndpoint<_i5hnstsl.ModelConnectionView>(
    'modelConnection',
    'update',
    {'request': request},
  );

  _ida.Future<void> delete(_im3xu94m.DeleteModelConnectionRequest request) =>
      caller.callServerEndpoint<void>(
        'modelConnection',
        'delete',
        {'request': request},
      );

  _ida.Future<List<_i9qkc4pk.WorkspaceModelSelectionView>> listSelections(
    _ibbwb4vv.ListWorkspaceModelSelectionsRequest request,
  ) => caller.callServerEndpoint<List<_i9qkc4pk.WorkspaceModelSelectionView>>(
    'modelConnection',
    'listSelections',
    {'request': request},
  );

  _ida.Future<_idbs8oqc.ModelSyncResult> testAndSync(
    _i5neyvt3.TestAndSyncModelConnectionRequest request,
  ) => caller.callServerEndpoint<_idbs8oqc.ModelSyncResult>(
    'modelConnection',
    'testAndSync',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointObject extends _isc.EndpointRef {
  EndpointObject(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'object';

  _ida.Future<_irr65imu.BeginUploadResult> beginUpload(
    _ibypbne4.BeginUploadRequest request,
  ) => caller.callServerEndpoint<_irr65imu.BeginUploadResult>(
    'object',
    'beginUpload',
    {'request': request},
  );

  _ida.Future<_iw6nkrbk.ObjectResult> completeUpload(
    _igedz0kd.CompleteUploadRequest request,
  ) => caller.callServerEndpoint<_iw6nkrbk.ObjectResult>(
    'object',
    'completeUpload',
    {'request': request},
  );

  _ida.Future<_ixm7fyok.GetDownloadResult> getDownload(
    _ijxvxgh5.GetDownloadRequest request,
  ) => caller.callServerEndpoint<_ixm7fyok.GetDownloadResult>(
    'object',
    'getDownload',
    {'request': request},
  );

  _ida.Future<void> delete(_i65avykf.DeleteObjectRequest request) =>
      caller.callServerEndpoint<void>(
        'object',
        'delete',
        {'request': request},
      );
}

/// {@category Endpoint}
class EndpointWorkspaceStream extends _isc.EndpointRef {
  EndpointWorkspaceStream(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceStream';

  _ida.Stream<_ifwc6wsw.WorkspaceStreamEnvelope> subscribe(
    _ihte0iyb.WorkspaceSubscribeRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ifwc6wsw.WorkspaceStreamEnvelope>,
        _ifwc6wsw.WorkspaceStreamEnvelope
      >(
        'workspaceStream',
        'subscribe',
        {'request': request},
        {},
      );
}

/// {@category Endpoint}
class EndpointWorkspaceSecret extends _isc.EndpointRef {
  EndpointWorkspaceSecret(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceSecret';

  _ida.Future<_itpf1yx8.PutWorkspaceSecretResponse> put(
    _itmt72kp.PutWorkspaceSecretRequest request,
  ) => caller.callServerEndpoint<_itpf1yx8.PutWorkspaceSecretResponse>(
    'workspaceSecret',
    'put',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointWorkspaceState extends _isc.EndpointRef {
  EndpointWorkspaceState(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceState';

  _ida.Future<_i3s0ysat.ReadWorkspaceStateResponse> read(
    _i7oqzoiv.ReadWorkspaceStateRequest request,
  ) => caller.callServerEndpoint<_i3s0ysat.ReadWorkspaceStateResponse>(
    'workspaceState',
    'read',
    {'request': request},
  );

  _ida.Future<_inzhu3sh.PatchWorkspaceStateResponse> patch(
    _i4jm10bd.PatchWorkspaceStateRequest request,
  ) => caller.callServerEndpoint<_inzhu3sh.PatchWorkspaceStateResponse>(
    'workspaceState',
    'patch',
    {'request': request},
  );

  _ida.Future<_i6eu5eia.MutateWorkspaceCredentialResponse> mutateCredential(
    _i2aip5sd.MutateWorkspaceCredentialRequest request,
  ) => caller.callServerEndpoint<_i6eu5eia.MutateWorkspaceCredentialResponse>(
    'workspaceState',
    'mutateCredential',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointCloudWorkspace extends _isc.EndpointRef {
  EndpointCloudWorkspace(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudWorkspace';

  _ida.Future<List<_ib73r5sl.CloudWorkspaceSummary>>
  listAuthorizedWorkspaces() =>
      caller.callServerEndpoint<List<_ib73r5sl.CloudWorkspaceSummary>>(
        'cloudWorkspace',
        'listAuthorizedWorkspaces',
        {},
      );

  _ida.Future<List<_ieuc8ihm.PendingWorkspaceInviteSummary>>
  listPendingInvites() =>
      caller.callServerEndpoint<List<_ieuc8ihm.PendingWorkspaceInviteSummary>>(
        'cloudWorkspace',
        'listPendingInvites',
        {},
      );

  _ida.Future<_i91wh5vy.CloudWorkspaceDetail> getWorkspaceDetail(
    _ic69zisf.GetCloudWorkspaceDetailRequest request,
  ) => caller.callServerEndpoint<_i91wh5vy.CloudWorkspaceDetail>(
    'cloudWorkspace',
    'getWorkspaceDetail',
    {'request': request},
  );

  _ida.Future<List<_i8ggzj4z.CloudWorkspaceMemberSummary>> listMembers(
    _iae6pyx0.ListWorkspaceMembersRequest request,
  ) => caller.callServerEndpoint<List<_i8ggzj4z.CloudWorkspaceMemberSummary>>(
    'cloudWorkspace',
    'listMembers',
    {'request': request},
  );

  _ida.Future<List<_iin9r2cd.CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    _iikpogvi.ListCloudWorkspaceInvitesRequest request,
  ) => caller.callServerEndpoint<List<_iin9r2cd.CloudWorkspaceInviteSummary>>(
    'cloudWorkspace',
    'listWorkspaceInvites',
    {'request': request},
  );

  _ida.Future<_ib73r5sl.CloudWorkspaceSummary> createWorkspace(
    _iki8or32.CreateCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_ib73r5sl.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'createWorkspace',
    {'request': request},
  );

  _ida.Future<_ieuc8ihm.PendingWorkspaceInviteSummary> inviteMember(
    _i9cbq6bg.InviteWorkspaceMemberRequest request,
  ) => caller.callServerEndpoint<_ieuc8ihm.PendingWorkspaceInviteSummary>(
    'cloudWorkspace',
    'inviteMember',
    {'request': request},
  );

  _ida.Future<_iin9r2cd.CloudWorkspaceInviteSummary> renewInvite(
    _i6br37rg.RenewWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_iin9r2cd.CloudWorkspaceInviteSummary>(
    'cloudWorkspace',
    'renewInvite',
    {'request': request},
  );

  _ida.Future<void> revokeInvite(
    _ic8yezfe.RevokeWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'revokeInvite',
    {'request': request},
  );

  _ida.Future<_ib73r5sl.CloudWorkspaceSummary> acceptInvite(
    _i0tihsii.AcceptWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_ib73r5sl.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'acceptInvite',
    {'request': request},
  );

  _ida.Future<void> declineInvite(
    _iieqdqzc.DeclineWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'declineInvite',
    {'request': request},
  );

  _ida.Future<_ib73r5sl.CloudWorkspaceSummary> renameWorkspace(
    _idlpsnny.RenameCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_ib73r5sl.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'renameWorkspace',
    {'request': request},
  );

  _ida.Future<void> leaveWorkspace(
    _i84g5apv.LeaveCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'leaveWorkspace',
    {'request': request},
  );

  _ida.Future<void> transferOwnership(
    _irp4u0sh.TransferCloudWorkspaceOwnershipRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'transferOwnership',
    {'request': request},
  );

  _ida.Future<void> updateMemberRole(
    _iyq4n2w8.UpdateWorkspaceMemberRoleRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'updateMemberRole',
    {'request': request},
  );

  _ida.Future<void> removeMember(
    _iyrw5hwx.RemoveWorkspaceMemberRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'removeMember',
    {'request': request},
  );

  _ida.Future<void> deleteWorkspace(
    _ied6jb7p.DeleteCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'deleteWorkspace',
    {'request': request},
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_core = _iacc.Caller(client);
    serverpod_auth_idp = _iaic.Caller(client);
  }

  late final _iacc.Caller serverpod_auth_core;

  late final _iaic.Caller serverpod_auth_idp;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
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
    agentCatalog = EndpointAgentCatalog(this);
    codexOAuth = EndpointCodexOAuth(this);
    conversation = EndpointConversation(this);
    mcpServer = EndpointMcpServer(this);
    modelConnection = EndpointModelConnection(this);
    object = EndpointObject(this);
    workspaceStream = EndpointWorkspaceStream(this);
    workspaceSecret = EndpointWorkspaceSecret(this);
    workspaceState = EndpointWorkspaceState(this);
    cloudWorkspace = EndpointCloudWorkspace(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAccount account;

  late final EndpointAgentCatalog agentCatalog;

  late final EndpointCodexOAuth codexOAuth;

  late final EndpointConversation conversation;

  late final EndpointMcpServer mcpServer;

  late final EndpointModelConnection modelConnection;

  late final EndpointObject object;

  late final EndpointWorkspaceStream workspaceStream;

  late final EndpointWorkspaceSecret workspaceSecret;

  late final EndpointWorkspaceState workspaceState;

  late final EndpointCloudWorkspace cloudWorkspace;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'account': account,
    'agentCatalog': agentCatalog,
    'codexOAuth': codexOAuth,
    'conversation': conversation,
    'mcpServer': mcpServer,
    'modelConnection': modelConnection,
    'object': object,
    'workspaceStream': workspaceStream,
    'workspaceSecret': workspaceSecret,
    'workspaceState': workspaceState,
    'cloudWorkspace': cloudWorkspace,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_core': modules.serverpod_auth_core,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
