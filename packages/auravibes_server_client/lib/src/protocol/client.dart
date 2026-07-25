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
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/start_codex_oauth_result.dart'
    as _i6;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/start_codex_oauth_request.dart'
    as _i7;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/complete_codex_oauth_result.dart'
    as _i8;
import 'package:auravibes_server_client/src/protocol/features/codex_oauth/models/complete_codex_oauth_request.dart'
    as _i9;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_summary.dart'
    as _i10;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/create_conversation_request.dart'
    as _i11;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/list_conversations_request.dart'
    as _i12;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_page.dart'
    as _i13;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/get_conversation_request.dart'
    as _i14;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_message_view.dart'
    as _i15;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/list_conversation_messages_request.dart'
    as _i16;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/update_conversation_request.dart'
    as _i17;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/delete_conversation_request.dart'
    as _i18;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/start_turn_result.dart'
    as _i19;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/start_turn_request.dart'
    as _i20;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_mutation_result.dart'
    as _i21;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/continue_turn_request.dart'
    as _i22;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/turn_snapshot.dart'
    as _i23;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/get_turn_request.dart'
    as _i24;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_snapshot.dart'
    as _i25;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/queue_conversation_message_request.dart'
    as _i26;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/continue_conversation_request.dart'
    as _i27;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/stop_conversation_request.dart'
    as _i28;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_stream_event.dart'
    as _i29;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_subscribe_request.dart'
    as _i30;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/edit_pending_conversation_message_request.dart'
    as _i31;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/reorder_pending_conversation_message_request.dart'
    as _i32;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/remove_pending_conversation_message_request.dart'
    as _i33;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/update_conversation_settings_request.dart'
    as _i34;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/submit_tool_decision_request.dart'
    as _i35;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/cancel_turn_request.dart'
    as _i36;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/compact_conversation_request.dart'
    as _i37;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/create_mcp_server_result.dart'
    as _i38;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/create_mcp_server_request.dart'
    as _i39;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/delete_mcp_server_request.dart'
    as _i40;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/discover_mcp_server_result.dart'
    as _i41;
import 'package:auravibes_server_client/src/protocol/features/mcp_servers/models/discover_mcp_server_request.dart'
    as _i42;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model_provider.dart'
    as _i43;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model.dart'
    as _i44;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/model_connection_view.dart'
    as _i45;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/create_model_connection_request.dart'
    as _i46;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/list_model_connections_request.dart'
    as _i47;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/update_model_connection_request.dart'
    as _i48;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/delete_model_connection_request.dart'
    as _i49;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/workspace_model_selection_view.dart'
    as _i50;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/list_workspace_model_selections_request.dart'
    as _i51;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/model_sync_result.dart'
    as _i52;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _i53;
import 'package:auravibes_server_client/src/protocol/features/objects/models/begin_upload_result.dart'
    as _i54;
import 'package:auravibes_server_client/src/protocol/features/objects/models/begin_upload_request.dart'
    as _i55;
import 'package:auravibes_server_client/src/protocol/features/objects/models/object_result.dart'
    as _i56;
import 'package:auravibes_server_client/src/protocol/features/objects/models/complete_upload_request.dart'
    as _i57;
import 'package:auravibes_server_client/src/protocol/features/objects/models/get_download_result.dart'
    as _i58;
import 'package:auravibes_server_client/src/protocol/features/objects/models/get_download_request.dart'
    as _i59;
import 'package:auravibes_server_client/src/protocol/features/objects/models/delete_object_request.dart'
    as _i60;
import 'package:auravibes_server_client/src/protocol/features/sync/stream/models/workspace_stream_envelope.dart'
    as _i61;
import 'package:auravibes_server_client/src/protocol/features/sync/stream/models/workspace_subscribe_request.dart'
    as _i62;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/put_workspace_secret_response.dart'
    as _i63;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/put_workspace_secret_request.dart'
    as _i64;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/read_workspace_state_response.dart'
    as _i65;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/read_workspace_state_request.dart'
    as _i66;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/patch_workspace_state_response.dart'
    as _i67;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/patch_workspace_state_request.dart'
    as _i68;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/mutate_workspace_credential_response.dart'
    as _i69;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _i70;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_summary.dart'
    as _i71;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i72;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_detail.dart'
    as _i73;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i74;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i75;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_workspace_members_request.dart'
    as _i76;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i77;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i78;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i79;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/invite_workspace_member_request.dart'
    as _i80;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i81;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i82;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i83;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/decline_workspace_invite_request.dart'
    as _i84;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i85;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i86;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i87;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/update_workspace_member_role_request.dart'
    as _i88;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/remove_workspace_member_request.dart'
    as _i89;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i90;
import 'package:http/http.dart' as _i91;
import 'protocol.dart' as _i92;

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
class EndpointCodexOAuth extends _i2.EndpointRef {
  EndpointCodexOAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'codexOAuth';

  _i3.Future<_i6.StartCodexOAuthResult> start(
    _i7.StartCodexOAuthRequest request,
  ) => caller.callServerEndpoint<_i6.StartCodexOAuthResult>(
    'codexOAuth',
    'start',
    {'request': request},
  );

  _i3.Future<_i8.CompleteCodexOAuthResult> complete(
    _i9.CompleteCodexOAuthRequest request,
  ) => caller.callServerEndpoint<_i8.CompleteCodexOAuthResult>(
    'codexOAuth',
    'complete',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointConversation extends _i2.EndpointRef {
  EndpointConversation(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'conversation';

  _i3.Future<_i10.ConversationSummary> create(
    _i11.CreateConversationRequest request,
  ) => caller.callServerEndpoint<_i10.ConversationSummary>(
    'conversation',
    'create',
    {'request': request},
  );

  _i3.Future<List<_i10.ConversationSummary>> list(
    _i12.ListConversationsRequest request,
  ) => caller.callServerEndpoint<List<_i10.ConversationSummary>>(
    'conversation',
    'list',
    {'request': request},
  );

  _i3.Future<_i13.ConversationPage> listPage(
    _i12.ListConversationsRequest request,
  ) => caller.callServerEndpoint<_i13.ConversationPage>(
    'conversation',
    'listPage',
    {'request': request},
  );

  _i3.Future<_i10.ConversationSummary> get(
    _i14.GetConversationRequest request,
  ) => caller.callServerEndpoint<_i10.ConversationSummary>(
    'conversation',
    'get',
    {'request': request},
  );

  _i3.Future<List<_i15.ConversationMessageView>> listMessages(
    _i16.ListConversationMessagesRequest request,
  ) => caller.callServerEndpoint<List<_i15.ConversationMessageView>>(
    'conversation',
    'listMessages',
    {'request': request},
  );

  _i3.Future<_i10.ConversationSummary> update(
    _i17.UpdateConversationRequest request,
  ) => caller.callServerEndpoint<_i10.ConversationSummary>(
    'conversation',
    'update',
    {'request': request},
  );

  _i3.Future<void> delete(_i18.DeleteConversationRequest request) =>
      caller.callServerEndpoint<void>(
        'conversation',
        'delete',
        {'request': request},
      );

  _i3.Future<_i19.StartTurnResult> startTurn(_i20.StartTurnRequest request) =>
      caller.callServerEndpoint<_i19.StartTurnResult>(
        'conversation',
        'startTurn',
        {'request': request},
      );

  _i3.Future<_i21.ConversationMutationResult> continueTurn(
    _i22.ContinueTurnRequest request,
  ) => caller.callServerEndpoint<_i21.ConversationMutationResult>(
    'conversation',
    'continueTurn',
    {'request': request},
  );

  _i3.Future<_i23.TurnSnapshot> getTurn(_i24.GetTurnRequest request) =>
      caller.callServerEndpoint<_i23.TurnSnapshot>(
        'conversation',
        'getTurn',
        {'request': request},
      );

  _i3.Future<_i25.ConversationSnapshot> getConversationSnapshot(
    _i14.GetConversationRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'getConversationSnapshot',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> queueConversationMessage(
    _i26.QueueConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'queueConversationMessage',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> continueConversation(
    _i27.ContinueConversationRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'continueConversation',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> stopConversation(
    _i28.StopConversationRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'stopConversation',
    {'request': request},
  );

  _i3.Stream<_i29.ConversationStreamEvent> subscribeConversation(
    _i30.ConversationSubscribeRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i29.ConversationStreamEvent>,
        _i29.ConversationStreamEvent
      >(
        'conversation',
        'subscribeConversation',
        {'request': request},
        {},
      );

  _i3.Future<_i25.ConversationSnapshot> editPendingConversationMessage(
    _i31.EditPendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'editPendingConversationMessage',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> reorderPendingConversationMessage(
    _i32.ReorderPendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'reorderPendingConversationMessage',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> removePendingConversationMessage(
    _i33.RemovePendingConversationMessageRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'removePendingConversationMessage',
    {'request': request},
  );

  _i3.Future<_i25.ConversationSnapshot> updateConversationSettings(
    _i34.UpdateConversationSettingsRequest request,
  ) => caller.callServerEndpoint<_i25.ConversationSnapshot>(
    'conversation',
    'updateConversationSettings',
    {'request': request},
  );

  _i3.Future<_i21.ConversationMutationResult> submitToolDecision(
    _i35.SubmitToolDecisionRequest request,
  ) => caller.callServerEndpoint<_i21.ConversationMutationResult>(
    'conversation',
    'submitToolDecision',
    {'request': request},
  );

  _i3.Future<_i21.ConversationMutationResult> cancelTurn(
    _i36.CancelTurnRequest request,
  ) => caller.callServerEndpoint<_i21.ConversationMutationResult>(
    'conversation',
    'cancelTurn',
    {'request': request},
  );

  _i3.Future<_i21.ConversationMutationResult> compact(
    _i37.CompactConversationRequest request,
  ) => caller.callServerEndpoint<_i21.ConversationMutationResult>(
    'conversation',
    'compact',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointMcpServer extends _i2.EndpointRef {
  EndpointMcpServer(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mcpServer';

  _i3.Future<_i38.CreateMcpServerResult> create(
    _i39.CreateMcpServerRequest request,
  ) => caller.callServerEndpoint<_i38.CreateMcpServerResult>(
    'mcpServer',
    'create',
    {'request': request},
  );

  _i3.Future<void> delete(_i40.DeleteMcpServerRequest request) =>
      caller.callServerEndpoint<void>(
        'mcpServer',
        'delete',
        {'request': request},
      );

  _i3.Future<_i41.DiscoverMcpServerResult> discoverAndCheck(
    _i42.DiscoverMcpServerRequest request,
  ) => caller.callServerEndpoint<_i41.DiscoverMcpServerResult>(
    'mcpServer',
    'discoverAndCheck',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointModelConnection extends _i2.EndpointRef {
  EndpointModelConnection(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'modelConnection';

  _i3.Future<List<_i43.ApiModelProvider>> listCatalogProviders() =>
      caller.callServerEndpoint<List<_i43.ApiModelProvider>>(
        'modelConnection',
        'listCatalogProviders',
        {},
      );

  _i3.Future<List<_i44.ApiModel>> listCatalogModels({String? providerId}) =>
      caller.callServerEndpoint<List<_i44.ApiModel>>(
        'modelConnection',
        'listCatalogModels',
        {'providerId': providerId},
      );

  _i3.Future<_i45.ModelConnectionView> create(
    _i46.CreateModelConnectionRequest request,
  ) => caller.callServerEndpoint<_i45.ModelConnectionView>(
    'modelConnection',
    'create',
    {'request': request},
  );

  _i3.Future<List<_i45.ModelConnectionView>> list(
    _i47.ListModelConnectionsRequest request,
  ) => caller.callServerEndpoint<List<_i45.ModelConnectionView>>(
    'modelConnection',
    'list',
    {'request': request},
  );

  _i3.Future<_i45.ModelConnectionView> update(
    _i48.UpdateModelConnectionRequest request,
  ) => caller.callServerEndpoint<_i45.ModelConnectionView>(
    'modelConnection',
    'update',
    {'request': request},
  );

  _i3.Future<void> delete(_i49.DeleteModelConnectionRequest request) =>
      caller.callServerEndpoint<void>(
        'modelConnection',
        'delete',
        {'request': request},
      );

  _i3.Future<List<_i50.WorkspaceModelSelectionView>> listSelections(
    _i51.ListWorkspaceModelSelectionsRequest request,
  ) => caller.callServerEndpoint<List<_i50.WorkspaceModelSelectionView>>(
    'modelConnection',
    'listSelections',
    {'request': request},
  );

  _i3.Future<_i52.ModelSyncResult> testAndSync(
    _i53.TestAndSyncModelConnectionRequest request,
  ) => caller.callServerEndpoint<_i52.ModelSyncResult>(
    'modelConnection',
    'testAndSync',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointObject extends _i2.EndpointRef {
  EndpointObject(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'object';

  _i3.Future<_i54.BeginUploadResult> beginUpload(
    _i55.BeginUploadRequest request,
  ) => caller.callServerEndpoint<_i54.BeginUploadResult>(
    'object',
    'beginUpload',
    {'request': request},
  );

  _i3.Future<_i56.ObjectResult> completeUpload(
    _i57.CompleteUploadRequest request,
  ) => caller.callServerEndpoint<_i56.ObjectResult>(
    'object',
    'completeUpload',
    {'request': request},
  );

  _i3.Future<_i58.GetDownloadResult> getDownload(
    _i59.GetDownloadRequest request,
  ) => caller.callServerEndpoint<_i58.GetDownloadResult>(
    'object',
    'getDownload',
    {'request': request},
  );

  _i3.Future<void> delete(_i60.DeleteObjectRequest request) =>
      caller.callServerEndpoint<void>(
        'object',
        'delete',
        {'request': request},
      );
}

/// {@category Endpoint}
class EndpointWorkspaceStream extends _i2.EndpointRef {
  EndpointWorkspaceStream(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceStream';

  _i3.Stream<_i61.WorkspaceStreamEnvelope> subscribe(
    _i62.WorkspaceSubscribeRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i61.WorkspaceStreamEnvelope>,
        _i61.WorkspaceStreamEnvelope
      >(
        'workspaceStream',
        'subscribe',
        {'request': request},
        {},
      );
}

/// {@category Endpoint}
class EndpointWorkspaceSecret extends _i2.EndpointRef {
  EndpointWorkspaceSecret(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceSecret';

  _i3.Future<_i63.PutWorkspaceSecretResponse> put(
    _i64.PutWorkspaceSecretRequest request,
  ) => caller.callServerEndpoint<_i63.PutWorkspaceSecretResponse>(
    'workspaceSecret',
    'put',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointWorkspaceState extends _i2.EndpointRef {
  EndpointWorkspaceState(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspaceState';

  _i3.Future<_i65.ReadWorkspaceStateResponse> read(
    _i66.ReadWorkspaceStateRequest request,
  ) => caller.callServerEndpoint<_i65.ReadWorkspaceStateResponse>(
    'workspaceState',
    'read',
    {'request': request},
  );

  _i3.Future<_i67.PatchWorkspaceStateResponse> patch(
    _i68.PatchWorkspaceStateRequest request,
  ) => caller.callServerEndpoint<_i67.PatchWorkspaceStateResponse>(
    'workspaceState',
    'patch',
    {'request': request},
  );

  _i3.Future<_i69.MutateWorkspaceCredentialResponse> mutateCredential(
    _i70.MutateWorkspaceCredentialRequest request,
  ) => caller.callServerEndpoint<_i69.MutateWorkspaceCredentialResponse>(
    'workspaceState',
    'mutateCredential',
    {'request': request},
  );
}

/// {@category Endpoint}
class EndpointCloudWorkspace extends _i2.EndpointRef {
  EndpointCloudWorkspace(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudWorkspace';

  _i3.Future<List<_i71.CloudWorkspaceSummary>> listAuthorizedWorkspaces() =>
      caller.callServerEndpoint<List<_i71.CloudWorkspaceSummary>>(
        'cloudWorkspace',
        'listAuthorizedWorkspaces',
        {},
      );

  _i3.Future<List<_i72.PendingWorkspaceInviteSummary>> listPendingInvites() =>
      caller.callServerEndpoint<List<_i72.PendingWorkspaceInviteSummary>>(
        'cloudWorkspace',
        'listPendingInvites',
        {},
      );

  _i3.Future<_i73.CloudWorkspaceDetail> getWorkspaceDetail(
    _i74.GetCloudWorkspaceDetailRequest request,
  ) => caller.callServerEndpoint<_i73.CloudWorkspaceDetail>(
    'cloudWorkspace',
    'getWorkspaceDetail',
    {'request': request},
  );

  _i3.Future<List<_i75.CloudWorkspaceMemberSummary>> listMembers(
    _i76.ListWorkspaceMembersRequest request,
  ) => caller.callServerEndpoint<List<_i75.CloudWorkspaceMemberSummary>>(
    'cloudWorkspace',
    'listMembers',
    {'request': request},
  );

  _i3.Future<List<_i77.CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    _i78.ListCloudWorkspaceInvitesRequest request,
  ) => caller.callServerEndpoint<List<_i77.CloudWorkspaceInviteSummary>>(
    'cloudWorkspace',
    'listWorkspaceInvites',
    {'request': request},
  );

  _i3.Future<_i71.CloudWorkspaceSummary> createWorkspace(
    _i79.CreateCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_i71.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'createWorkspace',
    {'request': request},
  );

  _i3.Future<_i72.PendingWorkspaceInviteSummary> inviteMember(
    _i80.InviteWorkspaceMemberRequest request,
  ) => caller.callServerEndpoint<_i72.PendingWorkspaceInviteSummary>(
    'cloudWorkspace',
    'inviteMember',
    {'request': request},
  );

  _i3.Future<_i77.CloudWorkspaceInviteSummary> renewInvite(
    _i81.RenewWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_i77.CloudWorkspaceInviteSummary>(
    'cloudWorkspace',
    'renewInvite',
    {'request': request},
  );

  _i3.Future<void> revokeInvite(_i82.RevokeWorkspaceInviteRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'revokeInvite',
        {'request': request},
      );

  _i3.Future<_i71.CloudWorkspaceSummary> acceptInvite(
    _i83.AcceptWorkspaceInviteRequest request,
  ) => caller.callServerEndpoint<_i71.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'acceptInvite',
    {'request': request},
  );

  _i3.Future<void> declineInvite(_i84.DeclineWorkspaceInviteRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'declineInvite',
        {'request': request},
      );

  _i3.Future<_i71.CloudWorkspaceSummary> renameWorkspace(
    _i85.RenameCloudWorkspaceRequest request,
  ) => caller.callServerEndpoint<_i71.CloudWorkspaceSummary>(
    'cloudWorkspace',
    'renameWorkspace',
    {'request': request},
  );

  _i3.Future<void> leaveWorkspace(_i86.LeaveCloudWorkspaceRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'leaveWorkspace',
        {'request': request},
      );

  _i3.Future<void> transferOwnership(
    _i87.TransferCloudWorkspaceOwnershipRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'transferOwnership',
    {'request': request},
  );

  _i3.Future<void> updateMemberRole(
    _i88.UpdateWorkspaceMemberRoleRequest request,
  ) => caller.callServerEndpoint<void>(
    'cloudWorkspace',
    'updateMemberRole',
    {'request': request},
  );

  _i3.Future<void> removeMember(_i89.RemoveWorkspaceMemberRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'removeMember',
        {'request': request},
      );

  _i3.Future<void> deleteWorkspace(_i90.DeleteCloudWorkspaceRequest request) =>
      caller.callServerEndpoint<void>(
        'cloudWorkspace',
        'deleteWorkspace',
        {'request': request},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_core = _i4.Caller(client);
    serverpod_auth_idp = _i1.Caller(client);
  }

  late final _i4.Caller serverpod_auth_core;

  late final _i1.Caller serverpod_auth_idp;
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
    _i91.Client? httpClientOverride,
  }) : super(
         host,
         _i92.Protocol(),
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
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'account': account,
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
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_core': modules.serverpod_auth_core,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
