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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i4;
import 'features/accounts/models/account_summary.dart' as _i5;
import 'features/codex_oauth/models/codex_oauth_transaction.dart' as _i6;
import 'features/codex_oauth/models/complete_codex_oauth_request.dart' as _i7;
import 'features/codex_oauth/models/complete_codex_oauth_result.dart' as _i8;
import 'features/codex_oauth/models/start_codex_oauth_request.dart' as _i9;
import 'features/codex_oauth/models/start_codex_oauth_result.dart' as _i10;
import 'features/conversations/models/cancel_turn_request.dart' as _i11;
import 'features/conversations/models/compact_conversation_request.dart'
    as _i12;
import 'features/conversations/models/continue_turn_request.dart' as _i13;
import 'features/conversations/models/conversation.dart' as _i14;
import 'features/conversations/models/conversation_error_code.dart' as _i15;
import 'features/conversations/models/conversation_exception.dart' as _i16;
import 'features/conversations/models/conversation_job.dart' as _i17;
import 'features/conversations/models/conversation_message.dart' as _i18;
import 'features/conversations/models/conversation_message_view.dart' as _i19;
import 'features/conversations/models/conversation_mutation_result.dart'
    as _i20;
import 'features/conversations/models/conversation_page.dart' as _i21;
import 'features/conversations/models/conversation_summary.dart' as _i22;
import 'features/conversations/models/conversation_tool_call.dart' as _i23;
import 'features/conversations/models/conversation_tool_call_view.dart' as _i24;
import 'features/conversations/models/conversation_turn.dart' as _i25;
import 'features/conversations/models/conversation_turn_view.dart' as _i26;
import 'features/conversations/models/conversation_usage.dart' as _i27;
import 'features/conversations/models/create_conversation_request.dart' as _i28;
import 'features/conversations/models/delete_conversation_request.dart' as _i29;
import 'features/conversations/models/get_conversation_request.dart' as _i30;
import 'features/conversations/models/get_turn_request.dart' as _i31;
import 'features/conversations/models/list_conversation_messages_request.dart'
    as _i32;
import 'features/conversations/models/list_conversations_request.dart' as _i33;
import 'features/conversations/models/live_turn_event.dart' as _i34;
import 'features/conversations/models/live_turn_event_kind.dart' as _i35;
import 'features/conversations/models/live_turn_subscribe_request.dart' as _i36;
import 'features/conversations/models/provider_admission.dart' as _i37;
import 'features/conversations/models/provider_admission_lock.dart' as _i38;
import 'features/conversations/models/provider_admission_reservation.dart'
    as _i39;
import 'features/conversations/models/start_turn_request.dart' as _i40;
import 'features/conversations/models/start_turn_result.dart' as _i41;
import 'features/conversations/models/submit_tool_decision_request.dart'
    as _i42;
import 'features/conversations/models/turn_snapshot.dart' as _i43;
import 'features/conversations/models/update_conversation_request.dart' as _i44;
import 'features/mcp_servers/models/create_mcp_server_request.dart' as _i45;
import 'features/mcp_servers/models/create_mcp_server_result.dart' as _i46;
import 'features/mcp_servers/models/delete_mcp_server_request.dart' as _i47;
import 'features/mcp_servers/models/discover_mcp_server_request.dart' as _i48;
import 'features/mcp_servers/models/discover_mcp_server_result.dart' as _i49;
import 'features/mcp_servers/models/discovered_mcp_tool.dart' as _i50;
import 'features/mcp_servers/models/mcp_server_health.dart' as _i51;
import 'features/model_connections/models/api_model.dart' as _i52;
import 'features/model_connections/models/api_model_provider.dart' as _i53;
import 'features/model_connections/models/create_model_connection_request.dart'
    as _i54;
import 'features/model_connections/models/delete_model_connection_request.dart'
    as _i55;
import 'features/model_connections/models/list_model_connections_request.dart'
    as _i56;
import 'features/model_connections/models/list_workspace_model_selections_request.dart'
    as _i57;
import 'features/model_connections/models/model_connection_view.dart' as _i58;
import 'features/model_connections/models/model_sync_result.dart' as _i59;
import 'features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _i60;
import 'features/model_connections/models/update_model_connection_request.dart'
    as _i61;
import 'features/model_connections/models/workspace_model_connection.dart'
    as _i62;
import 'features/model_connections/models/workspace_model_selection_view.dart'
    as _i63;
import 'features/objects/models/begin_upload_request.dart' as _i64;
import 'features/objects/models/begin_upload_result.dart' as _i65;
import 'features/objects/models/complete_upload_request.dart' as _i66;
import 'features/objects/models/delete_object_request.dart' as _i67;
import 'features/objects/models/get_download_request.dart' as _i68;
import 'features/objects/models/get_download_result.dart' as _i69;
import 'features/objects/models/object_deletion.dart' as _i70;
import 'features/objects/models/object_error_code.dart' as _i71;
import 'features/objects/models/object_exception.dart' as _i72;
import 'features/objects/models/object_reference.dart' as _i73;
import 'features/objects/models/object_result.dart' as _i74;
import 'features/objects/models/object_upload.dart' as _i75;
import 'features/objects/models/workspace_object.dart' as _i76;
import 'features/sync/stream/models/workspace_stream_envelope.dart' as _i77;
import 'features/sync/stream/models/workspace_stream_envelope_kind.dart'
    as _i78;
import 'features/sync/stream/models/workspace_subscribe_request.dart' as _i79;
import 'features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _i80;
import 'features/workspace_state/models/mutate_workspace_credential_response.dart'
    as _i81;
import 'features/workspace_state/models/patch_workspace_state_request.dart'
    as _i82;
import 'features/workspace_state/models/patch_workspace_state_response.dart'
    as _i83;
import 'features/workspace_state/models/put_workspace_secret_request.dart'
    as _i84;
import 'features/workspace_state/models/put_workspace_secret_response.dart'
    as _i85;
import 'features/workspace_state/models/read_workspace_state_request.dart'
    as _i86;
import 'features/workspace_state/models/read_workspace_state_response.dart'
    as _i87;
import 'features/workspace_state/models/workspace_patch_operation.dart' as _i88;
import 'features/workspace_state/models/workspace_patch_operation_kind.dart'
    as _i89;
import 'features/workspace_state/models/workspace_resource.dart' as _i90;
import 'features/workspace_state/models/workspace_resource_kind.dart' as _i91;
import 'features/workspace_state/models/workspace_resource_page.dart' as _i92;
import 'features/workspace_state/models/workspace_resource_page_request.dart'
    as _i93;
import 'features/workspace_state/models/workspace_secret.dart' as _i94;
import 'features/workspace_state/models/workspace_secret_kind.dart' as _i95;
import 'features/workspace_state/models/workspace_secret_scope.dart' as _i96;
import 'features/workspaces/models/accept_workspace_invite_request.dart'
    as _i97;
import 'features/workspaces/models/cloud_workspace.dart' as _i98;
import 'features/workspaces/models/cloud_workspace_capabilities.dart' as _i99;
import 'features/workspaces/models/cloud_workspace_detail.dart' as _i100;
import 'features/workspaces/models/cloud_workspace_error_code.dart' as _i101;
import 'features/workspaces/models/cloud_workspace_exception.dart' as _i102;
import 'features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i103;
import 'features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i104;
import 'features/workspaces/models/cloud_workspace_summary.dart' as _i105;
import 'features/workspaces/models/create_cloud_workspace_request.dart'
    as _i106;
import 'features/workspaces/models/decline_workspace_invite_request.dart'
    as _i107;
import 'features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i108;
import 'features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i109;
import 'features/workspaces/models/invite_workspace_member_request.dart'
    as _i110;
import 'features/workspaces/models/leave_cloud_workspace_request.dart' as _i111;
import 'features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i112;
import 'features/workspaces/models/list_workspace_members_request.dart'
    as _i113;
import 'features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i114;
import 'features/workspaces/models/remove_workspace_member_request.dart'
    as _i115;
import 'features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i116;
import 'features/workspaces/models/renew_workspace_invite_request.dart'
    as _i117;
import 'features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i118;
import 'features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i119;
import 'features/workspaces/models/update_workspace_member_role_request.dart'
    as _i120;
import 'features/workspaces/models/workspace_audit_record.dart' as _i121;
import 'features/workspaces/models/workspace_event.dart' as _i122;
import 'features/workspaces/models/workspace_invite.dart' as _i123;
import 'features/workspaces/models/workspace_member.dart' as _i124;
import 'features/workspaces/models/workspace_mutation_receipt.dart' as _i125;
import 'package:auravibes_server/src/generated/features/conversations/models/conversation_summary.dart'
    as _i126;
import 'package:auravibes_server/src/generated/features/conversations/models/conversation_message_view.dart'
    as _i127;
import 'package:auravibes_server/src/generated/features/model_connections/models/api_model_provider.dart'
    as _i128;
import 'package:auravibes_server/src/generated/features/model_connections/models/api_model.dart'
    as _i129;
import 'package:auravibes_server/src/generated/features/model_connections/models/model_connection_view.dart'
    as _i130;
import 'package:auravibes_server/src/generated/features/model_connections/models/workspace_model_selection_view.dart'
    as _i131;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_summary.dart'
    as _i132;
import 'package:auravibes_server/src/generated/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i133;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i134;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i135;
export 'features/accounts/models/account_summary.dart';
export 'features/codex_oauth/models/codex_oauth_transaction.dart';
export 'features/codex_oauth/models/complete_codex_oauth_request.dart';
export 'features/codex_oauth/models/complete_codex_oauth_result.dart';
export 'features/codex_oauth/models/start_codex_oauth_request.dart';
export 'features/codex_oauth/models/start_codex_oauth_result.dart';
export 'features/conversations/models/cancel_turn_request.dart';
export 'features/conversations/models/compact_conversation_request.dart';
export 'features/conversations/models/continue_turn_request.dart';
export 'features/conversations/models/conversation.dart';
export 'features/conversations/models/conversation_error_code.dart';
export 'features/conversations/models/conversation_exception.dart';
export 'features/conversations/models/conversation_job.dart';
export 'features/conversations/models/conversation_message.dart';
export 'features/conversations/models/conversation_message_view.dart';
export 'features/conversations/models/conversation_mutation_result.dart';
export 'features/conversations/models/conversation_page.dart';
export 'features/conversations/models/conversation_summary.dart';
export 'features/conversations/models/conversation_tool_call.dart';
export 'features/conversations/models/conversation_tool_call_view.dart';
export 'features/conversations/models/conversation_turn.dart';
export 'features/conversations/models/conversation_turn_view.dart';
export 'features/conversations/models/conversation_usage.dart';
export 'features/conversations/models/create_conversation_request.dart';
export 'features/conversations/models/delete_conversation_request.dart';
export 'features/conversations/models/get_conversation_request.dart';
export 'features/conversations/models/get_turn_request.dart';
export 'features/conversations/models/list_conversation_messages_request.dart';
export 'features/conversations/models/list_conversations_request.dart';
export 'features/conversations/models/live_turn_event.dart';
export 'features/conversations/models/live_turn_event_kind.dart';
export 'features/conversations/models/live_turn_subscribe_request.dart';
export 'features/conversations/models/provider_admission.dart';
export 'features/conversations/models/provider_admission_lock.dart';
export 'features/conversations/models/provider_admission_reservation.dart';
export 'features/conversations/models/start_turn_request.dart';
export 'features/conversations/models/start_turn_result.dart';
export 'features/conversations/models/submit_tool_decision_request.dart';
export 'features/conversations/models/turn_snapshot.dart';
export 'features/conversations/models/update_conversation_request.dart';
export 'features/mcp_servers/models/create_mcp_server_request.dart';
export 'features/mcp_servers/models/create_mcp_server_result.dart';
export 'features/mcp_servers/models/delete_mcp_server_request.dart';
export 'features/mcp_servers/models/discover_mcp_server_request.dart';
export 'features/mcp_servers/models/discover_mcp_server_result.dart';
export 'features/mcp_servers/models/discovered_mcp_tool.dart';
export 'features/mcp_servers/models/mcp_server_health.dart';
export 'features/model_connections/models/api_model.dart';
export 'features/model_connections/models/api_model_provider.dart';
export 'features/model_connections/models/create_model_connection_request.dart';
export 'features/model_connections/models/delete_model_connection_request.dart';
export 'features/model_connections/models/list_model_connections_request.dart';
export 'features/model_connections/models/list_workspace_model_selections_request.dart';
export 'features/model_connections/models/model_connection_view.dart';
export 'features/model_connections/models/model_sync_result.dart';
export 'features/model_connections/models/test_and_sync_model_connection_request.dart';
export 'features/model_connections/models/update_model_connection_request.dart';
export 'features/model_connections/models/workspace_model_connection.dart';
export 'features/model_connections/models/workspace_model_selection_view.dart';
export 'features/objects/models/begin_upload_request.dart';
export 'features/objects/models/begin_upload_result.dart';
export 'features/objects/models/complete_upload_request.dart';
export 'features/objects/models/delete_object_request.dart';
export 'features/objects/models/get_download_request.dart';
export 'features/objects/models/get_download_result.dart';
export 'features/objects/models/object_deletion.dart';
export 'features/objects/models/object_error_code.dart';
export 'features/objects/models/object_exception.dart';
export 'features/objects/models/object_reference.dart';
export 'features/objects/models/object_result.dart';
export 'features/objects/models/object_upload.dart';
export 'features/objects/models/workspace_object.dart';
export 'features/sync/stream/models/workspace_stream_envelope.dart';
export 'features/sync/stream/models/workspace_stream_envelope_kind.dart';
export 'features/sync/stream/models/workspace_subscribe_request.dart';
export 'features/workspace_state/models/mutate_workspace_credential_request.dart';
export 'features/workspace_state/models/mutate_workspace_credential_response.dart';
export 'features/workspace_state/models/patch_workspace_state_request.dart';
export 'features/workspace_state/models/patch_workspace_state_response.dart';
export 'features/workspace_state/models/put_workspace_secret_request.dart';
export 'features/workspace_state/models/put_workspace_secret_response.dart';
export 'features/workspace_state/models/read_workspace_state_request.dart';
export 'features/workspace_state/models/read_workspace_state_response.dart';
export 'features/workspace_state/models/workspace_patch_operation.dart';
export 'features/workspace_state/models/workspace_patch_operation_kind.dart';
export 'features/workspace_state/models/workspace_resource.dart';
export 'features/workspace_state/models/workspace_resource_kind.dart';
export 'features/workspace_state/models/workspace_resource_page.dart';
export 'features/workspace_state/models/workspace_resource_page_request.dart';
export 'features/workspace_state/models/workspace_secret.dart';
export 'features/workspace_state/models/workspace_secret_kind.dart';
export 'features/workspace_state/models/workspace_secret_scope.dart';
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
export 'features/workspaces/models/workspace_audit_record.dart';
export 'features/workspaces/models/workspace_event.dart';
export 'features/workspaces/models/workspace_invite.dart';
export 'features/workspaces/models/workspace_member.dart';
export 'features/workspaces/models/workspace_mutation_receipt.dart';

class Protocol extends _i1.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'api_model',
      dartName: 'ApiModel',
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
          name: 'providerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'modelId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'limitContext',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'limitOutput',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'modalitiesInput',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _i2.ColumnDefinition(
          name: 'modalitiesOutput',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _i2.ColumnDefinition(
          name: 'family',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'costInput',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'costCacheRead',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'costOutput',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'openWeights',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'supportsReasoning',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'isCanonical',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'supportsPriorityMode',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'supportsToolCalls',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
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
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'api_model_provider_model_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'providerId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'modelId',
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
      name: 'api_model_provider',
      dartName: 'ApiModelProvider',
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
          name: 'providerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'url',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'documentationUrl',
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
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'api_model_provider_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'providerId',
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
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      name: 'codex_oauth_transaction',
      dartName: 'CodexOAuthTransaction',
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
          name: 'transactionId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'connectionId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'stateHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'verifierCiphertext',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'verifierNonce',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'verifierAuthenticationTag',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'redirectUri',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'consumedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'codex_oauth_transaction_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'transactionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'codex_oauth_transaction_expiry_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'conversation',
      dartName: 'Conversation',
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
          name: 'stableId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isPinned',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'modelId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'agentId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'parentConversationStableId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_workspace_stable_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'stableId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_workspace_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_workspace_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
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
      name: 'conversation_job',
      dartName: 'ConversationJob',
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
          name: 'conversationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'turnId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'payloadJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'attempt',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'maxAttempts',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'availableAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'leaseOwner',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'leaseToken',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'leaseExpiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'checkpointJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'lastErrorCode',
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
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_job_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_job_fk_1',
          columns: ['conversationId'],
          referenceTable: 'conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_job_fk_2',
          columns: ['turnId'],
          referenceTable: 'conversation_turn',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_job_request_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_job_claim_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'availableAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'leaseExpiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_job_turn_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'turnId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'conversation_message',
      dartName: 'ConversationMessage',
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
          name: 'conversationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'stableId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'turnId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'content',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'metadataJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'compactedThroughMessageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_message_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_message_fk_1',
          columns: ['conversationId'],
          referenceTable: 'conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_message_fk_2',
          columns: ['turnId'],
          referenceTable: 'conversation_turn',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_message_stable_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'stableId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_message_order_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'conversationId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_message_turn_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'turnId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_message_workspace_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
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
      name: 'conversation_tool_call',
      dartName: 'ConversationToolCall',
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
          name: 'conversationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'turnId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'messageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'stableId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'argumentsJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'argumentsDigest',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'decision',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'decisionByUserId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'decisionAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'resultJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_tool_call_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_tool_call_fk_1',
          columns: ['conversationId'],
          referenceTable: 'conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_tool_call_fk_2',
          columns: ['turnId'],
          referenceTable: 'conversation_turn',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_tool_call_fk_3',
          columns: ['messageId'],
          referenceTable: 'conversation_message',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_tool_call_stable_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'stableId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_tool_call_turn_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'turnId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'conversation_turn',
      dartName: 'ConversationTurn',
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
          name: 'conversationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'initiatorUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userMessageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'assistantMessageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'acceptedSequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'cancellationRequestedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'terminalAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_turn_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_turn_fk_1',
          columns: ['conversationId'],
          referenceTable: 'conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_turn_fk_2',
          columns: ['userMessageId'],
          referenceTable: 'conversation_message',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_turn_fk_3',
          columns: ['assistantMessageId'],
          referenceTable: 'conversation_message',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_turn_request_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_turn_conversation_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'conversationId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conversation_turn_workspace_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
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
      name: 'conversation_usage',
      dartName: 'ConversationUsage',
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
          name: 'conversationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'turnId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'inputTokens',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'outputTokens',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'totalTokens',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_usage_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_usage_fk_1',
          columns: ['conversationId'],
          referenceTable: 'conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'conversation_usage_fk_2',
          columns: ['turnId'],
          referenceTable: 'conversation_turn',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conversation_usage_turn_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'turnId',
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
      name: 'object_deletion',
      dartName: 'ObjectDeletion',
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
          name: 'objectId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'objectKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expectedRevision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'requestedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'attempts',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'availableAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastError',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'object_deletion_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'object_deletion_fk_1',
          columns: ['objectId'],
          referenceTable: 'workspace_object',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'object_deletion_object_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'objectId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'object_deletion_request_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'object_deletion_pending_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'completedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'object_reference',
      dartName: 'ObjectReference',
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
          name: 'objectId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'messageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
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
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'object_reference_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'object_reference_fk_1',
          columns: ['objectId'],
          referenceTable: 'workspace_object',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'object_reference_fk_2',
          columns: ['messageId'],
          referenceTable: 'conversation_message',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'object_reference_message_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'messageId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'objectId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'object_reference_live_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'objectId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'deletedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'object_upload',
      dartName: 'ObjectUpload',
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
          name: 'objectId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'actorUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'object_upload_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'object_upload_fk_1',
          columns: ['objectId'],
          referenceTable: 'workspace_object',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'object_upload_request_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'actorUserId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'object_upload_object_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'objectId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'object_upload_expiry_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'completedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'provider_admission',
      dartName: 'ProviderAdmission',
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
          name: 'jobId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'providerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'leaseToken',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'provider_admission_fk_0',
          columns: ['jobId'],
          referenceTable: 'conversation_job',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'provider_admission_fk_1',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'provider_admission_workspace_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'provider_admission_lock',
      dartName: 'ProviderAdmissionLock',
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
          name: 'key',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'provider_admission_lock_key_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'key',
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
      name: 'provider_admission_reservation',
      dartName: 'ProviderAdmissionReservation',
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
          name: 'jobId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'providerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'leaseToken',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'provider_admission_reservation_fk_0',
          columns: ['jobId'],
          referenceTable: 'conversation_job',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'provider_admission_reservation_fk_1',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'provider_admission_reservation_job_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'jobId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'provider_admission_reservation_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_audit_record',
      dartName: 'WorkspaceAuditRecord',
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
          name: 'sequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'actorUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'operation',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'targetKind',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'targetId',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_audit_record_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_audit_record_workspace_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sequence',
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
      name: 'workspace_event',
      dartName: 'WorkspaceEvent',
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
          name: 'eventId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'actorUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resourceKind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resourceId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'payloadJson',
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
          name: 'publishedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_event_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_event_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_event_sequence_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sequence',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_event_outbox_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publishedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
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
          name: 'normalizedEmail',
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
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_invite_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
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
        _i2.IndexDefinition(
          indexName: 'workspace_invite_email_state_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'normalizedEmail',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'acceptedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'declinedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'revokedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
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
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
          name: 'removedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_member_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
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
        _i2.IndexDefinition(
          indexName: 'workspace_member_user_removed_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'removedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_model_connection',
      dartName: 'WorkspaceModelConnection',
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
          name: 'connectionId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'providerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'url',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'keySuffix',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'hasSecret',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_model_connection_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_model_connection_identity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'connectionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_model_connection_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'deletedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_mutation_receipt',
      dartName: 'WorkspaceMutationReceipt',
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
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'scopeKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'actorUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'endpoint',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'requestHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'responseJson',
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
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_mutation_receipt_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_mutation_receipt_request_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'actorUserId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'scopeKey',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'endpoint',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_mutation_receipt_workspace_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_object',
      dartName: 'WorkspaceObject',
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
          name: 'objectKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'purpose',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mimeType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'checksumSha256',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'workspace_object_fk_0',
          columns: ['workspaceId'],
          referenceTable: 'cloud_workspace',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_object_key_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'objectKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_object_scope_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'deletedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_resource',
      dartName: 'WorkspaceResource',
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
          name: 'resourceKind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WorkspaceResourceKind',
        ),
        _i2.ColumnDefinition(
          name: 'resourceId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'data',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_resource_identity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resourceKind',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resourceId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'workspace_resource_page_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resourceKind',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resourceId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'workspace_secret',
      dartName: 'WorkspaceSecret',
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
          name: 'secretKind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WorkspaceSecretKind',
        ),
        _i2.ColumnDefinition(
          name: 'scope',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WorkspaceSecretScope',
        ),
        _i2.ColumnDefinition(
          name: 'ownerUserId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resourceId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'ciphertext',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'nonce',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'authenticationTag',
          columnType: _i2.ColumnType.bytea,
          isNullable: false,
          dartType: 'dart:typed_data:ByteData',
        ),
        _i2.ColumnDefinition(
          name: 'algorithm',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'keyVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'displaySuffix',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
      indexes: [
        _i2.IndexDefinition(
          indexName: 'workspace_secret_identity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'secretKind',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'scope',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'ownerUserId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resourceId',
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
    if (t == _i6.CodexOAuthTransaction) {
      return _i6.CodexOAuthTransaction.fromJson(data) as T;
    }
    if (t == _i7.CompleteCodexOAuthRequest) {
      return _i7.CompleteCodexOAuthRequest.fromJson(data) as T;
    }
    if (t == _i8.CompleteCodexOAuthResult) {
      return _i8.CompleteCodexOAuthResult.fromJson(data) as T;
    }
    if (t == _i9.StartCodexOAuthRequest) {
      return _i9.StartCodexOAuthRequest.fromJson(data) as T;
    }
    if (t == _i10.StartCodexOAuthResult) {
      return _i10.StartCodexOAuthResult.fromJson(data) as T;
    }
    if (t == _i11.CancelTurnRequest) {
      return _i11.CancelTurnRequest.fromJson(data) as T;
    }
    if (t == _i12.CompactConversationRequest) {
      return _i12.CompactConversationRequest.fromJson(data) as T;
    }
    if (t == _i13.ContinueTurnRequest) {
      return _i13.ContinueTurnRequest.fromJson(data) as T;
    }
    if (t == _i14.Conversation) {
      return _i14.Conversation.fromJson(data) as T;
    }
    if (t == _i15.ConversationErrorCode) {
      return _i15.ConversationErrorCode.fromJson(data) as T;
    }
    if (t == _i16.ConversationException) {
      return _i16.ConversationException.fromJson(data) as T;
    }
    if (t == _i17.ConversationJob) {
      return _i17.ConversationJob.fromJson(data) as T;
    }
    if (t == _i18.ConversationMessage) {
      return _i18.ConversationMessage.fromJson(data) as T;
    }
    if (t == _i19.ConversationMessageView) {
      return _i19.ConversationMessageView.fromJson(data) as T;
    }
    if (t == _i20.ConversationMutationResult) {
      return _i20.ConversationMutationResult.fromJson(data) as T;
    }
    if (t == _i21.ConversationPage) {
      return _i21.ConversationPage.fromJson(data) as T;
    }
    if (t == _i22.ConversationSummary) {
      return _i22.ConversationSummary.fromJson(data) as T;
    }
    if (t == _i23.ConversationToolCall) {
      return _i23.ConversationToolCall.fromJson(data) as T;
    }
    if (t == _i24.ConversationToolCallView) {
      return _i24.ConversationToolCallView.fromJson(data) as T;
    }
    if (t == _i25.ConversationTurn) {
      return _i25.ConversationTurn.fromJson(data) as T;
    }
    if (t == _i26.ConversationTurnView) {
      return _i26.ConversationTurnView.fromJson(data) as T;
    }
    if (t == _i27.ConversationUsage) {
      return _i27.ConversationUsage.fromJson(data) as T;
    }
    if (t == _i28.CreateConversationRequest) {
      return _i28.CreateConversationRequest.fromJson(data) as T;
    }
    if (t == _i29.DeleteConversationRequest) {
      return _i29.DeleteConversationRequest.fromJson(data) as T;
    }
    if (t == _i30.GetConversationRequest) {
      return _i30.GetConversationRequest.fromJson(data) as T;
    }
    if (t == _i31.GetTurnRequest) {
      return _i31.GetTurnRequest.fromJson(data) as T;
    }
    if (t == _i32.ListConversationMessagesRequest) {
      return _i32.ListConversationMessagesRequest.fromJson(data) as T;
    }
    if (t == _i33.ListConversationsRequest) {
      return _i33.ListConversationsRequest.fromJson(data) as T;
    }
    if (t == _i34.LiveTurnEvent) {
      return _i34.LiveTurnEvent.fromJson(data) as T;
    }
    if (t == _i35.LiveTurnEventKind) {
      return _i35.LiveTurnEventKind.fromJson(data) as T;
    }
    if (t == _i36.LiveTurnSubscribeRequest) {
      return _i36.LiveTurnSubscribeRequest.fromJson(data) as T;
    }
    if (t == _i37.ProviderAdmission) {
      return _i37.ProviderAdmission.fromJson(data) as T;
    }
    if (t == _i38.ProviderAdmissionLock) {
      return _i38.ProviderAdmissionLock.fromJson(data) as T;
    }
    if (t == _i39.ProviderAdmissionReservation) {
      return _i39.ProviderAdmissionReservation.fromJson(data) as T;
    }
    if (t == _i40.StartTurnRequest) {
      return _i40.StartTurnRequest.fromJson(data) as T;
    }
    if (t == _i41.StartTurnResult) {
      return _i41.StartTurnResult.fromJson(data) as T;
    }
    if (t == _i42.SubmitToolDecisionRequest) {
      return _i42.SubmitToolDecisionRequest.fromJson(data) as T;
    }
    if (t == _i43.TurnSnapshot) {
      return _i43.TurnSnapshot.fromJson(data) as T;
    }
    if (t == _i44.UpdateConversationRequest) {
      return _i44.UpdateConversationRequest.fromJson(data) as T;
    }
    if (t == _i45.CreateMcpServerRequest) {
      return _i45.CreateMcpServerRequest.fromJson(data) as T;
    }
    if (t == _i46.CreateMcpServerResult) {
      return _i46.CreateMcpServerResult.fromJson(data) as T;
    }
    if (t == _i47.DeleteMcpServerRequest) {
      return _i47.DeleteMcpServerRequest.fromJson(data) as T;
    }
    if (t == _i48.DiscoverMcpServerRequest) {
      return _i48.DiscoverMcpServerRequest.fromJson(data) as T;
    }
    if (t == _i49.DiscoverMcpServerResult) {
      return _i49.DiscoverMcpServerResult.fromJson(data) as T;
    }
    if (t == _i50.DiscoveredMcpTool) {
      return _i50.DiscoveredMcpTool.fromJson(data) as T;
    }
    if (t == _i51.McpServerHealth) {
      return _i51.McpServerHealth.fromJson(data) as T;
    }
    if (t == _i52.ApiModel) {
      return _i52.ApiModel.fromJson(data) as T;
    }
    if (t == _i53.ApiModelProvider) {
      return _i53.ApiModelProvider.fromJson(data) as T;
    }
    if (t == _i54.CreateModelConnectionRequest) {
      return _i54.CreateModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _i55.DeleteModelConnectionRequest) {
      return _i55.DeleteModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _i56.ListModelConnectionsRequest) {
      return _i56.ListModelConnectionsRequest.fromJson(data) as T;
    }
    if (t == _i57.ListWorkspaceModelSelectionsRequest) {
      return _i57.ListWorkspaceModelSelectionsRequest.fromJson(data) as T;
    }
    if (t == _i58.ModelConnectionView) {
      return _i58.ModelConnectionView.fromJson(data) as T;
    }
    if (t == _i59.ModelSyncResult) {
      return _i59.ModelSyncResult.fromJson(data) as T;
    }
    if (t == _i60.TestAndSyncModelConnectionRequest) {
      return _i60.TestAndSyncModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _i61.UpdateModelConnectionRequest) {
      return _i61.UpdateModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _i62.WorkspaceModelConnection) {
      return _i62.WorkspaceModelConnection.fromJson(data) as T;
    }
    if (t == _i63.WorkspaceModelSelectionView) {
      return _i63.WorkspaceModelSelectionView.fromJson(data) as T;
    }
    if (t == _i64.BeginUploadRequest) {
      return _i64.BeginUploadRequest.fromJson(data) as T;
    }
    if (t == _i65.BeginUploadResult) {
      return _i65.BeginUploadResult.fromJson(data) as T;
    }
    if (t == _i66.CompleteUploadRequest) {
      return _i66.CompleteUploadRequest.fromJson(data) as T;
    }
    if (t == _i67.DeleteObjectRequest) {
      return _i67.DeleteObjectRequest.fromJson(data) as T;
    }
    if (t == _i68.GetDownloadRequest) {
      return _i68.GetDownloadRequest.fromJson(data) as T;
    }
    if (t == _i69.GetDownloadResult) {
      return _i69.GetDownloadResult.fromJson(data) as T;
    }
    if (t == _i70.ObjectDeletion) {
      return _i70.ObjectDeletion.fromJson(data) as T;
    }
    if (t == _i71.ObjectErrorCode) {
      return _i71.ObjectErrorCode.fromJson(data) as T;
    }
    if (t == _i72.ObjectException) {
      return _i72.ObjectException.fromJson(data) as T;
    }
    if (t == _i73.ObjectReference) {
      return _i73.ObjectReference.fromJson(data) as T;
    }
    if (t == _i74.ObjectResult) {
      return _i74.ObjectResult.fromJson(data) as T;
    }
    if (t == _i75.ObjectUpload) {
      return _i75.ObjectUpload.fromJson(data) as T;
    }
    if (t == _i76.WorkspaceObject) {
      return _i76.WorkspaceObject.fromJson(data) as T;
    }
    if (t == _i77.WorkspaceStreamEnvelope) {
      return _i77.WorkspaceStreamEnvelope.fromJson(data) as T;
    }
    if (t == _i78.WorkspaceStreamEnvelopeKind) {
      return _i78.WorkspaceStreamEnvelopeKind.fromJson(data) as T;
    }
    if (t == _i79.WorkspaceSubscribeRequest) {
      return _i79.WorkspaceSubscribeRequest.fromJson(data) as T;
    }
    if (t == _i80.MutateWorkspaceCredentialRequest) {
      return _i80.MutateWorkspaceCredentialRequest.fromJson(data) as T;
    }
    if (t == _i81.MutateWorkspaceCredentialResponse) {
      return _i81.MutateWorkspaceCredentialResponse.fromJson(data) as T;
    }
    if (t == _i82.PatchWorkspaceStateRequest) {
      return _i82.PatchWorkspaceStateRequest.fromJson(data) as T;
    }
    if (t == _i83.PatchWorkspaceStateResponse) {
      return _i83.PatchWorkspaceStateResponse.fromJson(data) as T;
    }
    if (t == _i84.PutWorkspaceSecretRequest) {
      return _i84.PutWorkspaceSecretRequest.fromJson(data) as T;
    }
    if (t == _i85.PutWorkspaceSecretResponse) {
      return _i85.PutWorkspaceSecretResponse.fromJson(data) as T;
    }
    if (t == _i86.ReadWorkspaceStateRequest) {
      return _i86.ReadWorkspaceStateRequest.fromJson(data) as T;
    }
    if (t == _i87.ReadWorkspaceStateResponse) {
      return _i87.ReadWorkspaceStateResponse.fromJson(data) as T;
    }
    if (t == _i88.WorkspacePatchOperation) {
      return _i88.WorkspacePatchOperation.fromJson(data) as T;
    }
    if (t == _i89.WorkspacePatchOperationKind) {
      return _i89.WorkspacePatchOperationKind.fromJson(data) as T;
    }
    if (t == _i90.WorkspaceResource) {
      return _i90.WorkspaceResource.fromJson(data) as T;
    }
    if (t == _i91.WorkspaceResourceKind) {
      return _i91.WorkspaceResourceKind.fromJson(data) as T;
    }
    if (t == _i92.WorkspaceResourcePage) {
      return _i92.WorkspaceResourcePage.fromJson(data) as T;
    }
    if (t == _i93.WorkspaceResourcePageRequest) {
      return _i93.WorkspaceResourcePageRequest.fromJson(data) as T;
    }
    if (t == _i94.WorkspaceSecret) {
      return _i94.WorkspaceSecret.fromJson(data) as T;
    }
    if (t == _i95.WorkspaceSecretKind) {
      return _i95.WorkspaceSecretKind.fromJson(data) as T;
    }
    if (t == _i96.WorkspaceSecretScope) {
      return _i96.WorkspaceSecretScope.fromJson(data) as T;
    }
    if (t == _i97.AcceptWorkspaceInviteRequest) {
      return _i97.AcceptWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i98.CloudWorkspace) {
      return _i98.CloudWorkspace.fromJson(data) as T;
    }
    if (t == _i99.CloudWorkspaceCapabilities) {
      return _i99.CloudWorkspaceCapabilities.fromJson(data) as T;
    }
    if (t == _i100.CloudWorkspaceDetail) {
      return _i100.CloudWorkspaceDetail.fromJson(data) as T;
    }
    if (t == _i101.CloudWorkspaceErrorCode) {
      return _i101.CloudWorkspaceErrorCode.fromJson(data) as T;
    }
    if (t == _i102.CloudWorkspaceException) {
      return _i102.CloudWorkspaceException.fromJson(data) as T;
    }
    if (t == _i103.CloudWorkspaceInviteSummary) {
      return _i103.CloudWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i104.CloudWorkspaceMemberSummary) {
      return _i104.CloudWorkspaceMemberSummary.fromJson(data) as T;
    }
    if (t == _i105.CloudWorkspaceSummary) {
      return _i105.CloudWorkspaceSummary.fromJson(data) as T;
    }
    if (t == _i106.CreateCloudWorkspaceRequest) {
      return _i106.CreateCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i107.DeclineWorkspaceInviteRequest) {
      return _i107.DeclineWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i108.DeleteCloudWorkspaceRequest) {
      return _i108.DeleteCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i109.GetCloudWorkspaceDetailRequest) {
      return _i109.GetCloudWorkspaceDetailRequest.fromJson(data) as T;
    }
    if (t == _i110.InviteWorkspaceMemberRequest) {
      return _i110.InviteWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i111.LeaveCloudWorkspaceRequest) {
      return _i111.LeaveCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i112.ListCloudWorkspaceInvitesRequest) {
      return _i112.ListCloudWorkspaceInvitesRequest.fromJson(data) as T;
    }
    if (t == _i113.ListWorkspaceMembersRequest) {
      return _i113.ListWorkspaceMembersRequest.fromJson(data) as T;
    }
    if (t == _i114.PendingWorkspaceInviteSummary) {
      return _i114.PendingWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i115.RemoveWorkspaceMemberRequest) {
      return _i115.RemoveWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i116.RenameCloudWorkspaceRequest) {
      return _i116.RenameCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i117.RenewWorkspaceInviteRequest) {
      return _i117.RenewWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i118.RevokeWorkspaceInviteRequest) {
      return _i118.RevokeWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i119.TransferCloudWorkspaceOwnershipRequest) {
      return _i119.TransferCloudWorkspaceOwnershipRequest.fromJson(data) as T;
    }
    if (t == _i120.UpdateWorkspaceMemberRoleRequest) {
      return _i120.UpdateWorkspaceMemberRoleRequest.fromJson(data) as T;
    }
    if (t == _i121.WorkspaceAuditRecord) {
      return _i121.WorkspaceAuditRecord.fromJson(data) as T;
    }
    if (t == _i122.WorkspaceEvent) {
      return _i122.WorkspaceEvent.fromJson(data) as T;
    }
    if (t == _i123.WorkspaceInvite) {
      return _i123.WorkspaceInvite.fromJson(data) as T;
    }
    if (t == _i124.WorkspaceMember) {
      return _i124.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i125.WorkspaceMutationReceipt) {
      return _i125.WorkspaceMutationReceipt.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AccountSummary?>()) {
      return (data != null ? _i5.AccountSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.CodexOAuthTransaction?>()) {
      return (data != null ? _i6.CodexOAuthTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.CompleteCodexOAuthRequest?>()) {
      return (data != null
              ? _i7.CompleteCodexOAuthRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i8.CompleteCodexOAuthResult?>()) {
      return (data != null ? _i8.CompleteCodexOAuthResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.StartCodexOAuthRequest?>()) {
      return (data != null ? _i9.StartCodexOAuthRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.StartCodexOAuthResult?>()) {
      return (data != null ? _i10.StartCodexOAuthResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.CancelTurnRequest?>()) {
      return (data != null ? _i11.CancelTurnRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.CompactConversationRequest?>()) {
      return (data != null
              ? _i12.CompactConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.ContinueTurnRequest?>()) {
      return (data != null ? _i13.ContinueTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.Conversation?>()) {
      return (data != null ? _i14.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ConversationErrorCode?>()) {
      return (data != null ? _i15.ConversationErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.ConversationException?>()) {
      return (data != null ? _i16.ConversationException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.ConversationJob?>()) {
      return (data != null ? _i17.ConversationJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ConversationMessage?>()) {
      return (data != null ? _i18.ConversationMessage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.ConversationMessageView?>()) {
      return (data != null ? _i19.ConversationMessageView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.ConversationMutationResult?>()) {
      return (data != null
              ? _i20.ConversationMutationResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.ConversationPage?>()) {
      return (data != null ? _i21.ConversationPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.ConversationSummary?>()) {
      return (data != null ? _i22.ConversationSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.ConversationToolCall?>()) {
      return (data != null ? _i23.ConversationToolCall.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.ConversationToolCallView?>()) {
      return (data != null
              ? _i24.ConversationToolCallView.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.ConversationTurn?>()) {
      return (data != null ? _i25.ConversationTurn.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ConversationTurnView?>()) {
      return (data != null ? _i26.ConversationTurnView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.ConversationUsage?>()) {
      return (data != null ? _i27.ConversationUsage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.CreateConversationRequest?>()) {
      return (data != null
              ? _i28.CreateConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i29.DeleteConversationRequest?>()) {
      return (data != null
              ? _i29.DeleteConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i30.GetConversationRequest?>()) {
      return (data != null ? _i30.GetConversationRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.GetTurnRequest?>()) {
      return (data != null ? _i31.GetTurnRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.ListConversationMessagesRequest?>()) {
      return (data != null
              ? _i32.ListConversationMessagesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i33.ListConversationsRequest?>()) {
      return (data != null
              ? _i33.ListConversationsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i34.LiveTurnEvent?>()) {
      return (data != null ? _i34.LiveTurnEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.LiveTurnEventKind?>()) {
      return (data != null ? _i35.LiveTurnEventKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.LiveTurnSubscribeRequest?>()) {
      return (data != null
              ? _i36.LiveTurnSubscribeRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i37.ProviderAdmission?>()) {
      return (data != null ? _i37.ProviderAdmission.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.ProviderAdmissionLock?>()) {
      return (data != null ? _i38.ProviderAdmissionLock.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i39.ProviderAdmissionReservation?>()) {
      return (data != null
              ? _i39.ProviderAdmissionReservation.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i40.StartTurnRequest?>()) {
      return (data != null ? _i40.StartTurnRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.StartTurnResult?>()) {
      return (data != null ? _i41.StartTurnResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.SubmitToolDecisionRequest?>()) {
      return (data != null
              ? _i42.SubmitToolDecisionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i43.TurnSnapshot?>()) {
      return (data != null ? _i43.TurnSnapshot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.UpdateConversationRequest?>()) {
      return (data != null
              ? _i44.UpdateConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i45.CreateMcpServerRequest?>()) {
      return (data != null ? _i45.CreateMcpServerRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i46.CreateMcpServerResult?>()) {
      return (data != null ? _i46.CreateMcpServerResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i47.DeleteMcpServerRequest?>()) {
      return (data != null ? _i47.DeleteMcpServerRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i48.DiscoverMcpServerRequest?>()) {
      return (data != null
              ? _i48.DiscoverMcpServerRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i49.DiscoverMcpServerResult?>()) {
      return (data != null ? _i49.DiscoverMcpServerResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i50.DiscoveredMcpTool?>()) {
      return (data != null ? _i50.DiscoveredMcpTool.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.McpServerHealth?>()) {
      return (data != null ? _i51.McpServerHealth.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.ApiModel?>()) {
      return (data != null ? _i52.ApiModel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i53.ApiModelProvider?>()) {
      return (data != null ? _i53.ApiModelProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.CreateModelConnectionRequest?>()) {
      return (data != null
              ? _i54.CreateModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i55.DeleteModelConnectionRequest?>()) {
      return (data != null
              ? _i55.DeleteModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i56.ListModelConnectionsRequest?>()) {
      return (data != null
              ? _i56.ListModelConnectionsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i57.ListWorkspaceModelSelectionsRequest?>()) {
      return (data != null
              ? _i57.ListWorkspaceModelSelectionsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i58.ModelConnectionView?>()) {
      return (data != null ? _i58.ModelConnectionView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i59.ModelSyncResult?>()) {
      return (data != null ? _i59.ModelSyncResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i60.TestAndSyncModelConnectionRequest?>()) {
      return (data != null
              ? _i60.TestAndSyncModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i61.UpdateModelConnectionRequest?>()) {
      return (data != null
              ? _i61.UpdateModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i62.WorkspaceModelConnection?>()) {
      return (data != null
              ? _i62.WorkspaceModelConnection.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i63.WorkspaceModelSelectionView?>()) {
      return (data != null
              ? _i63.WorkspaceModelSelectionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i64.BeginUploadRequest?>()) {
      return (data != null ? _i64.BeginUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i65.BeginUploadResult?>()) {
      return (data != null ? _i65.BeginUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i66.CompleteUploadRequest?>()) {
      return (data != null ? _i66.CompleteUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i67.DeleteObjectRequest?>()) {
      return (data != null ? _i67.DeleteObjectRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i68.GetDownloadRequest?>()) {
      return (data != null ? _i68.GetDownloadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i69.GetDownloadResult?>()) {
      return (data != null ? _i69.GetDownloadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i70.ObjectDeletion?>()) {
      return (data != null ? _i70.ObjectDeletion.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i71.ObjectErrorCode?>()) {
      return (data != null ? _i71.ObjectErrorCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i72.ObjectException?>()) {
      return (data != null ? _i72.ObjectException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i73.ObjectReference?>()) {
      return (data != null ? _i73.ObjectReference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i74.ObjectResult?>()) {
      return (data != null ? _i74.ObjectResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i75.ObjectUpload?>()) {
      return (data != null ? _i75.ObjectUpload.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i76.WorkspaceObject?>()) {
      return (data != null ? _i76.WorkspaceObject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i77.WorkspaceStreamEnvelope?>()) {
      return (data != null ? _i77.WorkspaceStreamEnvelope.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i78.WorkspaceStreamEnvelopeKind?>()) {
      return (data != null
              ? _i78.WorkspaceStreamEnvelopeKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i79.WorkspaceSubscribeRequest?>()) {
      return (data != null
              ? _i79.WorkspaceSubscribeRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i80.MutateWorkspaceCredentialRequest?>()) {
      return (data != null
              ? _i80.MutateWorkspaceCredentialRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i81.MutateWorkspaceCredentialResponse?>()) {
      return (data != null
              ? _i81.MutateWorkspaceCredentialResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i82.PatchWorkspaceStateRequest?>()) {
      return (data != null
              ? _i82.PatchWorkspaceStateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i83.PatchWorkspaceStateResponse?>()) {
      return (data != null
              ? _i83.PatchWorkspaceStateResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i84.PutWorkspaceSecretRequest?>()) {
      return (data != null
              ? _i84.PutWorkspaceSecretRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i85.PutWorkspaceSecretResponse?>()) {
      return (data != null
              ? _i85.PutWorkspaceSecretResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i86.ReadWorkspaceStateRequest?>()) {
      return (data != null
              ? _i86.ReadWorkspaceStateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i87.ReadWorkspaceStateResponse?>()) {
      return (data != null
              ? _i87.ReadWorkspaceStateResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i88.WorkspacePatchOperation?>()) {
      return (data != null ? _i88.WorkspacePatchOperation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i89.WorkspacePatchOperationKind?>()) {
      return (data != null
              ? _i89.WorkspacePatchOperationKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i90.WorkspaceResource?>()) {
      return (data != null ? _i90.WorkspaceResource.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i91.WorkspaceResourceKind?>()) {
      return (data != null ? _i91.WorkspaceResourceKind.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i92.WorkspaceResourcePage?>()) {
      return (data != null ? _i92.WorkspaceResourcePage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i93.WorkspaceResourcePageRequest?>()) {
      return (data != null
              ? _i93.WorkspaceResourcePageRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i94.WorkspaceSecret?>()) {
      return (data != null ? _i94.WorkspaceSecret.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i95.WorkspaceSecretKind?>()) {
      return (data != null ? _i95.WorkspaceSecretKind.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i96.WorkspaceSecretScope?>()) {
      return (data != null ? _i96.WorkspaceSecretScope.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i97.AcceptWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i97.AcceptWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i98.CloudWorkspace?>()) {
      return (data != null ? _i98.CloudWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i99.CloudWorkspaceCapabilities?>()) {
      return (data != null
              ? _i99.CloudWorkspaceCapabilities.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i100.CloudWorkspaceDetail?>()) {
      return (data != null ? _i100.CloudWorkspaceDetail.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i101.CloudWorkspaceErrorCode?>()) {
      return (data != null
              ? _i101.CloudWorkspaceErrorCode.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i102.CloudWorkspaceException?>()) {
      return (data != null
              ? _i102.CloudWorkspaceException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i103.CloudWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i103.CloudWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i104.CloudWorkspaceMemberSummary?>()) {
      return (data != null
              ? _i104.CloudWorkspaceMemberSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i105.CloudWorkspaceSummary?>()) {
      return (data != null ? _i105.CloudWorkspaceSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i106.CreateCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i106.CreateCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i107.DeclineWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i107.DeclineWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i108.DeleteCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i108.DeleteCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i109.GetCloudWorkspaceDetailRequest?>()) {
      return (data != null
              ? _i109.GetCloudWorkspaceDetailRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i110.InviteWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i110.InviteWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i111.LeaveCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i111.LeaveCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i112.ListCloudWorkspaceInvitesRequest?>()) {
      return (data != null
              ? _i112.ListCloudWorkspaceInvitesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i113.ListWorkspaceMembersRequest?>()) {
      return (data != null
              ? _i113.ListWorkspaceMembersRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i114.PendingWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i114.PendingWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i115.RemoveWorkspaceMemberRequest?>()) {
      return (data != null
              ? _i115.RemoveWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i116.RenameCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i116.RenameCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i117.RenewWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i117.RenewWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i118.RevokeWorkspaceInviteRequest?>()) {
      return (data != null
              ? _i118.RevokeWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i119.TransferCloudWorkspaceOwnershipRequest?>()) {
      return (data != null
              ? _i119.TransferCloudWorkspaceOwnershipRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i120.UpdateWorkspaceMemberRoleRequest?>()) {
      return (data != null
              ? _i120.UpdateWorkspaceMemberRoleRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i121.WorkspaceAuditRecord?>()) {
      return (data != null ? _i121.WorkspaceAuditRecord.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i122.WorkspaceEvent?>()) {
      return (data != null ? _i122.WorkspaceEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i123.WorkspaceInvite?>()) {
      return (data != null ? _i123.WorkspaceInvite.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i124.WorkspaceMember?>()) {
      return (data != null ? _i124.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i125.WorkspaceMutationReceipt?>()) {
      return (data != null
              ? _i125.WorkspaceMutationReceipt.fromJson(data)
              : null)
          as T;
    }
    if (t == List<_i24.ConversationToolCallView>) {
      return (data as List)
              .map((e) => deserialize<_i24.ConversationToolCallView>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.ConversationSummary>) {
      return (data as List)
              .map((e) => deserialize<_i22.ConversationSummary>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i19.ConversationMessageView>) {
      return (data as List)
              .map((e) => deserialize<_i19.ConversationMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.DiscoveredMcpTool>) {
      return (data as List)
              .map((e) => deserialize<_i50.DiscoveredMcpTool>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i88.WorkspacePatchOperation>) {
      return (data as List)
              .map((e) => deserialize<_i88.WorkspacePatchOperation>(e))
              .toList()
          as T;
    }
    if (t == List<_i90.WorkspaceResource>) {
      return (data as List)
              .map((e) => deserialize<_i90.WorkspaceResource>(e))
              .toList()
          as T;
    }
    if (t == List<_i93.WorkspaceResourcePageRequest>) {
      return (data as List)
              .map((e) => deserialize<_i93.WorkspaceResourcePageRequest>(e))
              .toList()
          as T;
    }
    if (t == List<_i92.WorkspaceResourcePage>) {
      return (data as List)
              .map((e) => deserialize<_i92.WorkspaceResourcePage>(e))
              .toList()
          as T;
    }
    if (t == List<_i122.WorkspaceEvent>) {
      return (data as List)
              .map((e) => deserialize<_i122.WorkspaceEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i126.ConversationSummary>) {
      return (data as List)
              .map((e) => deserialize<_i126.ConversationSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i127.ConversationMessageView>) {
      return (data as List)
              .map((e) => deserialize<_i127.ConversationMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_i128.ApiModelProvider>) {
      return (data as List)
              .map((e) => deserialize<_i128.ApiModelProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_i129.ApiModel>) {
      return (data as List).map((e) => deserialize<_i129.ApiModel>(e)).toList()
          as T;
    }
    if (t == List<_i130.ModelConnectionView>) {
      return (data as List)
              .map((e) => deserialize<_i130.ModelConnectionView>(e))
              .toList()
          as T;
    }
    if (t == List<_i131.WorkspaceModelSelectionView>) {
      return (data as List)
              .map((e) => deserialize<_i131.WorkspaceModelSelectionView>(e))
              .toList()
          as T;
    }
    if (t == List<_i132.CloudWorkspaceSummary>) {
      return (data as List)
              .map((e) => deserialize<_i132.CloudWorkspaceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i133.PendingWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i133.PendingWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i134.CloudWorkspaceMemberSummary>) {
      return (data as List)
              .map((e) => deserialize<_i134.CloudWorkspaceMemberSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i135.CloudWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_i135.CloudWorkspaceInviteSummary>(e))
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
      _i6.CodexOAuthTransaction => 'CodexOAuthTransaction',
      _i7.CompleteCodexOAuthRequest => 'CompleteCodexOAuthRequest',
      _i8.CompleteCodexOAuthResult => 'CompleteCodexOAuthResult',
      _i9.StartCodexOAuthRequest => 'StartCodexOAuthRequest',
      _i10.StartCodexOAuthResult => 'StartCodexOAuthResult',
      _i11.CancelTurnRequest => 'CancelTurnRequest',
      _i12.CompactConversationRequest => 'CompactConversationRequest',
      _i13.ContinueTurnRequest => 'ContinueTurnRequest',
      _i14.Conversation => 'Conversation',
      _i15.ConversationErrorCode => 'ConversationErrorCode',
      _i16.ConversationException => 'ConversationException',
      _i17.ConversationJob => 'ConversationJob',
      _i18.ConversationMessage => 'ConversationMessage',
      _i19.ConversationMessageView => 'ConversationMessageView',
      _i20.ConversationMutationResult => 'ConversationMutationResult',
      _i21.ConversationPage => 'ConversationPage',
      _i22.ConversationSummary => 'ConversationSummary',
      _i23.ConversationToolCall => 'ConversationToolCall',
      _i24.ConversationToolCallView => 'ConversationToolCallView',
      _i25.ConversationTurn => 'ConversationTurn',
      _i26.ConversationTurnView => 'ConversationTurnView',
      _i27.ConversationUsage => 'ConversationUsage',
      _i28.CreateConversationRequest => 'CreateConversationRequest',
      _i29.DeleteConversationRequest => 'DeleteConversationRequest',
      _i30.GetConversationRequest => 'GetConversationRequest',
      _i31.GetTurnRequest => 'GetTurnRequest',
      _i32.ListConversationMessagesRequest => 'ListConversationMessagesRequest',
      _i33.ListConversationsRequest => 'ListConversationsRequest',
      _i34.LiveTurnEvent => 'LiveTurnEvent',
      _i35.LiveTurnEventKind => 'LiveTurnEventKind',
      _i36.LiveTurnSubscribeRequest => 'LiveTurnSubscribeRequest',
      _i37.ProviderAdmission => 'ProviderAdmission',
      _i38.ProviderAdmissionLock => 'ProviderAdmissionLock',
      _i39.ProviderAdmissionReservation => 'ProviderAdmissionReservation',
      _i40.StartTurnRequest => 'StartTurnRequest',
      _i41.StartTurnResult => 'StartTurnResult',
      _i42.SubmitToolDecisionRequest => 'SubmitToolDecisionRequest',
      _i43.TurnSnapshot => 'TurnSnapshot',
      _i44.UpdateConversationRequest => 'UpdateConversationRequest',
      _i45.CreateMcpServerRequest => 'CreateMcpServerRequest',
      _i46.CreateMcpServerResult => 'CreateMcpServerResult',
      _i47.DeleteMcpServerRequest => 'DeleteMcpServerRequest',
      _i48.DiscoverMcpServerRequest => 'DiscoverMcpServerRequest',
      _i49.DiscoverMcpServerResult => 'DiscoverMcpServerResult',
      _i50.DiscoveredMcpTool => 'DiscoveredMcpTool',
      _i51.McpServerHealth => 'McpServerHealth',
      _i52.ApiModel => 'ApiModel',
      _i53.ApiModelProvider => 'ApiModelProvider',
      _i54.CreateModelConnectionRequest => 'CreateModelConnectionRequest',
      _i55.DeleteModelConnectionRequest => 'DeleteModelConnectionRequest',
      _i56.ListModelConnectionsRequest => 'ListModelConnectionsRequest',
      _i57.ListWorkspaceModelSelectionsRequest =>
        'ListWorkspaceModelSelectionsRequest',
      _i58.ModelConnectionView => 'ModelConnectionView',
      _i59.ModelSyncResult => 'ModelSyncResult',
      _i60.TestAndSyncModelConnectionRequest =>
        'TestAndSyncModelConnectionRequest',
      _i61.UpdateModelConnectionRequest => 'UpdateModelConnectionRequest',
      _i62.WorkspaceModelConnection => 'WorkspaceModelConnection',
      _i63.WorkspaceModelSelectionView => 'WorkspaceModelSelectionView',
      _i64.BeginUploadRequest => 'BeginUploadRequest',
      _i65.BeginUploadResult => 'BeginUploadResult',
      _i66.CompleteUploadRequest => 'CompleteUploadRequest',
      _i67.DeleteObjectRequest => 'DeleteObjectRequest',
      _i68.GetDownloadRequest => 'GetDownloadRequest',
      _i69.GetDownloadResult => 'GetDownloadResult',
      _i70.ObjectDeletion => 'ObjectDeletion',
      _i71.ObjectErrorCode => 'ObjectErrorCode',
      _i72.ObjectException => 'ObjectException',
      _i73.ObjectReference => 'ObjectReference',
      _i74.ObjectResult => 'ObjectResult',
      _i75.ObjectUpload => 'ObjectUpload',
      _i76.WorkspaceObject => 'WorkspaceObject',
      _i77.WorkspaceStreamEnvelope => 'WorkspaceStreamEnvelope',
      _i78.WorkspaceStreamEnvelopeKind => 'WorkspaceStreamEnvelopeKind',
      _i79.WorkspaceSubscribeRequest => 'WorkspaceSubscribeRequest',
      _i80.MutateWorkspaceCredentialRequest =>
        'MutateWorkspaceCredentialRequest',
      _i81.MutateWorkspaceCredentialResponse =>
        'MutateWorkspaceCredentialResponse',
      _i82.PatchWorkspaceStateRequest => 'PatchWorkspaceStateRequest',
      _i83.PatchWorkspaceStateResponse => 'PatchWorkspaceStateResponse',
      _i84.PutWorkspaceSecretRequest => 'PutWorkspaceSecretRequest',
      _i85.PutWorkspaceSecretResponse => 'PutWorkspaceSecretResponse',
      _i86.ReadWorkspaceStateRequest => 'ReadWorkspaceStateRequest',
      _i87.ReadWorkspaceStateResponse => 'ReadWorkspaceStateResponse',
      _i88.WorkspacePatchOperation => 'WorkspacePatchOperation',
      _i89.WorkspacePatchOperationKind => 'WorkspacePatchOperationKind',
      _i90.WorkspaceResource => 'WorkspaceResource',
      _i91.WorkspaceResourceKind => 'WorkspaceResourceKind',
      _i92.WorkspaceResourcePage => 'WorkspaceResourcePage',
      _i93.WorkspaceResourcePageRequest => 'WorkspaceResourcePageRequest',
      _i94.WorkspaceSecret => 'WorkspaceSecret',
      _i95.WorkspaceSecretKind => 'WorkspaceSecretKind',
      _i96.WorkspaceSecretScope => 'WorkspaceSecretScope',
      _i97.AcceptWorkspaceInviteRequest => 'AcceptWorkspaceInviteRequest',
      _i98.CloudWorkspace => 'CloudWorkspace',
      _i99.CloudWorkspaceCapabilities => 'CloudWorkspaceCapabilities',
      _i100.CloudWorkspaceDetail => 'CloudWorkspaceDetail',
      _i101.CloudWorkspaceErrorCode => 'CloudWorkspaceErrorCode',
      _i102.CloudWorkspaceException => 'CloudWorkspaceException',
      _i103.CloudWorkspaceInviteSummary => 'CloudWorkspaceInviteSummary',
      _i104.CloudWorkspaceMemberSummary => 'CloudWorkspaceMemberSummary',
      _i105.CloudWorkspaceSummary => 'CloudWorkspaceSummary',
      _i106.CreateCloudWorkspaceRequest => 'CreateCloudWorkspaceRequest',
      _i107.DeclineWorkspaceInviteRequest => 'DeclineWorkspaceInviteRequest',
      _i108.DeleteCloudWorkspaceRequest => 'DeleteCloudWorkspaceRequest',
      _i109.GetCloudWorkspaceDetailRequest => 'GetCloudWorkspaceDetailRequest',
      _i110.InviteWorkspaceMemberRequest => 'InviteWorkspaceMemberRequest',
      _i111.LeaveCloudWorkspaceRequest => 'LeaveCloudWorkspaceRequest',
      _i112.ListCloudWorkspaceInvitesRequest =>
        'ListCloudWorkspaceInvitesRequest',
      _i113.ListWorkspaceMembersRequest => 'ListWorkspaceMembersRequest',
      _i114.PendingWorkspaceInviteSummary => 'PendingWorkspaceInviteSummary',
      _i115.RemoveWorkspaceMemberRequest => 'RemoveWorkspaceMemberRequest',
      _i116.RenameCloudWorkspaceRequest => 'RenameCloudWorkspaceRequest',
      _i117.RenewWorkspaceInviteRequest => 'RenewWorkspaceInviteRequest',
      _i118.RevokeWorkspaceInviteRequest => 'RevokeWorkspaceInviteRequest',
      _i119.TransferCloudWorkspaceOwnershipRequest =>
        'TransferCloudWorkspaceOwnershipRequest',
      _i120.UpdateWorkspaceMemberRoleRequest =>
        'UpdateWorkspaceMemberRoleRequest',
      _i121.WorkspaceAuditRecord => 'WorkspaceAuditRecord',
      _i122.WorkspaceEvent => 'WorkspaceEvent',
      _i123.WorkspaceInvite => 'WorkspaceInvite',
      _i124.WorkspaceMember => 'WorkspaceMember',
      _i125.WorkspaceMutationReceipt => 'WorkspaceMutationReceipt',
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
      case _i6.CodexOAuthTransaction():
        return 'CodexOAuthTransaction';
      case _i7.CompleteCodexOAuthRequest():
        return 'CompleteCodexOAuthRequest';
      case _i8.CompleteCodexOAuthResult():
        return 'CompleteCodexOAuthResult';
      case _i9.StartCodexOAuthRequest():
        return 'StartCodexOAuthRequest';
      case _i10.StartCodexOAuthResult():
        return 'StartCodexOAuthResult';
      case _i11.CancelTurnRequest():
        return 'CancelTurnRequest';
      case _i12.CompactConversationRequest():
        return 'CompactConversationRequest';
      case _i13.ContinueTurnRequest():
        return 'ContinueTurnRequest';
      case _i14.Conversation():
        return 'Conversation';
      case _i15.ConversationErrorCode():
        return 'ConversationErrorCode';
      case _i16.ConversationException():
        return 'ConversationException';
      case _i17.ConversationJob():
        return 'ConversationJob';
      case _i18.ConversationMessage():
        return 'ConversationMessage';
      case _i19.ConversationMessageView():
        return 'ConversationMessageView';
      case _i20.ConversationMutationResult():
        return 'ConversationMutationResult';
      case _i21.ConversationPage():
        return 'ConversationPage';
      case _i22.ConversationSummary():
        return 'ConversationSummary';
      case _i23.ConversationToolCall():
        return 'ConversationToolCall';
      case _i24.ConversationToolCallView():
        return 'ConversationToolCallView';
      case _i25.ConversationTurn():
        return 'ConversationTurn';
      case _i26.ConversationTurnView():
        return 'ConversationTurnView';
      case _i27.ConversationUsage():
        return 'ConversationUsage';
      case _i28.CreateConversationRequest():
        return 'CreateConversationRequest';
      case _i29.DeleteConversationRequest():
        return 'DeleteConversationRequest';
      case _i30.GetConversationRequest():
        return 'GetConversationRequest';
      case _i31.GetTurnRequest():
        return 'GetTurnRequest';
      case _i32.ListConversationMessagesRequest():
        return 'ListConversationMessagesRequest';
      case _i33.ListConversationsRequest():
        return 'ListConversationsRequest';
      case _i34.LiveTurnEvent():
        return 'LiveTurnEvent';
      case _i35.LiveTurnEventKind():
        return 'LiveTurnEventKind';
      case _i36.LiveTurnSubscribeRequest():
        return 'LiveTurnSubscribeRequest';
      case _i37.ProviderAdmission():
        return 'ProviderAdmission';
      case _i38.ProviderAdmissionLock():
        return 'ProviderAdmissionLock';
      case _i39.ProviderAdmissionReservation():
        return 'ProviderAdmissionReservation';
      case _i40.StartTurnRequest():
        return 'StartTurnRequest';
      case _i41.StartTurnResult():
        return 'StartTurnResult';
      case _i42.SubmitToolDecisionRequest():
        return 'SubmitToolDecisionRequest';
      case _i43.TurnSnapshot():
        return 'TurnSnapshot';
      case _i44.UpdateConversationRequest():
        return 'UpdateConversationRequest';
      case _i45.CreateMcpServerRequest():
        return 'CreateMcpServerRequest';
      case _i46.CreateMcpServerResult():
        return 'CreateMcpServerResult';
      case _i47.DeleteMcpServerRequest():
        return 'DeleteMcpServerRequest';
      case _i48.DiscoverMcpServerRequest():
        return 'DiscoverMcpServerRequest';
      case _i49.DiscoverMcpServerResult():
        return 'DiscoverMcpServerResult';
      case _i50.DiscoveredMcpTool():
        return 'DiscoveredMcpTool';
      case _i51.McpServerHealth():
        return 'McpServerHealth';
      case _i52.ApiModel():
        return 'ApiModel';
      case _i53.ApiModelProvider():
        return 'ApiModelProvider';
      case _i54.CreateModelConnectionRequest():
        return 'CreateModelConnectionRequest';
      case _i55.DeleteModelConnectionRequest():
        return 'DeleteModelConnectionRequest';
      case _i56.ListModelConnectionsRequest():
        return 'ListModelConnectionsRequest';
      case _i57.ListWorkspaceModelSelectionsRequest():
        return 'ListWorkspaceModelSelectionsRequest';
      case _i58.ModelConnectionView():
        return 'ModelConnectionView';
      case _i59.ModelSyncResult():
        return 'ModelSyncResult';
      case _i60.TestAndSyncModelConnectionRequest():
        return 'TestAndSyncModelConnectionRequest';
      case _i61.UpdateModelConnectionRequest():
        return 'UpdateModelConnectionRequest';
      case _i62.WorkspaceModelConnection():
        return 'WorkspaceModelConnection';
      case _i63.WorkspaceModelSelectionView():
        return 'WorkspaceModelSelectionView';
      case _i64.BeginUploadRequest():
        return 'BeginUploadRequest';
      case _i65.BeginUploadResult():
        return 'BeginUploadResult';
      case _i66.CompleteUploadRequest():
        return 'CompleteUploadRequest';
      case _i67.DeleteObjectRequest():
        return 'DeleteObjectRequest';
      case _i68.GetDownloadRequest():
        return 'GetDownloadRequest';
      case _i69.GetDownloadResult():
        return 'GetDownloadResult';
      case _i70.ObjectDeletion():
        return 'ObjectDeletion';
      case _i71.ObjectErrorCode():
        return 'ObjectErrorCode';
      case _i72.ObjectException():
        return 'ObjectException';
      case _i73.ObjectReference():
        return 'ObjectReference';
      case _i74.ObjectResult():
        return 'ObjectResult';
      case _i75.ObjectUpload():
        return 'ObjectUpload';
      case _i76.WorkspaceObject():
        return 'WorkspaceObject';
      case _i77.WorkspaceStreamEnvelope():
        return 'WorkspaceStreamEnvelope';
      case _i78.WorkspaceStreamEnvelopeKind():
        return 'WorkspaceStreamEnvelopeKind';
      case _i79.WorkspaceSubscribeRequest():
        return 'WorkspaceSubscribeRequest';
      case _i80.MutateWorkspaceCredentialRequest():
        return 'MutateWorkspaceCredentialRequest';
      case _i81.MutateWorkspaceCredentialResponse():
        return 'MutateWorkspaceCredentialResponse';
      case _i82.PatchWorkspaceStateRequest():
        return 'PatchWorkspaceStateRequest';
      case _i83.PatchWorkspaceStateResponse():
        return 'PatchWorkspaceStateResponse';
      case _i84.PutWorkspaceSecretRequest():
        return 'PutWorkspaceSecretRequest';
      case _i85.PutWorkspaceSecretResponse():
        return 'PutWorkspaceSecretResponse';
      case _i86.ReadWorkspaceStateRequest():
        return 'ReadWorkspaceStateRequest';
      case _i87.ReadWorkspaceStateResponse():
        return 'ReadWorkspaceStateResponse';
      case _i88.WorkspacePatchOperation():
        return 'WorkspacePatchOperation';
      case _i89.WorkspacePatchOperationKind():
        return 'WorkspacePatchOperationKind';
      case _i90.WorkspaceResource():
        return 'WorkspaceResource';
      case _i91.WorkspaceResourceKind():
        return 'WorkspaceResourceKind';
      case _i92.WorkspaceResourcePage():
        return 'WorkspaceResourcePage';
      case _i93.WorkspaceResourcePageRequest():
        return 'WorkspaceResourcePageRequest';
      case _i94.WorkspaceSecret():
        return 'WorkspaceSecret';
      case _i95.WorkspaceSecretKind():
        return 'WorkspaceSecretKind';
      case _i96.WorkspaceSecretScope():
        return 'WorkspaceSecretScope';
      case _i97.AcceptWorkspaceInviteRequest():
        return 'AcceptWorkspaceInviteRequest';
      case _i98.CloudWorkspace():
        return 'CloudWorkspace';
      case _i99.CloudWorkspaceCapabilities():
        return 'CloudWorkspaceCapabilities';
      case _i100.CloudWorkspaceDetail():
        return 'CloudWorkspaceDetail';
      case _i101.CloudWorkspaceErrorCode():
        return 'CloudWorkspaceErrorCode';
      case _i102.CloudWorkspaceException():
        return 'CloudWorkspaceException';
      case _i103.CloudWorkspaceInviteSummary():
        return 'CloudWorkspaceInviteSummary';
      case _i104.CloudWorkspaceMemberSummary():
        return 'CloudWorkspaceMemberSummary';
      case _i105.CloudWorkspaceSummary():
        return 'CloudWorkspaceSummary';
      case _i106.CreateCloudWorkspaceRequest():
        return 'CreateCloudWorkspaceRequest';
      case _i107.DeclineWorkspaceInviteRequest():
        return 'DeclineWorkspaceInviteRequest';
      case _i108.DeleteCloudWorkspaceRequest():
        return 'DeleteCloudWorkspaceRequest';
      case _i109.GetCloudWorkspaceDetailRequest():
        return 'GetCloudWorkspaceDetailRequest';
      case _i110.InviteWorkspaceMemberRequest():
        return 'InviteWorkspaceMemberRequest';
      case _i111.LeaveCloudWorkspaceRequest():
        return 'LeaveCloudWorkspaceRequest';
      case _i112.ListCloudWorkspaceInvitesRequest():
        return 'ListCloudWorkspaceInvitesRequest';
      case _i113.ListWorkspaceMembersRequest():
        return 'ListWorkspaceMembersRequest';
      case _i114.PendingWorkspaceInviteSummary():
        return 'PendingWorkspaceInviteSummary';
      case _i115.RemoveWorkspaceMemberRequest():
        return 'RemoveWorkspaceMemberRequest';
      case _i116.RenameCloudWorkspaceRequest():
        return 'RenameCloudWorkspaceRequest';
      case _i117.RenewWorkspaceInviteRequest():
        return 'RenewWorkspaceInviteRequest';
      case _i118.RevokeWorkspaceInviteRequest():
        return 'RevokeWorkspaceInviteRequest';
      case _i119.TransferCloudWorkspaceOwnershipRequest():
        return 'TransferCloudWorkspaceOwnershipRequest';
      case _i120.UpdateWorkspaceMemberRoleRequest():
        return 'UpdateWorkspaceMemberRoleRequest';
      case _i121.WorkspaceAuditRecord():
        return 'WorkspaceAuditRecord';
      case _i122.WorkspaceEvent():
        return 'WorkspaceEvent';
      case _i123.WorkspaceInvite():
        return 'WorkspaceInvite';
      case _i124.WorkspaceMember():
        return 'WorkspaceMember';
      case _i125.WorkspaceMutationReceipt():
        return 'WorkspaceMutationReceipt';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
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
    if (dataClassName == 'CodexOAuthTransaction') {
      return deserialize<_i6.CodexOAuthTransaction>(data['data']);
    }
    if (dataClassName == 'CompleteCodexOAuthRequest') {
      return deserialize<_i7.CompleteCodexOAuthRequest>(data['data']);
    }
    if (dataClassName == 'CompleteCodexOAuthResult') {
      return deserialize<_i8.CompleteCodexOAuthResult>(data['data']);
    }
    if (dataClassName == 'StartCodexOAuthRequest') {
      return deserialize<_i9.StartCodexOAuthRequest>(data['data']);
    }
    if (dataClassName == 'StartCodexOAuthResult') {
      return deserialize<_i10.StartCodexOAuthResult>(data['data']);
    }
    if (dataClassName == 'CancelTurnRequest') {
      return deserialize<_i11.CancelTurnRequest>(data['data']);
    }
    if (dataClassName == 'CompactConversationRequest') {
      return deserialize<_i12.CompactConversationRequest>(data['data']);
    }
    if (dataClassName == 'ContinueTurnRequest') {
      return deserialize<_i13.ContinueTurnRequest>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i14.Conversation>(data['data']);
    }
    if (dataClassName == 'ConversationErrorCode') {
      return deserialize<_i15.ConversationErrorCode>(data['data']);
    }
    if (dataClassName == 'ConversationException') {
      return deserialize<_i16.ConversationException>(data['data']);
    }
    if (dataClassName == 'ConversationJob') {
      return deserialize<_i17.ConversationJob>(data['data']);
    }
    if (dataClassName == 'ConversationMessage') {
      return deserialize<_i18.ConversationMessage>(data['data']);
    }
    if (dataClassName == 'ConversationMessageView') {
      return deserialize<_i19.ConversationMessageView>(data['data']);
    }
    if (dataClassName == 'ConversationMutationResult') {
      return deserialize<_i20.ConversationMutationResult>(data['data']);
    }
    if (dataClassName == 'ConversationPage') {
      return deserialize<_i21.ConversationPage>(data['data']);
    }
    if (dataClassName == 'ConversationSummary') {
      return deserialize<_i22.ConversationSummary>(data['data']);
    }
    if (dataClassName == 'ConversationToolCall') {
      return deserialize<_i23.ConversationToolCall>(data['data']);
    }
    if (dataClassName == 'ConversationToolCallView') {
      return deserialize<_i24.ConversationToolCallView>(data['data']);
    }
    if (dataClassName == 'ConversationTurn') {
      return deserialize<_i25.ConversationTurn>(data['data']);
    }
    if (dataClassName == 'ConversationTurnView') {
      return deserialize<_i26.ConversationTurnView>(data['data']);
    }
    if (dataClassName == 'ConversationUsage') {
      return deserialize<_i27.ConversationUsage>(data['data']);
    }
    if (dataClassName == 'CreateConversationRequest') {
      return deserialize<_i28.CreateConversationRequest>(data['data']);
    }
    if (dataClassName == 'DeleteConversationRequest') {
      return deserialize<_i29.DeleteConversationRequest>(data['data']);
    }
    if (dataClassName == 'GetConversationRequest') {
      return deserialize<_i30.GetConversationRequest>(data['data']);
    }
    if (dataClassName == 'GetTurnRequest') {
      return deserialize<_i31.GetTurnRequest>(data['data']);
    }
    if (dataClassName == 'ListConversationMessagesRequest') {
      return deserialize<_i32.ListConversationMessagesRequest>(data['data']);
    }
    if (dataClassName == 'ListConversationsRequest') {
      return deserialize<_i33.ListConversationsRequest>(data['data']);
    }
    if (dataClassName == 'LiveTurnEvent') {
      return deserialize<_i34.LiveTurnEvent>(data['data']);
    }
    if (dataClassName == 'LiveTurnEventKind') {
      return deserialize<_i35.LiveTurnEventKind>(data['data']);
    }
    if (dataClassName == 'LiveTurnSubscribeRequest') {
      return deserialize<_i36.LiveTurnSubscribeRequest>(data['data']);
    }
    if (dataClassName == 'ProviderAdmission') {
      return deserialize<_i37.ProviderAdmission>(data['data']);
    }
    if (dataClassName == 'ProviderAdmissionLock') {
      return deserialize<_i38.ProviderAdmissionLock>(data['data']);
    }
    if (dataClassName == 'ProviderAdmissionReservation') {
      return deserialize<_i39.ProviderAdmissionReservation>(data['data']);
    }
    if (dataClassName == 'StartTurnRequest') {
      return deserialize<_i40.StartTurnRequest>(data['data']);
    }
    if (dataClassName == 'StartTurnResult') {
      return deserialize<_i41.StartTurnResult>(data['data']);
    }
    if (dataClassName == 'SubmitToolDecisionRequest') {
      return deserialize<_i42.SubmitToolDecisionRequest>(data['data']);
    }
    if (dataClassName == 'TurnSnapshot') {
      return deserialize<_i43.TurnSnapshot>(data['data']);
    }
    if (dataClassName == 'UpdateConversationRequest') {
      return deserialize<_i44.UpdateConversationRequest>(data['data']);
    }
    if (dataClassName == 'CreateMcpServerRequest') {
      return deserialize<_i45.CreateMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'CreateMcpServerResult') {
      return deserialize<_i46.CreateMcpServerResult>(data['data']);
    }
    if (dataClassName == 'DeleteMcpServerRequest') {
      return deserialize<_i47.DeleteMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'DiscoverMcpServerRequest') {
      return deserialize<_i48.DiscoverMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'DiscoverMcpServerResult') {
      return deserialize<_i49.DiscoverMcpServerResult>(data['data']);
    }
    if (dataClassName == 'DiscoveredMcpTool') {
      return deserialize<_i50.DiscoveredMcpTool>(data['data']);
    }
    if (dataClassName == 'McpServerHealth') {
      return deserialize<_i51.McpServerHealth>(data['data']);
    }
    if (dataClassName == 'ApiModel') {
      return deserialize<_i52.ApiModel>(data['data']);
    }
    if (dataClassName == 'ApiModelProvider') {
      return deserialize<_i53.ApiModelProvider>(data['data']);
    }
    if (dataClassName == 'CreateModelConnectionRequest') {
      return deserialize<_i54.CreateModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'DeleteModelConnectionRequest') {
      return deserialize<_i55.DeleteModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'ListModelConnectionsRequest') {
      return deserialize<_i56.ListModelConnectionsRequest>(data['data']);
    }
    if (dataClassName == 'ListWorkspaceModelSelectionsRequest') {
      return deserialize<_i57.ListWorkspaceModelSelectionsRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'ModelConnectionView') {
      return deserialize<_i58.ModelConnectionView>(data['data']);
    }
    if (dataClassName == 'ModelSyncResult') {
      return deserialize<_i59.ModelSyncResult>(data['data']);
    }
    if (dataClassName == 'TestAndSyncModelConnectionRequest') {
      return deserialize<_i60.TestAndSyncModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'UpdateModelConnectionRequest') {
      return deserialize<_i61.UpdateModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceModelConnection') {
      return deserialize<_i62.WorkspaceModelConnection>(data['data']);
    }
    if (dataClassName == 'WorkspaceModelSelectionView') {
      return deserialize<_i63.WorkspaceModelSelectionView>(data['data']);
    }
    if (dataClassName == 'BeginUploadRequest') {
      return deserialize<_i64.BeginUploadRequest>(data['data']);
    }
    if (dataClassName == 'BeginUploadResult') {
      return deserialize<_i65.BeginUploadResult>(data['data']);
    }
    if (dataClassName == 'CompleteUploadRequest') {
      return deserialize<_i66.CompleteUploadRequest>(data['data']);
    }
    if (dataClassName == 'DeleteObjectRequest') {
      return deserialize<_i67.DeleteObjectRequest>(data['data']);
    }
    if (dataClassName == 'GetDownloadRequest') {
      return deserialize<_i68.GetDownloadRequest>(data['data']);
    }
    if (dataClassName == 'GetDownloadResult') {
      return deserialize<_i69.GetDownloadResult>(data['data']);
    }
    if (dataClassName == 'ObjectDeletion') {
      return deserialize<_i70.ObjectDeletion>(data['data']);
    }
    if (dataClassName == 'ObjectErrorCode') {
      return deserialize<_i71.ObjectErrorCode>(data['data']);
    }
    if (dataClassName == 'ObjectException') {
      return deserialize<_i72.ObjectException>(data['data']);
    }
    if (dataClassName == 'ObjectReference') {
      return deserialize<_i73.ObjectReference>(data['data']);
    }
    if (dataClassName == 'ObjectResult') {
      return deserialize<_i74.ObjectResult>(data['data']);
    }
    if (dataClassName == 'ObjectUpload') {
      return deserialize<_i75.ObjectUpload>(data['data']);
    }
    if (dataClassName == 'WorkspaceObject') {
      return deserialize<_i76.WorkspaceObject>(data['data']);
    }
    if (dataClassName == 'WorkspaceStreamEnvelope') {
      return deserialize<_i77.WorkspaceStreamEnvelope>(data['data']);
    }
    if (dataClassName == 'WorkspaceStreamEnvelopeKind') {
      return deserialize<_i78.WorkspaceStreamEnvelopeKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceSubscribeRequest') {
      return deserialize<_i79.WorkspaceSubscribeRequest>(data['data']);
    }
    if (dataClassName == 'MutateWorkspaceCredentialRequest') {
      return deserialize<_i80.MutateWorkspaceCredentialRequest>(data['data']);
    }
    if (dataClassName == 'MutateWorkspaceCredentialResponse') {
      return deserialize<_i81.MutateWorkspaceCredentialResponse>(data['data']);
    }
    if (dataClassName == 'PatchWorkspaceStateRequest') {
      return deserialize<_i82.PatchWorkspaceStateRequest>(data['data']);
    }
    if (dataClassName == 'PatchWorkspaceStateResponse') {
      return deserialize<_i83.PatchWorkspaceStateResponse>(data['data']);
    }
    if (dataClassName == 'PutWorkspaceSecretRequest') {
      return deserialize<_i84.PutWorkspaceSecretRequest>(data['data']);
    }
    if (dataClassName == 'PutWorkspaceSecretResponse') {
      return deserialize<_i85.PutWorkspaceSecretResponse>(data['data']);
    }
    if (dataClassName == 'ReadWorkspaceStateRequest') {
      return deserialize<_i86.ReadWorkspaceStateRequest>(data['data']);
    }
    if (dataClassName == 'ReadWorkspaceStateResponse') {
      return deserialize<_i87.ReadWorkspaceStateResponse>(data['data']);
    }
    if (dataClassName == 'WorkspacePatchOperation') {
      return deserialize<_i88.WorkspacePatchOperation>(data['data']);
    }
    if (dataClassName == 'WorkspacePatchOperationKind') {
      return deserialize<_i89.WorkspacePatchOperationKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceResource') {
      return deserialize<_i90.WorkspaceResource>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourceKind') {
      return deserialize<_i91.WorkspaceResourceKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourcePage') {
      return deserialize<_i92.WorkspaceResourcePage>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourcePageRequest') {
      return deserialize<_i93.WorkspaceResourcePageRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecret') {
      return deserialize<_i94.WorkspaceSecret>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecretKind') {
      return deserialize<_i95.WorkspaceSecretKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecretScope') {
      return deserialize<_i96.WorkspaceSecretScope>(data['data']);
    }
    if (dataClassName == 'AcceptWorkspaceInviteRequest') {
      return deserialize<_i97.AcceptWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'CloudWorkspace') {
      return deserialize<_i98.CloudWorkspace>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceCapabilities') {
      return deserialize<_i99.CloudWorkspaceCapabilities>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceDetail') {
      return deserialize<_i100.CloudWorkspaceDetail>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceErrorCode') {
      return deserialize<_i101.CloudWorkspaceErrorCode>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceException') {
      return deserialize<_i102.CloudWorkspaceException>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceInviteSummary') {
      return deserialize<_i103.CloudWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceMemberSummary') {
      return deserialize<_i104.CloudWorkspaceMemberSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceSummary') {
      return deserialize<_i105.CloudWorkspaceSummary>(data['data']);
    }
    if (dataClassName == 'CreateCloudWorkspaceRequest') {
      return deserialize<_i106.CreateCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'DeclineWorkspaceInviteRequest') {
      return deserialize<_i107.DeclineWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'DeleteCloudWorkspaceRequest') {
      return deserialize<_i108.DeleteCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'GetCloudWorkspaceDetailRequest') {
      return deserialize<_i109.GetCloudWorkspaceDetailRequest>(data['data']);
    }
    if (dataClassName == 'InviteWorkspaceMemberRequest') {
      return deserialize<_i110.InviteWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'LeaveCloudWorkspaceRequest') {
      return deserialize<_i111.LeaveCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'ListCloudWorkspaceInvitesRequest') {
      return deserialize<_i112.ListCloudWorkspaceInvitesRequest>(data['data']);
    }
    if (dataClassName == 'ListWorkspaceMembersRequest') {
      return deserialize<_i113.ListWorkspaceMembersRequest>(data['data']);
    }
    if (dataClassName == 'PendingWorkspaceInviteSummary') {
      return deserialize<_i114.PendingWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'RemoveWorkspaceMemberRequest') {
      return deserialize<_i115.RemoveWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'RenameCloudWorkspaceRequest') {
      return deserialize<_i116.RenameCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'RenewWorkspaceInviteRequest') {
      return deserialize<_i117.RenewWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'RevokeWorkspaceInviteRequest') {
      return deserialize<_i118.RevokeWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'TransferCloudWorkspaceOwnershipRequest') {
      return deserialize<_i119.TransferCloudWorkspaceOwnershipRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'UpdateWorkspaceMemberRoleRequest') {
      return deserialize<_i120.UpdateWorkspaceMemberRoleRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceAuditRecord') {
      return deserialize<_i121.WorkspaceAuditRecord>(data['data']);
    }
    if (dataClassName == 'WorkspaceEvent') {
      return deserialize<_i122.WorkspaceEvent>(data['data']);
    }
    if (dataClassName == 'WorkspaceInvite') {
      return deserialize<_i123.WorkspaceInvite>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i124.WorkspaceMember>(data['data']);
    }
    if (dataClassName == 'WorkspaceMutationReceipt') {
      return deserialize<_i125.WorkspaceMutationReceipt>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
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
      case _i6.CodexOAuthTransaction:
        return _i6.CodexOAuthTransaction.t;
      case _i14.Conversation:
        return _i14.Conversation.t;
      case _i17.ConversationJob:
        return _i17.ConversationJob.t;
      case _i18.ConversationMessage:
        return _i18.ConversationMessage.t;
      case _i23.ConversationToolCall:
        return _i23.ConversationToolCall.t;
      case _i25.ConversationTurn:
        return _i25.ConversationTurn.t;
      case _i27.ConversationUsage:
        return _i27.ConversationUsage.t;
      case _i37.ProviderAdmission:
        return _i37.ProviderAdmission.t;
      case _i38.ProviderAdmissionLock:
        return _i38.ProviderAdmissionLock.t;
      case _i39.ProviderAdmissionReservation:
        return _i39.ProviderAdmissionReservation.t;
      case _i52.ApiModel:
        return _i52.ApiModel.t;
      case _i53.ApiModelProvider:
        return _i53.ApiModelProvider.t;
      case _i62.WorkspaceModelConnection:
        return _i62.WorkspaceModelConnection.t;
      case _i70.ObjectDeletion:
        return _i70.ObjectDeletion.t;
      case _i73.ObjectReference:
        return _i73.ObjectReference.t;
      case _i75.ObjectUpload:
        return _i75.ObjectUpload.t;
      case _i76.WorkspaceObject:
        return _i76.WorkspaceObject.t;
      case _i90.WorkspaceResource:
        return _i90.WorkspaceResource.t;
      case _i94.WorkspaceSecret:
        return _i94.WorkspaceSecret.t;
      case _i98.CloudWorkspace:
        return _i98.CloudWorkspace.t;
      case _i121.WorkspaceAuditRecord:
        return _i121.WorkspaceAuditRecord.t;
      case _i122.WorkspaceEvent:
        return _i122.WorkspaceEvent.t;
      case _i123.WorkspaceInvite:
        return _i123.WorkspaceInvite.t;
      case _i124.WorkspaceMember:
        return _i124.WorkspaceMember.t;
      case _i125.WorkspaceMutationReceipt:
        return _i125.WorkspaceMutationReceipt.t;
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
