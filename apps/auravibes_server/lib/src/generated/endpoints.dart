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
import '../features/codex_oauth/codex_oauth_endpoint.dart' as _i5;
import '../features/conversations/conversation_endpoint.dart' as _i6;
import '../features/mcp_servers/mcp_server_endpoint.dart' as _i7;
import '../features/model_connections/model_connection_endpoint.dart' as _i8;
import '../features/objects/object_endpoint.dart' as _i9;
import '../features/sync/stream/workspace_stream_endpoint.dart' as _i10;
import '../features/workspace_state/workspace_secret_endpoint.dart' as _i11;
import '../features/workspace_state/workspace_state_endpoint.dart' as _i12;
import '../features/workspaces/cloud_workspace_endpoint.dart' as _i13;

import 'package:auravibes_server/src/generated/features/codex_oauth/models/start_codex_oauth_request.dart'
    as _i14;
import 'package:auravibes_server/src/generated/features/codex_oauth/models/complete_codex_oauth_request.dart'
    as _i15;
import 'package:auravibes_server/src/generated/features/conversations/models/create_conversation_request.dart'
    as _i16;
import 'package:auravibes_server/src/generated/features/conversations/models/list_conversations_request.dart'
    as _i17;
import 'package:auravibes_server/src/generated/features/conversations/models/get_conversation_request.dart'
    as _i18;
import 'package:auravibes_server/src/generated/features/conversations/models/list_conversation_messages_request.dart'
    as _i19;
import 'package:auravibes_server/src/generated/features/conversations/models/update_conversation_request.dart'
    as _i20;
import 'package:auravibes_server/src/generated/features/conversations/models/delete_conversation_request.dart'
    as _i21;
import 'package:auravibes_server/src/generated/features/conversations/models/start_turn_request.dart'
    as _i22;
import 'package:auravibes_server/src/generated/features/conversations/models/continue_turn_request.dart'
    as _i23;
import 'package:auravibes_server/src/generated/features/conversations/models/get_turn_request.dart'
    as _i24;
import 'package:auravibes_server/src/generated/features/conversations/models/queue_conversation_message_request.dart'
    as _i25;
import 'package:auravibes_server/src/generated/features/conversations/models/continue_conversation_request.dart'
    as _i26;
import 'package:auravibes_server/src/generated/features/conversations/models/stop_conversation_request.dart'
    as _i27;
import 'package:auravibes_server/src/generated/features/conversations/models/edit_pending_conversation_message_request.dart'
    as _i28;
import 'package:auravibes_server/src/generated/features/conversations/models/reorder_pending_conversation_message_request.dart'
    as _i29;
import 'package:auravibes_server/src/generated/features/conversations/models/remove_pending_conversation_message_request.dart'
    as _i30;
import 'package:auravibes_server/src/generated/features/conversations/models/update_conversation_settings_request.dart'
    as _i31;
import 'package:auravibes_server/src/generated/features/conversations/models/submit_tool_decision_request.dart'
    as _i32;
import 'package:auravibes_server/src/generated/features/conversations/models/cancel_turn_request.dart'
    as _i33;
import 'package:auravibes_server/src/generated/features/conversations/models/compact_conversation_request.dart'
    as _i34;
import 'package:auravibes_server/src/generated/features/conversations/models/conversation_subscribe_request.dart'
    as _i35;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/create_mcp_server_request.dart'
    as _i36;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/delete_mcp_server_request.dart'
    as _i37;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/discover_mcp_server_request.dart'
    as _i38;
import 'package:auravibes_server/src/generated/features/model_connections/models/create_model_connection_request.dart'
    as _i39;
import 'package:auravibes_server/src/generated/features/model_connections/models/list_model_connections_request.dart'
    as _i40;
import 'package:auravibes_server/src/generated/features/model_connections/models/update_model_connection_request.dart'
    as _i41;
import 'package:auravibes_server/src/generated/features/model_connections/models/delete_model_connection_request.dart'
    as _i42;
import 'package:auravibes_server/src/generated/features/model_connections/models/list_workspace_model_selections_request.dart'
    as _i43;
import 'package:auravibes_server/src/generated/features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _i44;
import 'package:auravibes_server/src/generated/features/objects/models/begin_upload_request.dart'
    as _i45;
import 'package:auravibes_server/src/generated/features/objects/models/complete_upload_request.dart'
    as _i46;
import 'package:auravibes_server/src/generated/features/objects/models/get_download_request.dart'
    as _i47;
import 'package:auravibes_server/src/generated/features/objects/models/delete_object_request.dart'
    as _i48;
import 'package:auravibes_server/src/generated/features/sync/stream/models/workspace_subscribe_request.dart'
    as _i49;
import 'package:auravibes_server/src/generated/features/workspace_state/models/put_workspace_secret_request.dart'
    as _i50;
import 'package:auravibes_server/src/generated/features/workspace_state/models/read_workspace_state_request.dart'
    as _i51;
import 'package:auravibes_server/src/generated/features/workspace_state/models/patch_workspace_state_request.dart'
    as _i52;
import 'package:auravibes_server/src/generated/features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _i53;
import 'package:auravibes_server/src/generated/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i54;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_workspace_members_request.dart'
    as _i55;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i56;
import 'package:auravibes_server/src/generated/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i57;
import 'package:auravibes_server/src/generated/features/workspaces/models/invite_workspace_member_request.dart'
    as _i58;
import 'package:auravibes_server/src/generated/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i59;
import 'package:auravibes_server/src/generated/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i60;
import 'package:auravibes_server/src/generated/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i61;
import 'package:auravibes_server/src/generated/features/workspaces/models/decline_workspace_invite_request.dart'
    as _i62;
import 'package:auravibes_server/src/generated/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i63;
import 'package:auravibes_server/src/generated/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i64;
import 'package:auravibes_server/src/generated/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i65;
import 'package:auravibes_server/src/generated/features/workspaces/models/update_workspace_member_role_request.dart'
    as _i66;
import 'package:auravibes_server/src/generated/features/workspaces/models/remove_workspace_member_request.dart'
    as _i67;
import 'package:auravibes_server/src/generated/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i68;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i69;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i70;

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
      'codexOAuth': _i5.CodexOAuthEndpoint()
        ..initialize(
          server,
          'codexOAuth',
          null,
        ),
      'conversation': _i6.ConversationEndpoint()
        ..initialize(
          server,
          'conversation',
          null,
        ),
      'mcpServer': _i7.McpServerEndpoint()
        ..initialize(
          server,
          'mcpServer',
          null,
        ),
      'modelConnection': _i8.ModelConnectionEndpoint()
        ..initialize(
          server,
          'modelConnection',
          null,
        ),
      'object': _i9.ObjectEndpoint()
        ..initialize(
          server,
          'object',
          null,
        ),
      'workspaceStream': _i10.WorkspaceStreamEndpoint()
        ..initialize(
          server,
          'workspaceStream',
          null,
        ),
      'workspaceSecret': _i11.WorkspaceSecretEndpoint()
        ..initialize(
          server,
          'workspaceSecret',
          null,
        ),
      'workspaceState': _i12.WorkspaceStateEndpoint()
        ..initialize(
          server,
          'workspaceState',
          null,
        ),
      'cloudWorkspace': _i13.CloudWorkspaceEndpoint()
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
    connectors['codexOAuth'] = _i1.EndpointConnector(
      name: 'codexOAuth',
      endpoint: endpoints['codexOAuth']!,
      methodConnectors: {
        'start': _i1.MethodConnector(
          name: 'start',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.StartCodexOAuthRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codexOAuth'] as _i5.CodexOAuthEndpoint).start(
                    session,
                    params['request'],
                  ),
        ),
        'complete': _i1.MethodConnector(
          name: 'complete',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i15.CompleteCodexOAuthRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codexOAuth'] as _i5.CodexOAuthEndpoint).complete(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['conversation'] = _i1.EndpointConnector(
      name: 'conversation',
      endpoint: endpoints['conversation']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i16.CreateConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .create(
                    session,
                    params['request'],
                  ),
        ),
        'list': _i1.MethodConnector(
          name: 'list',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i17.ListConversationsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _i6.ConversationEndpoint).list(
                    session,
                    params['request'],
                  ),
        ),
        'listPage': _i1.MethodConnector(
          name: 'listPage',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i17.ListConversationsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .listPage(
                    session,
                    params['request'],
                  ),
        ),
        'get': _i1.MethodConnector(
          name: 'get',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i18.GetConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _i6.ConversationEndpoint).get(
                    session,
                    params['request'],
                  ),
        ),
        'listMessages': _i1.MethodConnector(
          name: 'listMessages',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.ListConversationMessagesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .listMessages(
                    session,
                    params['request'],
                  ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i20.UpdateConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .update(
                    session,
                    params['request'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i21.DeleteConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .delete(
                    session,
                    params['request'],
                  ),
        ),
        'startTurn': _i1.MethodConnector(
          name: 'startTurn',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i22.StartTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .startTurn(
                    session,
                    params['request'],
                  ),
        ),
        'continueTurn': _i1.MethodConnector(
          name: 'continueTurn',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i23.ContinueTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .continueTurn(
                    session,
                    params['request'],
                  ),
        ),
        'getTurn': _i1.MethodConnector(
          name: 'getTurn',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i24.GetTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .getTurn(
                    session,
                    params['request'],
                  ),
        ),
        'getConversationSnapshot': _i1.MethodConnector(
          name: 'getConversationSnapshot',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i18.GetConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .getConversationSnapshot(
                    session,
                    params['request'],
                  ),
        ),
        'queueConversationMessage': _i1.MethodConnector(
          name: 'queueConversationMessage',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i25.QueueConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .queueConversationMessage(
                    session,
                    params['request'],
                  ),
        ),
        'continueConversation': _i1.MethodConnector(
          name: 'continueConversation',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i26.ContinueConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .continueConversation(
                    session,
                    params['request'],
                  ),
        ),
        'stopConversation': _i1.MethodConnector(
          name: 'stopConversation',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i27.StopConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .stopConversation(
                    session,
                    params['request'],
                  ),
        ),
        'editPendingConversationMessage': _i1.MethodConnector(
          name: 'editPendingConversationMessage',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i28.EditPendingConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .editPendingConversationMessage(
                    session,
                    params['request'],
                  ),
        ),
        'reorderPendingConversationMessage': _i1.MethodConnector(
          name: 'reorderPendingConversationMessage',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1
                  .getType<_i29.ReorderPendingConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .reorderPendingConversationMessage(
                    session,
                    params['request'],
                  ),
        ),
        'removePendingConversationMessage': _i1.MethodConnector(
          name: 'removePendingConversationMessage',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i30.RemovePendingConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .removePendingConversationMessage(
                    session,
                    params['request'],
                  ),
        ),
        'updateConversationSettings': _i1.MethodConnector(
          name: 'updateConversationSettings',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i31.UpdateConversationSettingsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .updateConversationSettings(
                    session,
                    params['request'],
                  ),
        ),
        'submitToolDecision': _i1.MethodConnector(
          name: 'submitToolDecision',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i32.SubmitToolDecisionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .submitToolDecision(
                    session,
                    params['request'],
                  ),
        ),
        'cancelTurn': _i1.MethodConnector(
          name: 'cancelTurn',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i33.CancelTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .cancelTurn(
                    session,
                    params['request'],
                  ),
        ),
        'compact': _i1.MethodConnector(
          name: 'compact',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i34.CompactConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .compact(
                    session,
                    params['request'],
                  ),
        ),
        'subscribeConversation': _i1.MethodStreamConnector(
          name: 'subscribeConversation',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i35.ConversationSubscribeRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['conversation'] as _i6.ConversationEndpoint)
                  .subscribeConversation(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['mcpServer'] = _i1.EndpointConnector(
      name: 'mcpServer',
      endpoint: endpoints['mcpServer']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i36.CreateMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mcpServer'] as _i7.McpServerEndpoint).create(
                    session,
                    params['request'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i37.DeleteMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mcpServer'] as _i7.McpServerEndpoint).delete(
                    session,
                    params['request'],
                  ),
        ),
        'discoverAndCheck': _i1.MethodConnector(
          name: 'discoverAndCheck',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i38.DiscoverMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mcpServer'] as _i7.McpServerEndpoint)
                  .discoverAndCheck(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['modelConnection'] = _i1.EndpointConnector(
      name: 'modelConnection',
      endpoint: endpoints['modelConnection']!,
      methodConnectors: {
        'listCatalogProviders': _i1.MethodConnector(
          name: 'listCatalogProviders',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .listCatalogProviders(session),
        ),
        'listCatalogModels': _i1.MethodConnector(
          name: 'listCatalogModels',
          params: {
            'providerId': _i1.ParameterDescription(
              name: 'providerId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .listCatalogModels(
                        session,
                        providerId: params['providerId'],
                      ),
        ),
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i39.CreateModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .create(
                        session,
                        params['request'],
                      ),
        ),
        'list': _i1.MethodConnector(
          name: 'list',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i40.ListModelConnectionsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .list(
                        session,
                        params['request'],
                      ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i41.UpdateModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .update(
                        session,
                        params['request'],
                      ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i42.DeleteModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .delete(
                        session,
                        params['request'],
                      ),
        ),
        'listSelections': _i1.MethodConnector(
          name: 'listSelections',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i43.ListWorkspaceModelSelectionsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .listSelections(
                        session,
                        params['request'],
                      ),
        ),
        'testAndSync': _i1.MethodConnector(
          name: 'testAndSync',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i44.TestAndSyncModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection'] as _i8.ModelConnectionEndpoint)
                      .testAndSync(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['object'] = _i1.EndpointConnector(
      name: 'object',
      endpoint: endpoints['object']!,
      methodConnectors: {
        'beginUpload': _i1.MethodConnector(
          name: 'beginUpload',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i45.BeginUploadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _i9.ObjectEndpoint).beginUpload(
                    session,
                    params['request'],
                  ),
        ),
        'completeUpload': _i1.MethodConnector(
          name: 'completeUpload',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i46.CompleteUploadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _i9.ObjectEndpoint).completeUpload(
                    session,
                    params['request'],
                  ),
        ),
        'getDownload': _i1.MethodConnector(
          name: 'getDownload',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i47.GetDownloadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _i9.ObjectEndpoint).getDownload(
                    session,
                    params['request'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i48.DeleteObjectRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['object'] as _i9.ObjectEndpoint).delete(
                session,
                params['request'],
              ),
        ),
      },
    );
    connectors['workspaceStream'] = _i1.EndpointConnector(
      name: 'workspaceStream',
      endpoint: endpoints['workspaceStream']!,
      methodConnectors: {
        'subscribe': _i1.MethodStreamConnector(
          name: 'subscribe',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i49.WorkspaceSubscribeRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['workspaceStream'] as _i10.WorkspaceStreamEndpoint)
                      .subscribe(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['workspaceSecret'] = _i1.EndpointConnector(
      name: 'workspaceSecret',
      endpoint: endpoints['workspaceSecret']!,
      methodConnectors: {
        'put': _i1.MethodConnector(
          name: 'put',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i50.PutWorkspaceSecretRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceSecret'] as _i11.WorkspaceSecretEndpoint)
                      .put(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['workspaceState'] = _i1.EndpointConnector(
      name: 'workspaceState',
      endpoint: endpoints['workspaceState']!,
      methodConnectors: {
        'read': _i1.MethodConnector(
          name: 'read',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i51.ReadWorkspaceStateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState'] as _i12.WorkspaceStateEndpoint)
                      .read(
                        session,
                        params['request'],
                      ),
        ),
        'patch': _i1.MethodConnector(
          name: 'patch',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i52.PatchWorkspaceStateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState'] as _i12.WorkspaceStateEndpoint)
                      .patch(
                        session,
                        params['request'],
                      ),
        ),
        'mutateCredential': _i1.MethodConnector(
          name: 'mutateCredential',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i53.MutateWorkspaceCredentialRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState'] as _i12.WorkspaceStateEndpoint)
                      .mutateCredential(
                        session,
                        params['request'],
                      ),
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
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
                      .listPendingInvites(session),
        ),
        'getWorkspaceDetail': _i1.MethodConnector(
          name: 'getWorkspaceDetail',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i54.GetCloudWorkspaceDetailRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i55.ListWorkspaceMembersRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i56.ListCloudWorkspaceInvitesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i57.CreateCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i58.InviteWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i59.RenewWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i60.RevokeWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i61.AcceptWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i62.DeclineWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i63.RenameCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i64.LeaveCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i65.TransferCloudWorkspaceOwnershipRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i66.UpdateWorkspaceMemberRoleRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i67.RemoveWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
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
              type: _i1.getType<_i68.DeleteCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace'] as _i13.CloudWorkspaceEndpoint)
                      .deleteWorkspace(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _i69.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _i70.Endpoints()
      ..initializeEndpoints(server);
  }
}
