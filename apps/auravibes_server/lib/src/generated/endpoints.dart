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
import 'package:auravibes_server/src/generated/features/agents/models/get_agent_resources_request.dart'
    as _ijcdp7pz;
import 'package:auravibes_server/src/generated/features/agents/models/list_agents_request.dart'
    as _ibj467a3;
import 'package:auravibes_server/src/generated/features/codex_oauth/models/complete_codex_oauth_request.dart'
    as _ir0ud11r;
import 'package:auravibes_server/src/generated/features/codex_oauth/models/start_codex_oauth_request.dart'
    as _ivuexb4h;
import 'package:auravibes_server/src/generated/features/conversations/models/cancel_turn_request.dart'
    as _i4j5a2zc;
import 'package:auravibes_server/src/generated/features/conversations/models/compact_conversation_request.dart'
    as _i955umfq;
import 'package:auravibes_server/src/generated/features/conversations/models/continue_conversation_request.dart'
    as _ihn1s8rq;
import 'package:auravibes_server/src/generated/features/conversations/models/continue_turn_request.dart'
    as _io8jb8cg;
import 'package:auravibes_server/src/generated/features/conversations/models/conversation_subscribe_request.dart'
    as _iwkyl6n9;
import 'package:auravibes_server/src/generated/features/conversations/models/create_conversation_request.dart'
    as _ish3zj9o;
import 'package:auravibes_server/src/generated/features/conversations/models/delete_conversation_request.dart'
    as _il5llor3;
import 'package:auravibes_server/src/generated/features/conversations/models/edit_pending_conversation_message_request.dart'
    as _igstxg4l;
import 'package:auravibes_server/src/generated/features/conversations/models/get_conversation_request.dart'
    as _itkmf3xs;
import 'package:auravibes_server/src/generated/features/conversations/models/get_turn_request.dart'
    as _iaqawmcu;
import 'package:auravibes_server/src/generated/features/conversations/models/list_conversation_messages_request.dart'
    as _i5dqxctc;
import 'package:auravibes_server/src/generated/features/conversations/models/list_conversations_request.dart'
    as _i0m5o1i2;
import 'package:auravibes_server/src/generated/features/conversations/models/queue_conversation_message_request.dart'
    as _i605rjdx;
import 'package:auravibes_server/src/generated/features/conversations/models/remove_pending_conversation_message_request.dart'
    as _irlsykk6;
import 'package:auravibes_server/src/generated/features/conversations/models/reorder_pending_conversation_message_request.dart'
    as _ilmuzuyl;
import 'package:auravibes_server/src/generated/features/conversations/models/start_turn_request.dart'
    as _ijasfsbp;
import 'package:auravibes_server/src/generated/features/conversations/models/stop_conversation_request.dart'
    as _ii20rgdx;
import 'package:auravibes_server/src/generated/features/conversations/models/submit_tool_decision_request.dart'
    as _ii7vetdc;
import 'package:auravibes_server/src/generated/features/conversations/models/update_conversation_request.dart'
    as _i8uhzhf3;
import 'package:auravibes_server/src/generated/features/conversations/models/update_conversation_settings_request.dart'
    as _iwnddrxr;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/create_mcp_server_request.dart'
    as _ij06ag3u;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/delete_mcp_server_request.dart'
    as _ilfhgnq3;
import 'package:auravibes_server/src/generated/features/mcp_servers/models/discover_mcp_server_request.dart'
    as _imtqkt48;
import 'package:auravibes_server/src/generated/features/model_connections/models/create_model_connection_request.dart'
    as _iq4yqonh;
import 'package:auravibes_server/src/generated/features/model_connections/models/delete_model_connection_request.dart'
    as _ikucadiy;
import 'package:auravibes_server/src/generated/features/model_connections/models/list_model_connections_request.dart'
    as _ii4wbihw;
import 'package:auravibes_server/src/generated/features/model_connections/models/list_workspace_model_selections_request.dart'
    as _infwdxn7;
import 'package:auravibes_server/src/generated/features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _iskhxh94;
import 'package:auravibes_server/src/generated/features/model_connections/models/update_model_connection_request.dart'
    as _i2yb5fxk;
import 'package:auravibes_server/src/generated/features/objects/models/begin_upload_request.dart'
    as _i873rzap;
import 'package:auravibes_server/src/generated/features/objects/models/complete_upload_request.dart'
    as _ifp2nyf8;
import 'package:auravibes_server/src/generated/features/objects/models/delete_object_request.dart'
    as _ikvc6p78;
import 'package:auravibes_server/src/generated/features/objects/models/get_download_request.dart'
    as _itlqxnii;
import 'package:auravibes_server/src/generated/features/sync/stream/models/workspace_subscribe_request.dart'
    as _i87sg8g4;
import 'package:auravibes_server/src/generated/features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _ii40hsqd;
import 'package:auravibes_server/src/generated/features/workspace_state/models/patch_workspace_state_request.dart'
    as _iti8d4cu;
import 'package:auravibes_server/src/generated/features/workspace_state/models/put_workspace_secret_request.dart'
    as _ixodmwhe;
import 'package:auravibes_server/src/generated/features/workspace_state/models/read_workspace_state_request.dart'
    as _i2v5creq;
import 'package:auravibes_server/src/generated/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i3cjuwla;
import 'package:auravibes_server/src/generated/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i65qcwf4;
import 'package:auravibes_server/src/generated/features/workspaces/models/decline_workspace_invite_request.dart'
    as _inamn2d7;
import 'package:auravibes_server/src/generated/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _imv0e49a;
import 'package:auravibes_server/src/generated/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _ifw8zf1l;
import 'package:auravibes_server/src/generated/features/workspaces/models/invite_workspace_member_request.dart'
    as _iv16131v;
import 'package:auravibes_server/src/generated/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _is93p8g5;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _imorkccq;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_workspace_members_request.dart'
    as _iebkjj2l;
import 'package:auravibes_server/src/generated/features/workspaces/models/remove_workspace_member_request.dart'
    as _i6zx39if;
import 'package:auravibes_server/src/generated/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i03e4t22;
import 'package:auravibes_server/src/generated/features/workspaces/models/renew_workspace_invite_request.dart'
    as _iidbk7at;
import 'package:auravibes_server/src/generated/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _immu2eqq;
import 'package:auravibes_server/src/generated/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _iz1a25vz;
import 'package:auravibes_server/src/generated/features/workspaces/models/update_workspace_member_role_request.dart'
    as _iekbk1on;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;

import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../features/accounts/account_endpoint.dart' as _iytsp81w;
import '../features/agents/agent_catalog_endpoint.dart' as _ivvm0cyi;
import '../features/codex_oauth/codex_oauth_endpoint.dart' as _igisrqgh;
import '../features/conversations/conversation_endpoint.dart' as _ie3ymqip;
import '../features/mcp_servers/mcp_server_endpoint.dart' as _im1tu8co;
import '../features/model_connections/model_connection_endpoint.dart'
    as _irncar1s;
import '../features/objects/object_endpoint.dart' as _ia0f4jqg;
import '../features/sync/stream/workspace_stream_endpoint.dart' as _ifbwcqx4;
import '../features/workspace_state/workspace_secret_endpoint.dart'
    as _i2j4mlvu;
import '../features/workspace_state/workspace_state_endpoint.dart' as _iv99006q;
import '../features/workspaces/cloud_workspace_endpoint.dart' as _ij5poshv;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'account': _iytsp81w.AccountEndpoint()
        ..initialize(
          server,
          'account',
          null,
        ),
      'agentCatalog': _ivvm0cyi.AgentCatalogEndpoint()
        ..initialize(
          server,
          'agentCatalog',
          null,
        ),
      'codexOAuth': _igisrqgh.CodexOAuthEndpoint()
        ..initialize(
          server,
          'codexOAuth',
          null,
        ),
      'conversation': _ie3ymqip.ConversationEndpoint()
        ..initialize(
          server,
          'conversation',
          null,
        ),
      'mcpServer': _im1tu8co.McpServerEndpoint()
        ..initialize(
          server,
          'mcpServer',
          null,
        ),
      'modelConnection': _irncar1s.ModelConnectionEndpoint()
        ..initialize(
          server,
          'modelConnection',
          null,
        ),
      'object': _ia0f4jqg.ObjectEndpoint()
        ..initialize(
          server,
          'object',
          null,
        ),
      'workspaceStream': _ifbwcqx4.WorkspaceStreamEndpoint()
        ..initialize(
          server,
          'workspaceStream',
          null,
        ),
      'workspaceSecret': _i2j4mlvu.WorkspaceSecretEndpoint()
        ..initialize(
          server,
          'workspaceSecret',
          null,
        ),
      'workspaceState': _iv99006q.WorkspaceStateEndpoint()
        ..initialize(
          server,
          'workspaceState',
          null,
        ),
      'cloudWorkspace': _ij5poshv.CloudWorkspaceEndpoint()
        ..initialize(
          server,
          'cloudWorkspace',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['account'] = _is.EndpointConnector(
      name: 'account',
      endpoint: endpoints['account']!,
      methodConnectors: {
        'currentUser': _is.MethodConnector(
          name: 'currentUser',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _iytsp81w.AccountEndpoint)
                  .currentUser(session),
        ),
      },
    );
    connectors['agentCatalog'] = _is.EndpointConnector(
      name: 'agentCatalog',
      endpoint: endpoints['agentCatalog']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ibj467a3.ListAgentsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['agentCatalog'] as _ivvm0cyi.AgentCatalogEndpoint)
                      .list(
                        session,
                        params['request'],
                      ),
        ),
        'getResources': _is.MethodConnector(
          name: 'getResources',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ijcdp7pz.GetAgentResourcesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['agentCatalog'] as _ivvm0cyi.AgentCatalogEndpoint)
                      .getResources(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['codexOAuth'] = _is.EndpointConnector(
      name: 'codexOAuth',
      endpoint: endpoints['codexOAuth']!,
      methodConnectors: {
        'start': _is.MethodConnector(
          name: 'start',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ivuexb4h.StartCodexOAuthRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codexOAuth'] as _igisrqgh.CodexOAuthEndpoint)
                      .start(
                        session,
                        params['request'],
                      ),
        ),
        'complete': _is.MethodConnector(
          name: 'complete',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ir0ud11r.CompleteCodexOAuthRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codexOAuth'] as _igisrqgh.CodexOAuthEndpoint)
                      .complete(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['conversation'] = _is.EndpointConnector(
      name: 'conversation',
      endpoint: endpoints['conversation']!,
      methodConnectors: {
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ish3zj9o.CreateConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .create(
                        session,
                        params['request'],
                      ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i0m5o1i2.ListConversationsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .list(
                        session,
                        params['request'],
                      ),
        ),
        'listPage': _is.MethodConnector(
          name: 'listPage',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i0m5o1i2.ListConversationsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .listPage(
                        session,
                        params['request'],
                      ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_itkmf3xs.GetConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .get(
                        session,
                        params['request'],
                      ),
        ),
        'listMessages': _is.MethodConnector(
          name: 'listMessages',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i5dqxctc.ListConversationMessagesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .listMessages(
                        session,
                        params['request'],
                      ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i8uhzhf3.UpdateConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .update(
                        session,
                        params['request'],
                      ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_il5llor3.DeleteConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .delete(
                        session,
                        params['request'],
                      ),
        ),
        'startTurn': _is.MethodConnector(
          name: 'startTurn',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ijasfsbp.StartTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .startTurn(
                        session,
                        params['request'],
                      ),
        ),
        'continueTurn': _is.MethodConnector(
          name: 'continueTurn',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_io8jb8cg.ContinueTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .continueTurn(
                        session,
                        params['request'],
                      ),
        ),
        'getTurn': _is.MethodConnector(
          name: 'getTurn',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iaqawmcu.GetTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .getTurn(
                        session,
                        params['request'],
                      ),
        ),
        'getConversationSnapshot': _is.MethodConnector(
          name: 'getConversationSnapshot',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_itkmf3xs.GetConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .getConversationSnapshot(
                        session,
                        params['request'],
                      ),
        ),
        'queueConversationMessage': _is.MethodConnector(
          name: 'queueConversationMessage',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i605rjdx.QueueConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .queueConversationMessage(
                        session,
                        params['request'],
                      ),
        ),
        'continueConversation': _is.MethodConnector(
          name: 'continueConversation',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ihn1s8rq.ContinueConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .continueConversation(
                        session,
                        params['request'],
                      ),
        ),
        'stopConversation': _is.MethodConnector(
          name: 'stopConversation',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ii20rgdx.StopConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .stopConversation(
                        session,
                        params['request'],
                      ),
        ),
        'editPendingConversationMessage': _is.MethodConnector(
          name: 'editPendingConversationMessage',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is
                  .getType<_igstxg4l.EditPendingConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .editPendingConversationMessage(
                        session,
                        params['request'],
                      ),
        ),
        'reorderPendingConversationMessage': _is.MethodConnector(
          name: 'reorderPendingConversationMessage',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is
                  .getType<
                    _ilmuzuyl.ReorderPendingConversationMessageRequest
                  >(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .reorderPendingConversationMessage(
                        session,
                        params['request'],
                      ),
        ),
        'removePendingConversationMessage': _is.MethodConnector(
          name: 'removePendingConversationMessage',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is
                  .getType<_irlsykk6.RemovePendingConversationMessageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .removePendingConversationMessage(
                        session,
                        params['request'],
                      ),
        ),
        'updateConversationSettings': _is.MethodConnector(
          name: 'updateConversationSettings',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iwnddrxr.UpdateConversationSettingsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .updateConversationSettings(
                        session,
                        params['request'],
                      ),
        ),
        'submitToolDecision': _is.MethodConnector(
          name: 'submitToolDecision',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ii7vetdc.SubmitToolDecisionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .submitToolDecision(
                        session,
                        params['request'],
                      ),
        ),
        'cancelTurn': _is.MethodConnector(
          name: 'cancelTurn',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i4j5a2zc.CancelTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .cancelTurn(
                        session,
                        params['request'],
                      ),
        ),
        'compact': _is.MethodConnector(
          name: 'compact',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i955umfq.CompactConversationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                      .compact(
                        session,
                        params['request'],
                      ),
        ),
        'subscribeConversation': _is.MethodStreamConnector(
          name: 'subscribeConversation',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iwkyl6n9.ConversationSubscribeRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['conversation'] as _ie3ymqip.ConversationEndpoint)
                  .subscribeConversation(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['mcpServer'] = _is.EndpointConnector(
      name: 'mcpServer',
      endpoint: endpoints['mcpServer']!,
      methodConnectors: {
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ij06ag3u.CreateMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mcpServer'] as _im1tu8co.McpServerEndpoint)
                  .create(
                    session,
                    params['request'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ilfhgnq3.DeleteMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mcpServer'] as _im1tu8co.McpServerEndpoint)
                  .delete(
                    session,
                    params['request'],
                  ),
        ),
        'discoverAndCheck': _is.MethodConnector(
          name: 'discoverAndCheck',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_imtqkt48.DiscoverMcpServerRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mcpServer'] as _im1tu8co.McpServerEndpoint)
                  .discoverAndCheck(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['modelConnection'] = _is.EndpointConnector(
      name: 'modelConnection',
      endpoint: endpoints['modelConnection']!,
      methodConnectors: {
        'listCatalogProviders': _is.MethodConnector(
          name: 'listCatalogProviders',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .listCatalogProviders(session),
        ),
        'listCatalogModels': _is.MethodConnector(
          name: 'listCatalogModels',
          params: {
            'providerId': _is.ParameterDescription(
              name: 'providerId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .listCatalogModels(
                        session,
                        providerId: params['providerId'],
                      ),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iq4yqonh.CreateModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .create(
                        session,
                        params['request'],
                      ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ii4wbihw.ListModelConnectionsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .list(
                        session,
                        params['request'],
                      ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i2yb5fxk.UpdateModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .update(
                        session,
                        params['request'],
                      ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ikucadiy.DeleteModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .delete(
                        session,
                        params['request'],
                      ),
        ),
        'listSelections': _is.MethodConnector(
          name: 'listSelections',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is
                  .getType<_infwdxn7.ListWorkspaceModelSelectionsRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .listSelections(
                        session,
                        params['request'],
                      ),
        ),
        'testAndSync': _is.MethodConnector(
          name: 'testAndSync',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iskhxh94.TestAndSyncModelConnectionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['modelConnection']
                          as _irncar1s.ModelConnectionEndpoint)
                      .testAndSync(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['object'] = _is.EndpointConnector(
      name: 'object',
      endpoint: endpoints['object']!,
      methodConnectors: {
        'beginUpload': _is.MethodConnector(
          name: 'beginUpload',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i873rzap.BeginUploadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _ia0f4jqg.ObjectEndpoint).beginUpload(
                    session,
                    params['request'],
                  ),
        ),
        'completeUpload': _is.MethodConnector(
          name: 'completeUpload',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ifp2nyf8.CompleteUploadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['object'] as _ia0f4jqg.ObjectEndpoint)
                  .completeUpload(
                    session,
                    params['request'],
                  ),
        ),
        'getDownload': _is.MethodConnector(
          name: 'getDownload',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_itlqxnii.GetDownloadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _ia0f4jqg.ObjectEndpoint).getDownload(
                    session,
                    params['request'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ikvc6p78.DeleteObjectRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['object'] as _ia0f4jqg.ObjectEndpoint).delete(
                    session,
                    params['request'],
                  ),
        ),
      },
    );
    connectors['workspaceStream'] = _is.EndpointConnector(
      name: 'workspaceStream',
      endpoint: endpoints['workspaceStream']!,
      methodConnectors: {
        'subscribe': _is.MethodStreamConnector(
          name: 'subscribe',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i87sg8g4.WorkspaceSubscribeRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['workspaceStream']
                          as _ifbwcqx4.WorkspaceStreamEndpoint)
                      .subscribe(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['workspaceSecret'] = _is.EndpointConnector(
      name: 'workspaceSecret',
      endpoint: endpoints['workspaceSecret']!,
      methodConnectors: {
        'put': _is.MethodConnector(
          name: 'put',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ixodmwhe.PutWorkspaceSecretRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceSecret']
                          as _i2j4mlvu.WorkspaceSecretEndpoint)
                      .put(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['workspaceState'] = _is.EndpointConnector(
      name: 'workspaceState',
      endpoint: endpoints['workspaceState']!,
      methodConnectors: {
        'read': _is.MethodConnector(
          name: 'read',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i2v5creq.ReadWorkspaceStateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState']
                          as _iv99006q.WorkspaceStateEndpoint)
                      .read(
                        session,
                        params['request'],
                      ),
        ),
        'patch': _is.MethodConnector(
          name: 'patch',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iti8d4cu.PatchWorkspaceStateRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState']
                          as _iv99006q.WorkspaceStateEndpoint)
                      .patch(
                        session,
                        params['request'],
                      ),
        ),
        'mutateCredential': _is.MethodConnector(
          name: 'mutateCredential',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ii40hsqd.MutateWorkspaceCredentialRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspaceState']
                          as _iv99006q.WorkspaceStateEndpoint)
                      .mutateCredential(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    connectors['cloudWorkspace'] = _is.EndpointConnector(
      name: 'cloudWorkspace',
      endpoint: endpoints['cloudWorkspace']!,
      methodConnectors: {
        'listAuthorizedWorkspaces': _is.MethodConnector(
          name: 'listAuthorizedWorkspaces',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .listAuthorizedWorkspaces(session),
        ),
        'listPendingInvites': _is.MethodConnector(
          name: 'listPendingInvites',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .listPendingInvites(session),
        ),
        'getWorkspaceDetail': _is.MethodConnector(
          name: 'getWorkspaceDetail',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ifw8zf1l.GetCloudWorkspaceDetailRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .getWorkspaceDetail(
                        session,
                        params['request'],
                      ),
        ),
        'listMembers': _is.MethodConnector(
          name: 'listMembers',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iebkjj2l.ListWorkspaceMembersRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .listMembers(
                        session,
                        params['request'],
                      ),
        ),
        'listWorkspaceInvites': _is.MethodConnector(
          name: 'listWorkspaceInvites',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_imorkccq.ListCloudWorkspaceInvitesRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .listWorkspaceInvites(
                        session,
                        params['request'],
                      ),
        ),
        'createWorkspace': _is.MethodConnector(
          name: 'createWorkspace',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i65qcwf4.CreateCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .createWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'inviteMember': _is.MethodConnector(
          name: 'inviteMember',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iv16131v.InviteWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .inviteMember(
                        session,
                        params['request'],
                      ),
        ),
        'renewInvite': _is.MethodConnector(
          name: 'renewInvite',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iidbk7at.RenewWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .renewInvite(
                        session,
                        params['request'],
                      ),
        ),
        'revokeInvite': _is.MethodConnector(
          name: 'revokeInvite',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_immu2eqq.RevokeWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .revokeInvite(
                        session,
                        params['request'],
                      ),
        ),
        'acceptInvite': _is.MethodConnector(
          name: 'acceptInvite',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i3cjuwla.AcceptWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .acceptInvite(
                        session,
                        params['request'],
                      ),
        ),
        'declineInvite': _is.MethodConnector(
          name: 'declineInvite',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_inamn2d7.DeclineWorkspaceInviteRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .declineInvite(
                        session,
                        params['request'],
                      ),
        ),
        'renameWorkspace': _is.MethodConnector(
          name: 'renameWorkspace',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i03e4t22.RenameCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .renameWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'leaveWorkspace': _is.MethodConnector(
          name: 'leaveWorkspace',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_is93p8g5.LeaveCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .leaveWorkspace(
                        session,
                        params['request'],
                      ),
        ),
        'transferOwnership': _is.MethodConnector(
          name: 'transferOwnership',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is
                  .getType<_iz1a25vz.TransferCloudWorkspaceOwnershipRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .transferOwnership(
                        session,
                        params['request'],
                      ),
        ),
        'updateMemberRole': _is.MethodConnector(
          name: 'updateMemberRole',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iekbk1on.UpdateWorkspaceMemberRoleRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .updateMemberRole(
                        session,
                        params['request'],
                      ),
        ),
        'removeMember': _is.MethodConnector(
          name: 'removeMember',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i6zx39if.RemoveWorkspaceMemberRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .removeMember(
                        session,
                        params['request'],
                      ),
        ),
        'deleteWorkspace': _is.MethodConnector(
          name: 'deleteWorkspace',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_imv0e49a.DeleteCloudWorkspaceRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['cloudWorkspace']
                          as _ij5poshv.CloudWorkspaceEndpoint)
                      .deleteWorkspace(
                        session,
                        params['request'],
                      ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
  }
}
