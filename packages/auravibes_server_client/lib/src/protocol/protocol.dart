/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_message_view.dart'
    as _isubclmd;
import 'package:auravibes_server_client/src/protocol/features/conversations/models/conversation_summary.dart'
    as _i54dvwkh;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model.dart'
    as _iuloe217;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/api_model_provider.dart'
    as _ipos6eci;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/model_connection_view.dart'
    as _i5hnstsl;
import 'package:auravibes_server_client/src/protocol/features/model_connections/models/workspace_model_selection_view.dart'
    as _i9qkc4pk;
import 'package:auravibes_server_client/src/protocol/features/workspace_state/models/workspace_resource.dart'
    as _iar0fwau;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _iin9r2cd;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i8ggzj4z;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/cloud_workspace_summary.dart'
    as _ib73r5sl;
import 'package:auravibes_server_client/src/protocol/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _ieuc8ihm;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import 'features/accounts/models/account_summary.dart' as _i0kh9vnq;
import 'features/agents/models/agent_catalog_item.dart' as _iczr9u8f;
import 'features/agents/models/agent_catalog_page.dart' as _ib4whsrz;
import 'features/agents/models/agent_catalog_status.dart' as _i0h0m7az;
import 'features/agents/models/agent_catalog_type.dart' as _icsw3jh1;
import 'features/agents/models/agent_catalog_visibility.dart' as _izubbx9m;
import 'features/agents/models/get_agent_resources_request.dart' as _i84solqu;
import 'features/agents/models/list_agents_request.dart' as _ilueer9m;
import 'features/codex_oauth/models/codex_oauth_transaction.dart' as _ify5ufwn;
import 'features/codex_oauth/models/complete_codex_oauth_request.dart'
    as _i2qdkbo8;
import 'features/codex_oauth/models/complete_codex_oauth_result.dart'
    as _ibhl6ekj;
import 'features/codex_oauth/models/start_codex_oauth_request.dart'
    as _iv7ukgnj;
import 'features/codex_oauth/models/start_codex_oauth_result.dart' as _itptq7z5;
import 'features/conversations/models/cancel_turn_request.dart' as _iarqshx6;
import 'features/conversations/models/compact_conversation_request.dart'
    as _isyd7s84;
import 'features/conversations/models/continue_conversation_request.dart'
    as _ialxa16r;
import 'features/conversations/models/continue_turn_request.dart' as _iwrs6sde;
import 'features/conversations/models/conversation.dart' as _iivijtsr;
import 'features/conversations/models/conversation_error_code.dart'
    as _iz6esn7o;
import 'features/conversations/models/conversation_event.dart' as _i77s958n;
import 'features/conversations/models/conversation_event_type.dart'
    as _i5gn99j4;
import 'features/conversations/models/conversation_exception.dart' as _i4box1gt;
import 'features/conversations/models/conversation_execution.dart' as _iznwbo5b;
import 'features/conversations/models/conversation_execution_view.dart'
    as _ij9w9f8d;
import 'features/conversations/models/conversation_job.dart' as _iq1eovrr;
import 'features/conversations/models/conversation_message.dart' as _ibea51bx;
import 'features/conversations/models/conversation_message_view.dart'
    as _iutotoh6;
import 'features/conversations/models/conversation_mutation_result.dart'
    as _iz02ruas;
import 'features/conversations/models/conversation_page.dart' as _icl1rfiv;
import 'features/conversations/models/conversation_projection_view.dart'
    as _icx9bns3;
import 'features/conversations/models/conversation_snapshot.dart' as _i4omaws8;
import 'features/conversations/models/conversation_stream_event.dart'
    as _irrmkjcu;
import 'features/conversations/models/conversation_subscribe_request.dart'
    as _i6hxcode;
import 'features/conversations/models/conversation_summary.dart' as _i7a0mfc5;
import 'features/conversations/models/conversation_tool_call.dart' as _iflac717;
import 'features/conversations/models/conversation_tool_call_view.dart'
    as _ic5ojtne;
import 'features/conversations/models/conversation_turn.dart' as _i7mmki1w;
import 'features/conversations/models/conversation_turn_view.dart' as _ir5w321b;
import 'features/conversations/models/conversation_usage.dart' as _iii6xlqw;
import 'features/conversations/models/create_conversation_request.dart'
    as _i4shnjby;
import 'features/conversations/models/delete_conversation_request.dart'
    as _iqsppx3t;
import 'features/conversations/models/edit_pending_conversation_message_request.dart'
    as _iybdpw96;
import 'features/conversations/models/get_conversation_request.dart'
    as _ixb0z1tn;
import 'features/conversations/models/get_turn_request.dart' as _ilyvwvdb;
import 'features/conversations/models/list_conversation_messages_request.dart'
    as _it91nt4l;
import 'features/conversations/models/list_conversations_request.dart'
    as _itcpel99;
import 'features/conversations/models/provider_admission.dart' as _i32k4voa;
import 'features/conversations/models/provider_admission_lock.dart'
    as _ih2np1vh;
import 'features/conversations/models/provider_admission_reservation.dart'
    as _i7moywui;
import 'features/conversations/models/queue_conversation_message_request.dart'
    as _ido51m94;
import 'features/conversations/models/remove_pending_conversation_message_request.dart'
    as _iy526sio;
import 'features/conversations/models/reorder_pending_conversation_message_request.dart'
    as _infbxzxr;
import 'features/conversations/models/start_turn_request.dart' as _iocu6u94;
import 'features/conversations/models/start_turn_result.dart' as _iw8le0j7;
import 'features/conversations/models/stop_conversation_request.dart'
    as _i4cgq7zt;
import 'features/conversations/models/submit_tool_decision_request.dart'
    as _inla43mu;
import 'features/conversations/models/turn_snapshot.dart' as _ih4jnnah;
import 'features/conversations/models/update_conversation_request.dart'
    as _ihs4d7mz;
import 'features/conversations/models/update_conversation_settings_request.dart'
    as _i8unm495;
import 'features/mcp_servers/models/create_mcp_server_request.dart'
    as _i6hg2xtf;
import 'features/mcp_servers/models/create_mcp_server_result.dart' as _ihyupc89;
import 'features/mcp_servers/models/delete_mcp_server_request.dart'
    as _iabui7vl;
import 'features/mcp_servers/models/discover_mcp_server_request.dart'
    as _ilmfigs5;
import 'features/mcp_servers/models/discover_mcp_server_result.dart'
    as _i5i328k3;
import 'features/mcp_servers/models/discovered_mcp_tool.dart' as _igzjg3pi;
import 'features/mcp_servers/models/mcp_server_health.dart' as _iw1ftww6;
import 'features/model_connections/models/api_model.dart' as _i8ct1fsr;
import 'features/model_connections/models/api_model_provider.dart' as _ioo5yu9z;
import 'features/model_connections/models/create_model_connection_request.dart'
    as _i4akrsd1;
import 'features/model_connections/models/delete_model_connection_request.dart'
    as _im8o8464;
import 'features/model_connections/models/list_model_connections_request.dart'
    as _iuwdkoab;
import 'features/model_connections/models/list_workspace_model_selections_request.dart'
    as _i926jgxf;
import 'features/model_connections/models/model_connection_view.dart'
    as _ikk9qcnz;
import 'features/model_connections/models/model_sync_result.dart' as _il1l34li;
import 'features/model_connections/models/test_and_sync_model_connection_request.dart'
    as _ixyi2mo6;
import 'features/model_connections/models/update_model_connection_request.dart'
    as _iw5yf4pd;
import 'features/model_connections/models/workspace_model_connection.dart'
    as _ihf3aqrg;
import 'features/model_connections/models/workspace_model_selection_view.dart'
    as _i2zocl9o;
import 'features/objects/models/begin_upload_request.dart' as _ii7xucwd;
import 'features/objects/models/begin_upload_result.dart' as _iy4az4cb;
import 'features/objects/models/complete_upload_request.dart' as _ip871ox8;
import 'features/objects/models/delete_object_request.dart' as _iae520xs;
import 'features/objects/models/get_download_request.dart' as _i99cztt4;
import 'features/objects/models/get_download_result.dart' as _ip02joz1;
import 'features/objects/models/object_deletion.dart' as _ii2nljpm;
import 'features/objects/models/object_error_code.dart' as _ivy9wxc7;
import 'features/objects/models/object_exception.dart' as _i4o8es85;
import 'features/objects/models/object_reference.dart' as _ino5s3hv;
import 'features/objects/models/object_result.dart' as _is4lmm7s;
import 'features/objects/models/object_upload.dart' as _i6zmsyes;
import 'features/objects/models/workspace_object.dart' as _i52p5grh;
import 'features/sync/stream/models/workspace_stream_envelope.dart'
    as _i0ekjn7l;
import 'features/sync/stream/models/workspace_stream_envelope_kind.dart'
    as _i4zgsr0a;
import 'features/sync/stream/models/workspace_subscribe_request.dart'
    as _ig40wm3p;
import 'features/workers/models/recurring_worker_schedule.dart' as _ivj0myfi;
import 'features/workers/models/worker_coordinator_lease.dart' as _ifhsy8zv;
import 'features/workspace_state/models/mutate_workspace_credential_request.dart'
    as _io0q4g8e;
import 'features/workspace_state/models/mutate_workspace_credential_response.dart'
    as _ipy8xct6;
import 'features/workspace_state/models/patch_workspace_state_request.dart'
    as _ipvegfbn;
import 'features/workspace_state/models/patch_workspace_state_response.dart'
    as _ig93yftz;
import 'features/workspace_state/models/put_workspace_secret_request.dart'
    as _ipxnqptw;
import 'features/workspace_state/models/put_workspace_secret_response.dart'
    as _iavc361v;
import 'features/workspace_state/models/read_workspace_state_request.dart'
    as _iz7boq8w;
import 'features/workspace_state/models/read_workspace_state_response.dart'
    as _iqk6zto1;
import 'features/workspace_state/models/workspace_patch_operation.dart'
    as _iolo6w4a;
import 'features/workspace_state/models/workspace_patch_operation_kind.dart'
    as _ihbarnlu;
import 'features/workspace_state/models/workspace_resource.dart' as _iqzfyfs9;
import 'features/workspace_state/models/workspace_resource_kind.dart'
    as _i8d1xr9g;
import 'features/workspace_state/models/workspace_resource_page.dart'
    as _iilez6xa;
import 'features/workspace_state/models/workspace_resource_page_request.dart'
    as _i0vhsjed;
import 'features/workspace_state/models/workspace_secret.dart' as _iyjw9v2c;
import 'features/workspace_state/models/workspace_secret_kind.dart'
    as _iq96p1l9;
import 'features/workspace_state/models/workspace_secret_scope.dart'
    as _ioqbiy3d;
import 'features/workspaces/models/accept_workspace_invite_request.dart'
    as _ib7b2bmq;
import 'features/workspaces/models/cloud_workspace.dart' as _iyfjt29r;
import 'features/workspaces/models/cloud_workspace_capabilities.dart'
    as _i1uzipdf;
import 'features/workspaces/models/cloud_workspace_detail.dart' as _ixqnubu3;
import 'features/workspaces/models/cloud_workspace_error_code.dart'
    as _ikaytupt;
import 'features/workspaces/models/cloud_workspace_exception.dart' as _iq0v59d3;
import 'features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i4buxtw8;
import 'features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i3c64tpx;
import 'features/workspaces/models/cloud_workspace_summary.dart' as _iqlfhfv2;
import 'features/workspaces/models/create_cloud_workspace_request.dart'
    as _i2wx1hcz;
import 'features/workspaces/models/decline_workspace_invite_request.dart'
    as _izpvgmoh;
import 'features/workspaces/models/delete_cloud_workspace_request.dart'
    as _irqsg6pc;
import 'features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i3slgemv;
import 'features/workspaces/models/invite_workspace_member_request.dart'
    as _iojw3n39;
import 'features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i90hckxm;
import 'features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _ig64imxt;
import 'features/workspaces/models/list_workspace_members_request.dart'
    as _iop4tnuf;
import 'features/workspaces/models/pending_workspace_invite_summary.dart'
    as _imuwa8ax;
import 'features/workspaces/models/remove_workspace_member_request.dart'
    as _ioya5p5j;
import 'features/workspaces/models/rename_cloud_workspace_request.dart'
    as _ifsfc78n;
import 'features/workspaces/models/renew_workspace_invite_request.dart'
    as _ivko4e0f;
import 'features/workspaces/models/revoke_workspace_invite_request.dart'
    as _iwlbozzh;
import 'features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i7ana9ux;
import 'features/workspaces/models/update_workspace_member_role_request.dart'
    as _i2qmz98c;
import 'features/workspaces/models/workspace_audit_record.dart' as _ifp2sq2r;
import 'features/workspaces/models/workspace_event.dart' as _ivvnnphu;
import 'features/workspaces/models/workspace_invite.dart' as _ilpykuxc;
import 'features/workspaces/models/workspace_member.dart' as _i56tb1yu;
import 'features/workspaces/models/workspace_mutation_receipt.dart'
    as _ia614g7d;
export 'features/accounts/models/account_summary.dart';
export 'features/agents/models/agent_catalog_item.dart';
export 'features/agents/models/agent_catalog_page.dart';
export 'features/agents/models/agent_catalog_status.dart';
export 'features/agents/models/agent_catalog_type.dart';
export 'features/agents/models/agent_catalog_visibility.dart';
export 'features/agents/models/get_agent_resources_request.dart';
export 'features/agents/models/list_agents_request.dart';
export 'features/codex_oauth/models/codex_oauth_transaction.dart';
export 'features/codex_oauth/models/complete_codex_oauth_request.dart';
export 'features/codex_oauth/models/complete_codex_oauth_result.dart';
export 'features/codex_oauth/models/start_codex_oauth_request.dart';
export 'features/codex_oauth/models/start_codex_oauth_result.dart';
export 'features/conversations/models/cancel_turn_request.dart';
export 'features/conversations/models/compact_conversation_request.dart';
export 'features/conversations/models/continue_conversation_request.dart';
export 'features/conversations/models/continue_turn_request.dart';
export 'features/conversations/models/conversation.dart';
export 'features/conversations/models/conversation_error_code.dart';
export 'features/conversations/models/conversation_event.dart';
export 'features/conversations/models/conversation_event_type.dart';
export 'features/conversations/models/conversation_exception.dart';
export 'features/conversations/models/conversation_execution.dart';
export 'features/conversations/models/conversation_execution_view.dart';
export 'features/conversations/models/conversation_job.dart';
export 'features/conversations/models/conversation_message.dart';
export 'features/conversations/models/conversation_message_view.dart';
export 'features/conversations/models/conversation_mutation_result.dart';
export 'features/conversations/models/conversation_page.dart';
export 'features/conversations/models/conversation_projection_view.dart';
export 'features/conversations/models/conversation_snapshot.dart';
export 'features/conversations/models/conversation_stream_event.dart';
export 'features/conversations/models/conversation_subscribe_request.dart';
export 'features/conversations/models/conversation_summary.dart';
export 'features/conversations/models/conversation_tool_call.dart';
export 'features/conversations/models/conversation_tool_call_view.dart';
export 'features/conversations/models/conversation_turn.dart';
export 'features/conversations/models/conversation_turn_view.dart';
export 'features/conversations/models/conversation_usage.dart';
export 'features/conversations/models/create_conversation_request.dart';
export 'features/conversations/models/delete_conversation_request.dart';
export 'features/conversations/models/edit_pending_conversation_message_request.dart';
export 'features/conversations/models/get_conversation_request.dart';
export 'features/conversations/models/get_turn_request.dart';
export 'features/conversations/models/list_conversation_messages_request.dart';
export 'features/conversations/models/list_conversations_request.dart';
export 'features/conversations/models/provider_admission.dart';
export 'features/conversations/models/provider_admission_lock.dart';
export 'features/conversations/models/provider_admission_reservation.dart';
export 'features/conversations/models/queue_conversation_message_request.dart';
export 'features/conversations/models/remove_pending_conversation_message_request.dart';
export 'features/conversations/models/reorder_pending_conversation_message_request.dart';
export 'features/conversations/models/start_turn_request.dart';
export 'features/conversations/models/start_turn_result.dart';
export 'features/conversations/models/stop_conversation_request.dart';
export 'features/conversations/models/submit_tool_decision_request.dart';
export 'features/conversations/models/turn_snapshot.dart';
export 'features/conversations/models/update_conversation_request.dart';
export 'features/conversations/models/update_conversation_settings_request.dart';
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
export 'features/workers/models/recurring_worker_schedule.dart';
export 'features/workers/models/worker_coordinator_lease.dart';
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
export 'client.dart';

class Protocol extends _isc.SerializationManager {
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
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i0kh9vnq.AccountSummary) {
      return _i0kh9vnq.AccountSummary.fromJson(data) as T;
    }
    if (t == _iczr9u8f.AgentCatalogItem) {
      return _iczr9u8f.AgentCatalogItem.fromJson(data) as T;
    }
    if (t == _ib4whsrz.AgentCatalogPage) {
      return _ib4whsrz.AgentCatalogPage.fromJson(data) as T;
    }
    if (t == _i0h0m7az.AgentCatalogStatus) {
      return _i0h0m7az.AgentCatalogStatus.fromJson(data) as T;
    }
    if (t == _icsw3jh1.AgentCatalogType) {
      return _icsw3jh1.AgentCatalogType.fromJson(data) as T;
    }
    if (t == _izubbx9m.AgentCatalogVisibility) {
      return _izubbx9m.AgentCatalogVisibility.fromJson(data) as T;
    }
    if (t == _i84solqu.GetAgentResourcesRequest) {
      return _i84solqu.GetAgentResourcesRequest.fromJson(data) as T;
    }
    if (t == _ilueer9m.ListAgentsRequest) {
      return _ilueer9m.ListAgentsRequest.fromJson(data) as T;
    }
    if (t == _ify5ufwn.CodexOAuthTransaction) {
      return _ify5ufwn.CodexOAuthTransaction.fromJson(data) as T;
    }
    if (t == _i2qdkbo8.CompleteCodexOAuthRequest) {
      return _i2qdkbo8.CompleteCodexOAuthRequest.fromJson(data) as T;
    }
    if (t == _ibhl6ekj.CompleteCodexOAuthResult) {
      return _ibhl6ekj.CompleteCodexOAuthResult.fromJson(data) as T;
    }
    if (t == _iv7ukgnj.StartCodexOAuthRequest) {
      return _iv7ukgnj.StartCodexOAuthRequest.fromJson(data) as T;
    }
    if (t == _itptq7z5.StartCodexOAuthResult) {
      return _itptq7z5.StartCodexOAuthResult.fromJson(data) as T;
    }
    if (t == _iarqshx6.CancelTurnRequest) {
      return _iarqshx6.CancelTurnRequest.fromJson(data) as T;
    }
    if (t == _isyd7s84.CompactConversationRequest) {
      return _isyd7s84.CompactConversationRequest.fromJson(data) as T;
    }
    if (t == _ialxa16r.ContinueConversationRequest) {
      return _ialxa16r.ContinueConversationRequest.fromJson(data) as T;
    }
    if (t == _iwrs6sde.ContinueTurnRequest) {
      return _iwrs6sde.ContinueTurnRequest.fromJson(data) as T;
    }
    if (t == _iivijtsr.Conversation) {
      return _iivijtsr.Conversation.fromJson(data) as T;
    }
    if (t == _iz6esn7o.ConversationErrorCode) {
      return _iz6esn7o.ConversationErrorCode.fromJson(data) as T;
    }
    if (t == _i77s958n.ConversationEvent) {
      return _i77s958n.ConversationEvent.fromJson(data) as T;
    }
    if (t == _i5gn99j4.ConversationEventType) {
      return _i5gn99j4.ConversationEventType.fromJson(data) as T;
    }
    if (t == _i4box1gt.ConversationException) {
      return _i4box1gt.ConversationException.fromJson(data) as T;
    }
    if (t == _iznwbo5b.ConversationExecution) {
      return _iznwbo5b.ConversationExecution.fromJson(data) as T;
    }
    if (t == _ij9w9f8d.ConversationExecutionView) {
      return _ij9w9f8d.ConversationExecutionView.fromJson(data) as T;
    }
    if (t == _iq1eovrr.ConversationJob) {
      return _iq1eovrr.ConversationJob.fromJson(data) as T;
    }
    if (t == _ibea51bx.ConversationMessage) {
      return _ibea51bx.ConversationMessage.fromJson(data) as T;
    }
    if (t == _iutotoh6.ConversationMessageView) {
      return _iutotoh6.ConversationMessageView.fromJson(data) as T;
    }
    if (t == _iz02ruas.ConversationMutationResult) {
      return _iz02ruas.ConversationMutationResult.fromJson(data) as T;
    }
    if (t == _icl1rfiv.ConversationPage) {
      return _icl1rfiv.ConversationPage.fromJson(data) as T;
    }
    if (t == _icx9bns3.ConversationProjectionView) {
      return _icx9bns3.ConversationProjectionView.fromJson(data) as T;
    }
    if (t == _i4omaws8.ConversationSnapshot) {
      return _i4omaws8.ConversationSnapshot.fromJson(data) as T;
    }
    if (t == _irrmkjcu.ConversationStreamEvent) {
      return _irrmkjcu.ConversationStreamEvent.fromJson(data) as T;
    }
    if (t == _i6hxcode.ConversationSubscribeRequest) {
      return _i6hxcode.ConversationSubscribeRequest.fromJson(data) as T;
    }
    if (t == _i7a0mfc5.ConversationSummary) {
      return _i7a0mfc5.ConversationSummary.fromJson(data) as T;
    }
    if (t == _iflac717.ConversationToolCall) {
      return _iflac717.ConversationToolCall.fromJson(data) as T;
    }
    if (t == _ic5ojtne.ConversationToolCallView) {
      return _ic5ojtne.ConversationToolCallView.fromJson(data) as T;
    }
    if (t == _i7mmki1w.ConversationTurn) {
      return _i7mmki1w.ConversationTurn.fromJson(data) as T;
    }
    if (t == _ir5w321b.ConversationTurnView) {
      return _ir5w321b.ConversationTurnView.fromJson(data) as T;
    }
    if (t == _iii6xlqw.ConversationUsage) {
      return _iii6xlqw.ConversationUsage.fromJson(data) as T;
    }
    if (t == _i4shnjby.CreateConversationRequest) {
      return _i4shnjby.CreateConversationRequest.fromJson(data) as T;
    }
    if (t == _iqsppx3t.DeleteConversationRequest) {
      return _iqsppx3t.DeleteConversationRequest.fromJson(data) as T;
    }
    if (t == _iybdpw96.EditPendingConversationMessageRequest) {
      return _iybdpw96.EditPendingConversationMessageRequest.fromJson(data)
          as T;
    }
    if (t == _ixb0z1tn.GetConversationRequest) {
      return _ixb0z1tn.GetConversationRequest.fromJson(data) as T;
    }
    if (t == _ilyvwvdb.GetTurnRequest) {
      return _ilyvwvdb.GetTurnRequest.fromJson(data) as T;
    }
    if (t == _it91nt4l.ListConversationMessagesRequest) {
      return _it91nt4l.ListConversationMessagesRequest.fromJson(data) as T;
    }
    if (t == _itcpel99.ListConversationsRequest) {
      return _itcpel99.ListConversationsRequest.fromJson(data) as T;
    }
    if (t == _i32k4voa.ProviderAdmission) {
      return _i32k4voa.ProviderAdmission.fromJson(data) as T;
    }
    if (t == _ih2np1vh.ProviderAdmissionLock) {
      return _ih2np1vh.ProviderAdmissionLock.fromJson(data) as T;
    }
    if (t == _i7moywui.ProviderAdmissionReservation) {
      return _i7moywui.ProviderAdmissionReservation.fromJson(data) as T;
    }
    if (t == _ido51m94.QueueConversationMessageRequest) {
      return _ido51m94.QueueConversationMessageRequest.fromJson(data) as T;
    }
    if (t == _iy526sio.RemovePendingConversationMessageRequest) {
      return _iy526sio.RemovePendingConversationMessageRequest.fromJson(data)
          as T;
    }
    if (t == _infbxzxr.ReorderPendingConversationMessageRequest) {
      return _infbxzxr.ReorderPendingConversationMessageRequest.fromJson(data)
          as T;
    }
    if (t == _iocu6u94.StartTurnRequest) {
      return _iocu6u94.StartTurnRequest.fromJson(data) as T;
    }
    if (t == _iw8le0j7.StartTurnResult) {
      return _iw8le0j7.StartTurnResult.fromJson(data) as T;
    }
    if (t == _i4cgq7zt.StopConversationRequest) {
      return _i4cgq7zt.StopConversationRequest.fromJson(data) as T;
    }
    if (t == _inla43mu.SubmitToolDecisionRequest) {
      return _inla43mu.SubmitToolDecisionRequest.fromJson(data) as T;
    }
    if (t == _ih4jnnah.TurnSnapshot) {
      return _ih4jnnah.TurnSnapshot.fromJson(data) as T;
    }
    if (t == _ihs4d7mz.UpdateConversationRequest) {
      return _ihs4d7mz.UpdateConversationRequest.fromJson(data) as T;
    }
    if (t == _i8unm495.UpdateConversationSettingsRequest) {
      return _i8unm495.UpdateConversationSettingsRequest.fromJson(data) as T;
    }
    if (t == _i6hg2xtf.CreateMcpServerRequest) {
      return _i6hg2xtf.CreateMcpServerRequest.fromJson(data) as T;
    }
    if (t == _ihyupc89.CreateMcpServerResult) {
      return _ihyupc89.CreateMcpServerResult.fromJson(data) as T;
    }
    if (t == _iabui7vl.DeleteMcpServerRequest) {
      return _iabui7vl.DeleteMcpServerRequest.fromJson(data) as T;
    }
    if (t == _ilmfigs5.DiscoverMcpServerRequest) {
      return _ilmfigs5.DiscoverMcpServerRequest.fromJson(data) as T;
    }
    if (t == _i5i328k3.DiscoverMcpServerResult) {
      return _i5i328k3.DiscoverMcpServerResult.fromJson(data) as T;
    }
    if (t == _igzjg3pi.DiscoveredMcpTool) {
      return _igzjg3pi.DiscoveredMcpTool.fromJson(data) as T;
    }
    if (t == _iw1ftww6.McpServerHealth) {
      return _iw1ftww6.McpServerHealth.fromJson(data) as T;
    }
    if (t == _i8ct1fsr.ApiModel) {
      return _i8ct1fsr.ApiModel.fromJson(data) as T;
    }
    if (t == _ioo5yu9z.ApiModelProvider) {
      return _ioo5yu9z.ApiModelProvider.fromJson(data) as T;
    }
    if (t == _i4akrsd1.CreateModelConnectionRequest) {
      return _i4akrsd1.CreateModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _im8o8464.DeleteModelConnectionRequest) {
      return _im8o8464.DeleteModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _iuwdkoab.ListModelConnectionsRequest) {
      return _iuwdkoab.ListModelConnectionsRequest.fromJson(data) as T;
    }
    if (t == _i926jgxf.ListWorkspaceModelSelectionsRequest) {
      return _i926jgxf.ListWorkspaceModelSelectionsRequest.fromJson(data) as T;
    }
    if (t == _ikk9qcnz.ModelConnectionView) {
      return _ikk9qcnz.ModelConnectionView.fromJson(data) as T;
    }
    if (t == _il1l34li.ModelSyncResult) {
      return _il1l34li.ModelSyncResult.fromJson(data) as T;
    }
    if (t == _ixyi2mo6.TestAndSyncModelConnectionRequest) {
      return _ixyi2mo6.TestAndSyncModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _iw5yf4pd.UpdateModelConnectionRequest) {
      return _iw5yf4pd.UpdateModelConnectionRequest.fromJson(data) as T;
    }
    if (t == _ihf3aqrg.WorkspaceModelConnection) {
      return _ihf3aqrg.WorkspaceModelConnection.fromJson(data) as T;
    }
    if (t == _i2zocl9o.WorkspaceModelSelectionView) {
      return _i2zocl9o.WorkspaceModelSelectionView.fromJson(data) as T;
    }
    if (t == _ii7xucwd.BeginUploadRequest) {
      return _ii7xucwd.BeginUploadRequest.fromJson(data) as T;
    }
    if (t == _iy4az4cb.BeginUploadResult) {
      return _iy4az4cb.BeginUploadResult.fromJson(data) as T;
    }
    if (t == _ip871ox8.CompleteUploadRequest) {
      return _ip871ox8.CompleteUploadRequest.fromJson(data) as T;
    }
    if (t == _iae520xs.DeleteObjectRequest) {
      return _iae520xs.DeleteObjectRequest.fromJson(data) as T;
    }
    if (t == _i99cztt4.GetDownloadRequest) {
      return _i99cztt4.GetDownloadRequest.fromJson(data) as T;
    }
    if (t == _ip02joz1.GetDownloadResult) {
      return _ip02joz1.GetDownloadResult.fromJson(data) as T;
    }
    if (t == _ii2nljpm.ObjectDeletion) {
      return _ii2nljpm.ObjectDeletion.fromJson(data) as T;
    }
    if (t == _ivy9wxc7.ObjectErrorCode) {
      return _ivy9wxc7.ObjectErrorCode.fromJson(data) as T;
    }
    if (t == _i4o8es85.ObjectException) {
      return _i4o8es85.ObjectException.fromJson(data) as T;
    }
    if (t == _ino5s3hv.ObjectReference) {
      return _ino5s3hv.ObjectReference.fromJson(data) as T;
    }
    if (t == _is4lmm7s.ObjectResult) {
      return _is4lmm7s.ObjectResult.fromJson(data) as T;
    }
    if (t == _i6zmsyes.ObjectUpload) {
      return _i6zmsyes.ObjectUpload.fromJson(data) as T;
    }
    if (t == _i52p5grh.WorkspaceObject) {
      return _i52p5grh.WorkspaceObject.fromJson(data) as T;
    }
    if (t == _i0ekjn7l.WorkspaceStreamEnvelope) {
      return _i0ekjn7l.WorkspaceStreamEnvelope.fromJson(data) as T;
    }
    if (t == _i4zgsr0a.WorkspaceStreamEnvelopeKind) {
      return _i4zgsr0a.WorkspaceStreamEnvelopeKind.fromJson(data) as T;
    }
    if (t == _ig40wm3p.WorkspaceSubscribeRequest) {
      return _ig40wm3p.WorkspaceSubscribeRequest.fromJson(data) as T;
    }
    if (t == _ivj0myfi.RecurringWorkerSchedule) {
      return _ivj0myfi.RecurringWorkerSchedule.fromJson(data) as T;
    }
    if (t == _ifhsy8zv.WorkerCoordinatorLease) {
      return _ifhsy8zv.WorkerCoordinatorLease.fromJson(data) as T;
    }
    if (t == _io0q4g8e.MutateWorkspaceCredentialRequest) {
      return _io0q4g8e.MutateWorkspaceCredentialRequest.fromJson(data) as T;
    }
    if (t == _ipy8xct6.MutateWorkspaceCredentialResponse) {
      return _ipy8xct6.MutateWorkspaceCredentialResponse.fromJson(data) as T;
    }
    if (t == _ipvegfbn.PatchWorkspaceStateRequest) {
      return _ipvegfbn.PatchWorkspaceStateRequest.fromJson(data) as T;
    }
    if (t == _ig93yftz.PatchWorkspaceStateResponse) {
      return _ig93yftz.PatchWorkspaceStateResponse.fromJson(data) as T;
    }
    if (t == _ipxnqptw.PutWorkspaceSecretRequest) {
      return _ipxnqptw.PutWorkspaceSecretRequest.fromJson(data) as T;
    }
    if (t == _iavc361v.PutWorkspaceSecretResponse) {
      return _iavc361v.PutWorkspaceSecretResponse.fromJson(data) as T;
    }
    if (t == _iz7boq8w.ReadWorkspaceStateRequest) {
      return _iz7boq8w.ReadWorkspaceStateRequest.fromJson(data) as T;
    }
    if (t == _iqk6zto1.ReadWorkspaceStateResponse) {
      return _iqk6zto1.ReadWorkspaceStateResponse.fromJson(data) as T;
    }
    if (t == _iolo6w4a.WorkspacePatchOperation) {
      return _iolo6w4a.WorkspacePatchOperation.fromJson(data) as T;
    }
    if (t == _ihbarnlu.WorkspacePatchOperationKind) {
      return _ihbarnlu.WorkspacePatchOperationKind.fromJson(data) as T;
    }
    if (t == _iqzfyfs9.WorkspaceResource) {
      return _iqzfyfs9.WorkspaceResource.fromJson(data) as T;
    }
    if (t == _i8d1xr9g.WorkspaceResourceKind) {
      return _i8d1xr9g.WorkspaceResourceKind.fromJson(data) as T;
    }
    if (t == _iilez6xa.WorkspaceResourcePage) {
      return _iilez6xa.WorkspaceResourcePage.fromJson(data) as T;
    }
    if (t == _i0vhsjed.WorkspaceResourcePageRequest) {
      return _i0vhsjed.WorkspaceResourcePageRequest.fromJson(data) as T;
    }
    if (t == _iyjw9v2c.WorkspaceSecret) {
      return _iyjw9v2c.WorkspaceSecret.fromJson(data) as T;
    }
    if (t == _iq96p1l9.WorkspaceSecretKind) {
      return _iq96p1l9.WorkspaceSecretKind.fromJson(data) as T;
    }
    if (t == _ioqbiy3d.WorkspaceSecretScope) {
      return _ioqbiy3d.WorkspaceSecretScope.fromJson(data) as T;
    }
    if (t == _ib7b2bmq.AcceptWorkspaceInviteRequest) {
      return _ib7b2bmq.AcceptWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _iyfjt29r.CloudWorkspace) {
      return _iyfjt29r.CloudWorkspace.fromJson(data) as T;
    }
    if (t == _i1uzipdf.CloudWorkspaceCapabilities) {
      return _i1uzipdf.CloudWorkspaceCapabilities.fromJson(data) as T;
    }
    if (t == _ixqnubu3.CloudWorkspaceDetail) {
      return _ixqnubu3.CloudWorkspaceDetail.fromJson(data) as T;
    }
    if (t == _ikaytupt.CloudWorkspaceErrorCode) {
      return _ikaytupt.CloudWorkspaceErrorCode.fromJson(data) as T;
    }
    if (t == _iq0v59d3.CloudWorkspaceException) {
      return _iq0v59d3.CloudWorkspaceException.fromJson(data) as T;
    }
    if (t == _i4buxtw8.CloudWorkspaceInviteSummary) {
      return _i4buxtw8.CloudWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _i3c64tpx.CloudWorkspaceMemberSummary) {
      return _i3c64tpx.CloudWorkspaceMemberSummary.fromJson(data) as T;
    }
    if (t == _iqlfhfv2.CloudWorkspaceSummary) {
      return _iqlfhfv2.CloudWorkspaceSummary.fromJson(data) as T;
    }
    if (t == _i2wx1hcz.CreateCloudWorkspaceRequest) {
      return _i2wx1hcz.CreateCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _izpvgmoh.DeclineWorkspaceInviteRequest) {
      return _izpvgmoh.DeclineWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _irqsg6pc.DeleteCloudWorkspaceRequest) {
      return _irqsg6pc.DeleteCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _i3slgemv.GetCloudWorkspaceDetailRequest) {
      return _i3slgemv.GetCloudWorkspaceDetailRequest.fromJson(data) as T;
    }
    if (t == _iojw3n39.InviteWorkspaceMemberRequest) {
      return _iojw3n39.InviteWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _i90hckxm.LeaveCloudWorkspaceRequest) {
      return _i90hckxm.LeaveCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _ig64imxt.ListCloudWorkspaceInvitesRequest) {
      return _ig64imxt.ListCloudWorkspaceInvitesRequest.fromJson(data) as T;
    }
    if (t == _iop4tnuf.ListWorkspaceMembersRequest) {
      return _iop4tnuf.ListWorkspaceMembersRequest.fromJson(data) as T;
    }
    if (t == _imuwa8ax.PendingWorkspaceInviteSummary) {
      return _imuwa8ax.PendingWorkspaceInviteSummary.fromJson(data) as T;
    }
    if (t == _ioya5p5j.RemoveWorkspaceMemberRequest) {
      return _ioya5p5j.RemoveWorkspaceMemberRequest.fromJson(data) as T;
    }
    if (t == _ifsfc78n.RenameCloudWorkspaceRequest) {
      return _ifsfc78n.RenameCloudWorkspaceRequest.fromJson(data) as T;
    }
    if (t == _ivko4e0f.RenewWorkspaceInviteRequest) {
      return _ivko4e0f.RenewWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _iwlbozzh.RevokeWorkspaceInviteRequest) {
      return _iwlbozzh.RevokeWorkspaceInviteRequest.fromJson(data) as T;
    }
    if (t == _i7ana9ux.TransferCloudWorkspaceOwnershipRequest) {
      return _i7ana9ux.TransferCloudWorkspaceOwnershipRequest.fromJson(data)
          as T;
    }
    if (t == _i2qmz98c.UpdateWorkspaceMemberRoleRequest) {
      return _i2qmz98c.UpdateWorkspaceMemberRoleRequest.fromJson(data) as T;
    }
    if (t == _ifp2sq2r.WorkspaceAuditRecord) {
      return _ifp2sq2r.WorkspaceAuditRecord.fromJson(data) as T;
    }
    if (t == _ivvnnphu.WorkspaceEvent) {
      return _ivvnnphu.WorkspaceEvent.fromJson(data) as T;
    }
    if (t == _ilpykuxc.WorkspaceInvite) {
      return _ilpykuxc.WorkspaceInvite.fromJson(data) as T;
    }
    if (t == _i56tb1yu.WorkspaceMember) {
      return _i56tb1yu.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _ia614g7d.WorkspaceMutationReceipt) {
      return _ia614g7d.WorkspaceMutationReceipt.fromJson(data) as T;
    }
    if (t == _isc.getType<_i0kh9vnq.AccountSummary?>()) {
      return (data != null ? _i0kh9vnq.AccountSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iczr9u8f.AgentCatalogItem?>()) {
      return (data != null ? _iczr9u8f.AgentCatalogItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ib4whsrz.AgentCatalogPage?>()) {
      return (data != null ? _ib4whsrz.AgentCatalogPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0h0m7az.AgentCatalogStatus?>()) {
      return (data != null ? _i0h0m7az.AgentCatalogStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icsw3jh1.AgentCatalogType?>()) {
      return (data != null ? _icsw3jh1.AgentCatalogType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izubbx9m.AgentCatalogVisibility?>()) {
      return (data != null
              ? _izubbx9m.AgentCatalogVisibility.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i84solqu.GetAgentResourcesRequest?>()) {
      return (data != null
              ? _i84solqu.GetAgentResourcesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ilueer9m.ListAgentsRequest?>()) {
      return (data != null ? _ilueer9m.ListAgentsRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ify5ufwn.CodexOAuthTransaction?>()) {
      return (data != null
              ? _ify5ufwn.CodexOAuthTransaction.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2qdkbo8.CompleteCodexOAuthRequest?>()) {
      return (data != null
              ? _i2qdkbo8.CompleteCodexOAuthRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ibhl6ekj.CompleteCodexOAuthResult?>()) {
      return (data != null
              ? _ibhl6ekj.CompleteCodexOAuthResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iv7ukgnj.StartCodexOAuthRequest?>()) {
      return (data != null
              ? _iv7ukgnj.StartCodexOAuthRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_itptq7z5.StartCodexOAuthResult?>()) {
      return (data != null
              ? _itptq7z5.StartCodexOAuthResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iarqshx6.CancelTurnRequest?>()) {
      return (data != null ? _iarqshx6.CancelTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isyd7s84.CompactConversationRequest?>()) {
      return (data != null
              ? _isyd7s84.CompactConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ialxa16r.ContinueConversationRequest?>()) {
      return (data != null
              ? _ialxa16r.ContinueConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iwrs6sde.ContinueTurnRequest?>()) {
      return (data != null
              ? _iwrs6sde.ContinueTurnRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iivijtsr.Conversation?>()) {
      return (data != null ? _iivijtsr.Conversation.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iz6esn7o.ConversationErrorCode?>()) {
      return (data != null
              ? _iz6esn7o.ConversationErrorCode.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i77s958n.ConversationEvent?>()) {
      return (data != null ? _i77s958n.ConversationEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5gn99j4.ConversationEventType?>()) {
      return (data != null
              ? _i5gn99j4.ConversationEventType.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4box1gt.ConversationException?>()) {
      return (data != null
              ? _i4box1gt.ConversationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iznwbo5b.ConversationExecution?>()) {
      return (data != null
              ? _iznwbo5b.ConversationExecution.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ij9w9f8d.ConversationExecutionView?>()) {
      return (data != null
              ? _ij9w9f8d.ConversationExecutionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq1eovrr.ConversationJob?>()) {
      return (data != null ? _iq1eovrr.ConversationJob.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ibea51bx.ConversationMessage?>()) {
      return (data != null
              ? _ibea51bx.ConversationMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iutotoh6.ConversationMessageView?>()) {
      return (data != null
              ? _iutotoh6.ConversationMessageView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz02ruas.ConversationMutationResult?>()) {
      return (data != null
              ? _iz02ruas.ConversationMutationResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icl1rfiv.ConversationPage?>()) {
      return (data != null ? _icl1rfiv.ConversationPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icx9bns3.ConversationProjectionView?>()) {
      return (data != null
              ? _icx9bns3.ConversationProjectionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4omaws8.ConversationSnapshot?>()) {
      return (data != null
              ? _i4omaws8.ConversationSnapshot.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_irrmkjcu.ConversationStreamEvent?>()) {
      return (data != null
              ? _irrmkjcu.ConversationStreamEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i6hxcode.ConversationSubscribeRequest?>()) {
      return (data != null
              ? _i6hxcode.ConversationSubscribeRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7a0mfc5.ConversationSummary?>()) {
      return (data != null
              ? _i7a0mfc5.ConversationSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iflac717.ConversationToolCall?>()) {
      return (data != null
              ? _iflac717.ConversationToolCall.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ic5ojtne.ConversationToolCallView?>()) {
      return (data != null
              ? _ic5ojtne.ConversationToolCallView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7mmki1w.ConversationTurn?>()) {
      return (data != null ? _i7mmki1w.ConversationTurn.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ir5w321b.ConversationTurnView?>()) {
      return (data != null
              ? _ir5w321b.ConversationTurnView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iii6xlqw.ConversationUsage?>()) {
      return (data != null ? _iii6xlqw.ConversationUsage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4shnjby.CreateConversationRequest?>()) {
      return (data != null
              ? _i4shnjby.CreateConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqsppx3t.DeleteConversationRequest?>()) {
      return (data != null
              ? _iqsppx3t.DeleteConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iybdpw96.EditPendingConversationMessageRequest?>()) {
      return (data != null
              ? _iybdpw96.EditPendingConversationMessageRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ixb0z1tn.GetConversationRequest?>()) {
      return (data != null
              ? _ixb0z1tn.GetConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ilyvwvdb.GetTurnRequest?>()) {
      return (data != null ? _ilyvwvdb.GetTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_it91nt4l.ListConversationMessagesRequest?>()) {
      return (data != null
              ? _it91nt4l.ListConversationMessagesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_itcpel99.ListConversationsRequest?>()) {
      return (data != null
              ? _itcpel99.ListConversationsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i32k4voa.ProviderAdmission?>()) {
      return (data != null ? _i32k4voa.ProviderAdmission.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ih2np1vh.ProviderAdmissionLock?>()) {
      return (data != null
              ? _ih2np1vh.ProviderAdmissionLock.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7moywui.ProviderAdmissionReservation?>()) {
      return (data != null
              ? _i7moywui.ProviderAdmissionReservation.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ido51m94.QueueConversationMessageRequest?>()) {
      return (data != null
              ? _ido51m94.QueueConversationMessageRequest.fromJson(data)
              : null)
          as T;
    }
    if (t ==
        _isc.getType<_iy526sio.RemovePendingConversationMessageRequest?>()) {
      return (data != null
              ? _iy526sio.RemovePendingConversationMessageRequest.fromJson(data)
              : null)
          as T;
    }
    if (t ==
        _isc.getType<_infbxzxr.ReorderPendingConversationMessageRequest?>()) {
      return (data != null
              ? _infbxzxr.ReorderPendingConversationMessageRequest.fromJson(
                  data,
                )
              : null)
          as T;
    }
    if (t == _isc.getType<_iocu6u94.StartTurnRequest?>()) {
      return (data != null ? _iocu6u94.StartTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iw8le0j7.StartTurnResult?>()) {
      return (data != null ? _iw8le0j7.StartTurnResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4cgq7zt.StopConversationRequest?>()) {
      return (data != null
              ? _i4cgq7zt.StopConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_inla43mu.SubmitToolDecisionRequest?>()) {
      return (data != null
              ? _inla43mu.SubmitToolDecisionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ih4jnnah.TurnSnapshot?>()) {
      return (data != null ? _ih4jnnah.TurnSnapshot.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihs4d7mz.UpdateConversationRequest?>()) {
      return (data != null
              ? _ihs4d7mz.UpdateConversationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i8unm495.UpdateConversationSettingsRequest?>()) {
      return (data != null
              ? _i8unm495.UpdateConversationSettingsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i6hg2xtf.CreateMcpServerRequest?>()) {
      return (data != null
              ? _i6hg2xtf.CreateMcpServerRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ihyupc89.CreateMcpServerResult?>()) {
      return (data != null
              ? _ihyupc89.CreateMcpServerResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iabui7vl.DeleteMcpServerRequest?>()) {
      return (data != null
              ? _iabui7vl.DeleteMcpServerRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ilmfigs5.DiscoverMcpServerRequest?>()) {
      return (data != null
              ? _ilmfigs5.DiscoverMcpServerRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5i328k3.DiscoverMcpServerResult?>()) {
      return (data != null
              ? _i5i328k3.DiscoverMcpServerResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_igzjg3pi.DiscoveredMcpTool?>()) {
      return (data != null ? _igzjg3pi.DiscoveredMcpTool.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iw1ftww6.McpServerHealth?>()) {
      return (data != null ? _iw1ftww6.McpServerHealth.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8ct1fsr.ApiModel?>()) {
      return (data != null ? _i8ct1fsr.ApiModel.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ioo5yu9z.ApiModelProvider?>()) {
      return (data != null ? _ioo5yu9z.ApiModelProvider.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4akrsd1.CreateModelConnectionRequest?>()) {
      return (data != null
              ? _i4akrsd1.CreateModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_im8o8464.DeleteModelConnectionRequest?>()) {
      return (data != null
              ? _im8o8464.DeleteModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iuwdkoab.ListModelConnectionsRequest?>()) {
      return (data != null
              ? _iuwdkoab.ListModelConnectionsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i926jgxf.ListWorkspaceModelSelectionsRequest?>()) {
      return (data != null
              ? _i926jgxf.ListWorkspaceModelSelectionsRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ikk9qcnz.ModelConnectionView?>()) {
      return (data != null
              ? _ikk9qcnz.ModelConnectionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_il1l34li.ModelSyncResult?>()) {
      return (data != null ? _il1l34li.ModelSyncResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixyi2mo6.TestAndSyncModelConnectionRequest?>()) {
      return (data != null
              ? _ixyi2mo6.TestAndSyncModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iw5yf4pd.UpdateModelConnectionRequest?>()) {
      return (data != null
              ? _iw5yf4pd.UpdateModelConnectionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ihf3aqrg.WorkspaceModelConnection?>()) {
      return (data != null
              ? _ihf3aqrg.WorkspaceModelConnection.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2zocl9o.WorkspaceModelSelectionView?>()) {
      return (data != null
              ? _i2zocl9o.WorkspaceModelSelectionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ii7xucwd.BeginUploadRequest?>()) {
      return (data != null ? _ii7xucwd.BeginUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iy4az4cb.BeginUploadResult?>()) {
      return (data != null ? _iy4az4cb.BeginUploadResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ip871ox8.CompleteUploadRequest?>()) {
      return (data != null
              ? _ip871ox8.CompleteUploadRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iae520xs.DeleteObjectRequest?>()) {
      return (data != null
              ? _iae520xs.DeleteObjectRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i99cztt4.GetDownloadRequest?>()) {
      return (data != null ? _i99cztt4.GetDownloadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ip02joz1.GetDownloadResult?>()) {
      return (data != null ? _ip02joz1.GetDownloadResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ii2nljpm.ObjectDeletion?>()) {
      return (data != null ? _ii2nljpm.ObjectDeletion.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivy9wxc7.ObjectErrorCode?>()) {
      return (data != null ? _ivy9wxc7.ObjectErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4o8es85.ObjectException?>()) {
      return (data != null ? _i4o8es85.ObjectException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ino5s3hv.ObjectReference?>()) {
      return (data != null ? _ino5s3hv.ObjectReference.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_is4lmm7s.ObjectResult?>()) {
      return (data != null ? _is4lmm7s.ObjectResult.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6zmsyes.ObjectUpload?>()) {
      return (data != null ? _i6zmsyes.ObjectUpload.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i52p5grh.WorkspaceObject?>()) {
      return (data != null ? _i52p5grh.WorkspaceObject.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0ekjn7l.WorkspaceStreamEnvelope?>()) {
      return (data != null
              ? _i0ekjn7l.WorkspaceStreamEnvelope.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4zgsr0a.WorkspaceStreamEnvelopeKind?>()) {
      return (data != null
              ? _i4zgsr0a.WorkspaceStreamEnvelopeKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ig40wm3p.WorkspaceSubscribeRequest?>()) {
      return (data != null
              ? _ig40wm3p.WorkspaceSubscribeRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ivj0myfi.RecurringWorkerSchedule?>()) {
      return (data != null
              ? _ivj0myfi.RecurringWorkerSchedule.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ifhsy8zv.WorkerCoordinatorLease?>()) {
      return (data != null
              ? _ifhsy8zv.WorkerCoordinatorLease.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_io0q4g8e.MutateWorkspaceCredentialRequest?>()) {
      return (data != null
              ? _io0q4g8e.MutateWorkspaceCredentialRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ipy8xct6.MutateWorkspaceCredentialResponse?>()) {
      return (data != null
              ? _ipy8xct6.MutateWorkspaceCredentialResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ipvegfbn.PatchWorkspaceStateRequest?>()) {
      return (data != null
              ? _ipvegfbn.PatchWorkspaceStateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ig93yftz.PatchWorkspaceStateResponse?>()) {
      return (data != null
              ? _ig93yftz.PatchWorkspaceStateResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ipxnqptw.PutWorkspaceSecretRequest?>()) {
      return (data != null
              ? _ipxnqptw.PutWorkspaceSecretRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iavc361v.PutWorkspaceSecretResponse?>()) {
      return (data != null
              ? _iavc361v.PutWorkspaceSecretResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz7boq8w.ReadWorkspaceStateRequest?>()) {
      return (data != null
              ? _iz7boq8w.ReadWorkspaceStateRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqk6zto1.ReadWorkspaceStateResponse?>()) {
      return (data != null
              ? _iqk6zto1.ReadWorkspaceStateResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iolo6w4a.WorkspacePatchOperation?>()) {
      return (data != null
              ? _iolo6w4a.WorkspacePatchOperation.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ihbarnlu.WorkspacePatchOperationKind?>()) {
      return (data != null
              ? _ihbarnlu.WorkspacePatchOperationKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqzfyfs9.WorkspaceResource?>()) {
      return (data != null ? _iqzfyfs9.WorkspaceResource.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8d1xr9g.WorkspaceResourceKind?>()) {
      return (data != null
              ? _i8d1xr9g.WorkspaceResourceKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iilez6xa.WorkspaceResourcePage?>()) {
      return (data != null
              ? _iilez6xa.WorkspaceResourcePage.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i0vhsjed.WorkspaceResourcePageRequest?>()) {
      return (data != null
              ? _i0vhsjed.WorkspaceResourcePageRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iyjw9v2c.WorkspaceSecret?>()) {
      return (data != null ? _iyjw9v2c.WorkspaceSecret.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iq96p1l9.WorkspaceSecretKind?>()) {
      return (data != null
              ? _iq96p1l9.WorkspaceSecretKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ioqbiy3d.WorkspaceSecretScope?>()) {
      return (data != null
              ? _ioqbiy3d.WorkspaceSecretScope.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ib7b2bmq.AcceptWorkspaceInviteRequest?>()) {
      return (data != null
              ? _ib7b2bmq.AcceptWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iyfjt29r.CloudWorkspace?>()) {
      return (data != null ? _iyfjt29r.CloudWorkspace.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i1uzipdf.CloudWorkspaceCapabilities?>()) {
      return (data != null
              ? _i1uzipdf.CloudWorkspaceCapabilities.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ixqnubu3.CloudWorkspaceDetail?>()) {
      return (data != null
              ? _ixqnubu3.CloudWorkspaceDetail.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ikaytupt.CloudWorkspaceErrorCode?>()) {
      return (data != null
              ? _ikaytupt.CloudWorkspaceErrorCode.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq0v59d3.CloudWorkspaceException?>()) {
      return (data != null
              ? _iq0v59d3.CloudWorkspaceException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4buxtw8.CloudWorkspaceInviteSummary?>()) {
      return (data != null
              ? _i4buxtw8.CloudWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i3c64tpx.CloudWorkspaceMemberSummary?>()) {
      return (data != null
              ? _i3c64tpx.CloudWorkspaceMemberSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqlfhfv2.CloudWorkspaceSummary?>()) {
      return (data != null
              ? _iqlfhfv2.CloudWorkspaceSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2wx1hcz.CreateCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i2wx1hcz.CreateCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_izpvgmoh.DeclineWorkspaceInviteRequest?>()) {
      return (data != null
              ? _izpvgmoh.DeclineWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_irqsg6pc.DeleteCloudWorkspaceRequest?>()) {
      return (data != null
              ? _irqsg6pc.DeleteCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i3slgemv.GetCloudWorkspaceDetailRequest?>()) {
      return (data != null
              ? _i3slgemv.GetCloudWorkspaceDetailRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iojw3n39.InviteWorkspaceMemberRequest?>()) {
      return (data != null
              ? _iojw3n39.InviteWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i90hckxm.LeaveCloudWorkspaceRequest?>()) {
      return (data != null
              ? _i90hckxm.LeaveCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ig64imxt.ListCloudWorkspaceInvitesRequest?>()) {
      return (data != null
              ? _ig64imxt.ListCloudWorkspaceInvitesRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iop4tnuf.ListWorkspaceMembersRequest?>()) {
      return (data != null
              ? _iop4tnuf.ListWorkspaceMembersRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_imuwa8ax.PendingWorkspaceInviteSummary?>()) {
      return (data != null
              ? _imuwa8ax.PendingWorkspaceInviteSummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ioya5p5j.RemoveWorkspaceMemberRequest?>()) {
      return (data != null
              ? _ioya5p5j.RemoveWorkspaceMemberRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ifsfc78n.RenameCloudWorkspaceRequest?>()) {
      return (data != null
              ? _ifsfc78n.RenameCloudWorkspaceRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ivko4e0f.RenewWorkspaceInviteRequest?>()) {
      return (data != null
              ? _ivko4e0f.RenewWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iwlbozzh.RevokeWorkspaceInviteRequest?>()) {
      return (data != null
              ? _iwlbozzh.RevokeWorkspaceInviteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t ==
        _isc.getType<_i7ana9ux.TransferCloudWorkspaceOwnershipRequest?>()) {
      return (data != null
              ? _i7ana9ux.TransferCloudWorkspaceOwnershipRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2qmz98c.UpdateWorkspaceMemberRoleRequest?>()) {
      return (data != null
              ? _i2qmz98c.UpdateWorkspaceMemberRoleRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ifp2sq2r.WorkspaceAuditRecord?>()) {
      return (data != null
              ? _ifp2sq2r.WorkspaceAuditRecord.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ivvnnphu.WorkspaceEvent?>()) {
      return (data != null ? _ivvnnphu.WorkspaceEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ilpykuxc.WorkspaceInvite?>()) {
      return (data != null ? _ilpykuxc.WorkspaceInvite.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i56tb1yu.WorkspaceMember?>()) {
      return (data != null ? _i56tb1yu.WorkspaceMember.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ia614g7d.WorkspaceMutationReceipt?>()) {
      return (data != null
              ? _ia614g7d.WorkspaceMutationReceipt.fromJson(data)
              : null)
          as T;
    }
    if (t == List<_iczr9u8f.AgentCatalogItem>) {
      return (data as List)
              .map((e) => deserialize<_iczr9u8f.AgentCatalogItem>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_ic5ojtne.ConversationToolCallView>) {
      return (data as List)
              .map((e) => deserialize<_ic5ojtne.ConversationToolCallView>(e))
              .toList()
          as T;
    }
    if (t == List<_i7a0mfc5.ConversationSummary>) {
      return (data as List)
              .map((e) => deserialize<_i7a0mfc5.ConversationSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_iutotoh6.ConversationMessageView>) {
      return (data as List)
              .map((e) => deserialize<_iutotoh6.ConversationMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_igzjg3pi.DiscoveredMcpTool>) {
      return (data as List)
              .map((e) => deserialize<_igzjg3pi.DiscoveredMcpTool>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
        (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
      ) as T;
    }
    if (t == List<_iolo6w4a.WorkspacePatchOperation>) {
      return (data as List)
              .map((e) => deserialize<_iolo6w4a.WorkspacePatchOperation>(e))
              .toList()
          as T;
    }
    if (t == List<_iqzfyfs9.WorkspaceResource>) {
      return (data as List)
              .map((e) => deserialize<_iqzfyfs9.WorkspaceResource>(e))
              .toList()
          as T;
    }
    if (t == List<_i0vhsjed.WorkspaceResourcePageRequest>) {
      return (data as List)
              .map(
                (e) => deserialize<_i0vhsjed.WorkspaceResourcePageRequest>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_iilez6xa.WorkspaceResourcePage>) {
      return (data as List)
              .map((e) => deserialize<_iilez6xa.WorkspaceResourcePage>(e))
              .toList()
          as T;
    }
    if (t == List<_ivvnnphu.WorkspaceEvent>) {
      return (data as List)
              .map((e) => deserialize<_ivvnnphu.WorkspaceEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_iar0fwau.WorkspaceResource>) {
      return (data as List)
              .map((e) => deserialize<_iar0fwau.WorkspaceResource>(e))
              .toList()
          as T;
    }
    if (t == List<_i54dvwkh.ConversationSummary>) {
      return (data as List)
              .map((e) => deserialize<_i54dvwkh.ConversationSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_isubclmd.ConversationMessageView>) {
      return (data as List)
              .map((e) => deserialize<_isubclmd.ConversationMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_ipos6eci.ApiModelProvider>) {
      return (data as List)
              .map((e) => deserialize<_ipos6eci.ApiModelProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_iuloe217.ApiModel>) {
      return (data as List)
              .map((e) => deserialize<_iuloe217.ApiModel>(e))
              .toList()
          as T;
    }
    if (t == List<_i5hnstsl.ModelConnectionView>) {
      return (data as List)
              .map((e) => deserialize<_i5hnstsl.ModelConnectionView>(e))
              .toList()
          as T;
    }
    if (t == List<_i9qkc4pk.WorkspaceModelSelectionView>) {
      return (data as List)
              .map((e) => deserialize<_i9qkc4pk.WorkspaceModelSelectionView>(e))
              .toList()
          as T;
    }
    if (t == List<_ib73r5sl.CloudWorkspaceSummary>) {
      return (data as List)
              .map((e) => deserialize<_ib73r5sl.CloudWorkspaceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_ieuc8ihm.PendingWorkspaceInviteSummary>) {
      return (data as List)
              .map(
                (e) => deserialize<_ieuc8ihm.PendingWorkspaceInviteSummary>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_i8ggzj4z.CloudWorkspaceMemberSummary>) {
      return (data as List)
              .map((e) => deserialize<_i8ggzj4z.CloudWorkspaceMemberSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_iin9r2cd.CloudWorkspaceInviteSummary>) {
      return (data as List)
              .map((e) => deserialize<_iin9r2cd.CloudWorkspaceInviteSummary>(e))
              .toList()
          as T;
    }
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i0kh9vnq.AccountSummary => 'AccountSummary',
      _iczr9u8f.AgentCatalogItem => 'AgentCatalogItem',
      _ib4whsrz.AgentCatalogPage => 'AgentCatalogPage',
      _i0h0m7az.AgentCatalogStatus => 'AgentCatalogStatus',
      _icsw3jh1.AgentCatalogType => 'AgentCatalogType',
      _izubbx9m.AgentCatalogVisibility => 'AgentCatalogVisibility',
      _i84solqu.GetAgentResourcesRequest => 'GetAgentResourcesRequest',
      _ilueer9m.ListAgentsRequest => 'ListAgentsRequest',
      _ify5ufwn.CodexOAuthTransaction => 'CodexOAuthTransaction',
      _i2qdkbo8.CompleteCodexOAuthRequest => 'CompleteCodexOAuthRequest',
      _ibhl6ekj.CompleteCodexOAuthResult => 'CompleteCodexOAuthResult',
      _iv7ukgnj.StartCodexOAuthRequest => 'StartCodexOAuthRequest',
      _itptq7z5.StartCodexOAuthResult => 'StartCodexOAuthResult',
      _iarqshx6.CancelTurnRequest => 'CancelTurnRequest',
      _isyd7s84.CompactConversationRequest => 'CompactConversationRequest',
      _ialxa16r.ContinueConversationRequest => 'ContinueConversationRequest',
      _iwrs6sde.ContinueTurnRequest => 'ContinueTurnRequest',
      _iivijtsr.Conversation => 'Conversation',
      _iz6esn7o.ConversationErrorCode => 'ConversationErrorCode',
      _i77s958n.ConversationEvent => 'ConversationEvent',
      _i5gn99j4.ConversationEventType => 'ConversationEventType',
      _i4box1gt.ConversationException => 'ConversationException',
      _iznwbo5b.ConversationExecution => 'ConversationExecution',
      _ij9w9f8d.ConversationExecutionView => 'ConversationExecutionView',
      _iq1eovrr.ConversationJob => 'ConversationJob',
      _ibea51bx.ConversationMessage => 'ConversationMessage',
      _iutotoh6.ConversationMessageView => 'ConversationMessageView',
      _iz02ruas.ConversationMutationResult => 'ConversationMutationResult',
      _icl1rfiv.ConversationPage => 'ConversationPage',
      _icx9bns3.ConversationProjectionView => 'ConversationProjectionView',
      _i4omaws8.ConversationSnapshot => 'ConversationSnapshot',
      _irrmkjcu.ConversationStreamEvent => 'ConversationStreamEvent',
      _i6hxcode.ConversationSubscribeRequest => 'ConversationSubscribeRequest',
      _i7a0mfc5.ConversationSummary => 'ConversationSummary',
      _iflac717.ConversationToolCall => 'ConversationToolCall',
      _ic5ojtne.ConversationToolCallView => 'ConversationToolCallView',
      _i7mmki1w.ConversationTurn => 'ConversationTurn',
      _ir5w321b.ConversationTurnView => 'ConversationTurnView',
      _iii6xlqw.ConversationUsage => 'ConversationUsage',
      _i4shnjby.CreateConversationRequest => 'CreateConversationRequest',
      _iqsppx3t.DeleteConversationRequest => 'DeleteConversationRequest',
      _iybdpw96.EditPendingConversationMessageRequest =>
        'EditPendingConversationMessageRequest',
      _ixb0z1tn.GetConversationRequest => 'GetConversationRequest',
      _ilyvwvdb.GetTurnRequest => 'GetTurnRequest',
      _it91nt4l.ListConversationMessagesRequest =>
        'ListConversationMessagesRequest',
      _itcpel99.ListConversationsRequest => 'ListConversationsRequest',
      _i32k4voa.ProviderAdmission => 'ProviderAdmission',
      _ih2np1vh.ProviderAdmissionLock => 'ProviderAdmissionLock',
      _i7moywui.ProviderAdmissionReservation => 'ProviderAdmissionReservation',
      _ido51m94.QueueConversationMessageRequest =>
        'QueueConversationMessageRequest',
      _iy526sio.RemovePendingConversationMessageRequest =>
        'RemovePendingConversationMessageRequest',
      _infbxzxr.ReorderPendingConversationMessageRequest =>
        'ReorderPendingConversationMessageRequest',
      _iocu6u94.StartTurnRequest => 'StartTurnRequest',
      _iw8le0j7.StartTurnResult => 'StartTurnResult',
      _i4cgq7zt.StopConversationRequest => 'StopConversationRequest',
      _inla43mu.SubmitToolDecisionRequest => 'SubmitToolDecisionRequest',
      _ih4jnnah.TurnSnapshot => 'TurnSnapshot',
      _ihs4d7mz.UpdateConversationRequest => 'UpdateConversationRequest',
      _i8unm495.UpdateConversationSettingsRequest =>
        'UpdateConversationSettingsRequest',
      _i6hg2xtf.CreateMcpServerRequest => 'CreateMcpServerRequest',
      _ihyupc89.CreateMcpServerResult => 'CreateMcpServerResult',
      _iabui7vl.DeleteMcpServerRequest => 'DeleteMcpServerRequest',
      _ilmfigs5.DiscoverMcpServerRequest => 'DiscoverMcpServerRequest',
      _i5i328k3.DiscoverMcpServerResult => 'DiscoverMcpServerResult',
      _igzjg3pi.DiscoveredMcpTool => 'DiscoveredMcpTool',
      _iw1ftww6.McpServerHealth => 'McpServerHealth',
      _i8ct1fsr.ApiModel => 'ApiModel',
      _ioo5yu9z.ApiModelProvider => 'ApiModelProvider',
      _i4akrsd1.CreateModelConnectionRequest => 'CreateModelConnectionRequest',
      _im8o8464.DeleteModelConnectionRequest => 'DeleteModelConnectionRequest',
      _iuwdkoab.ListModelConnectionsRequest => 'ListModelConnectionsRequest',
      _i926jgxf.ListWorkspaceModelSelectionsRequest =>
        'ListWorkspaceModelSelectionsRequest',
      _ikk9qcnz.ModelConnectionView => 'ModelConnectionView',
      _il1l34li.ModelSyncResult => 'ModelSyncResult',
      _ixyi2mo6.TestAndSyncModelConnectionRequest =>
        'TestAndSyncModelConnectionRequest',
      _iw5yf4pd.UpdateModelConnectionRequest => 'UpdateModelConnectionRequest',
      _ihf3aqrg.WorkspaceModelConnection => 'WorkspaceModelConnection',
      _i2zocl9o.WorkspaceModelSelectionView => 'WorkspaceModelSelectionView',
      _ii7xucwd.BeginUploadRequest => 'BeginUploadRequest',
      _iy4az4cb.BeginUploadResult => 'BeginUploadResult',
      _ip871ox8.CompleteUploadRequest => 'CompleteUploadRequest',
      _iae520xs.DeleteObjectRequest => 'DeleteObjectRequest',
      _i99cztt4.GetDownloadRequest => 'GetDownloadRequest',
      _ip02joz1.GetDownloadResult => 'GetDownloadResult',
      _ii2nljpm.ObjectDeletion => 'ObjectDeletion',
      _ivy9wxc7.ObjectErrorCode => 'ObjectErrorCode',
      _i4o8es85.ObjectException => 'ObjectException',
      _ino5s3hv.ObjectReference => 'ObjectReference',
      _is4lmm7s.ObjectResult => 'ObjectResult',
      _i6zmsyes.ObjectUpload => 'ObjectUpload',
      _i52p5grh.WorkspaceObject => 'WorkspaceObject',
      _i0ekjn7l.WorkspaceStreamEnvelope => 'WorkspaceStreamEnvelope',
      _i4zgsr0a.WorkspaceStreamEnvelopeKind => 'WorkspaceStreamEnvelopeKind',
      _ig40wm3p.WorkspaceSubscribeRequest => 'WorkspaceSubscribeRequest',
      _ivj0myfi.RecurringWorkerSchedule => 'RecurringWorkerSchedule',
      _ifhsy8zv.WorkerCoordinatorLease => 'WorkerCoordinatorLease',
      _io0q4g8e.MutateWorkspaceCredentialRequest =>
        'MutateWorkspaceCredentialRequest',
      _ipy8xct6.MutateWorkspaceCredentialResponse =>
        'MutateWorkspaceCredentialResponse',
      _ipvegfbn.PatchWorkspaceStateRequest => 'PatchWorkspaceStateRequest',
      _ig93yftz.PatchWorkspaceStateResponse => 'PatchWorkspaceStateResponse',
      _ipxnqptw.PutWorkspaceSecretRequest => 'PutWorkspaceSecretRequest',
      _iavc361v.PutWorkspaceSecretResponse => 'PutWorkspaceSecretResponse',
      _iz7boq8w.ReadWorkspaceStateRequest => 'ReadWorkspaceStateRequest',
      _iqk6zto1.ReadWorkspaceStateResponse => 'ReadWorkspaceStateResponse',
      _iolo6w4a.WorkspacePatchOperation => 'WorkspacePatchOperation',
      _ihbarnlu.WorkspacePatchOperationKind => 'WorkspacePatchOperationKind',
      _iqzfyfs9.WorkspaceResource => 'WorkspaceResource',
      _i8d1xr9g.WorkspaceResourceKind => 'WorkspaceResourceKind',
      _iilez6xa.WorkspaceResourcePage => 'WorkspaceResourcePage',
      _i0vhsjed.WorkspaceResourcePageRequest => 'WorkspaceResourcePageRequest',
      _iyjw9v2c.WorkspaceSecret => 'WorkspaceSecret',
      _iq96p1l9.WorkspaceSecretKind => 'WorkspaceSecretKind',
      _ioqbiy3d.WorkspaceSecretScope => 'WorkspaceSecretScope',
      _ib7b2bmq.AcceptWorkspaceInviteRequest => 'AcceptWorkspaceInviteRequest',
      _iyfjt29r.CloudWorkspace => 'CloudWorkspace',
      _i1uzipdf.CloudWorkspaceCapabilities => 'CloudWorkspaceCapabilities',
      _ixqnubu3.CloudWorkspaceDetail => 'CloudWorkspaceDetail',
      _ikaytupt.CloudWorkspaceErrorCode => 'CloudWorkspaceErrorCode',
      _iq0v59d3.CloudWorkspaceException => 'CloudWorkspaceException',
      _i4buxtw8.CloudWorkspaceInviteSummary => 'CloudWorkspaceInviteSummary',
      _i3c64tpx.CloudWorkspaceMemberSummary => 'CloudWorkspaceMemberSummary',
      _iqlfhfv2.CloudWorkspaceSummary => 'CloudWorkspaceSummary',
      _i2wx1hcz.CreateCloudWorkspaceRequest => 'CreateCloudWorkspaceRequest',
      _izpvgmoh.DeclineWorkspaceInviteRequest =>
        'DeclineWorkspaceInviteRequest',
      _irqsg6pc.DeleteCloudWorkspaceRequest => 'DeleteCloudWorkspaceRequest',
      _i3slgemv.GetCloudWorkspaceDetailRequest =>
        'GetCloudWorkspaceDetailRequest',
      _iojw3n39.InviteWorkspaceMemberRequest => 'InviteWorkspaceMemberRequest',
      _i90hckxm.LeaveCloudWorkspaceRequest => 'LeaveCloudWorkspaceRequest',
      _ig64imxt.ListCloudWorkspaceInvitesRequest =>
        'ListCloudWorkspaceInvitesRequest',
      _iop4tnuf.ListWorkspaceMembersRequest => 'ListWorkspaceMembersRequest',
      _imuwa8ax.PendingWorkspaceInviteSummary =>
        'PendingWorkspaceInviteSummary',
      _ioya5p5j.RemoveWorkspaceMemberRequest => 'RemoveWorkspaceMemberRequest',
      _ifsfc78n.RenameCloudWorkspaceRequest => 'RenameCloudWorkspaceRequest',
      _ivko4e0f.RenewWorkspaceInviteRequest => 'RenewWorkspaceInviteRequest',
      _iwlbozzh.RevokeWorkspaceInviteRequest => 'RevokeWorkspaceInviteRequest',
      _i7ana9ux.TransferCloudWorkspaceOwnershipRequest =>
        'TransferCloudWorkspaceOwnershipRequest',
      _i2qmz98c.UpdateWorkspaceMemberRoleRequest =>
        'UpdateWorkspaceMemberRoleRequest',
      _ifp2sq2r.WorkspaceAuditRecord => 'WorkspaceAuditRecord',
      _ivvnnphu.WorkspaceEvent => 'WorkspaceEvent',
      _ilpykuxc.WorkspaceInvite => 'WorkspaceInvite',
      _i56tb1yu.WorkspaceMember => 'WorkspaceMember',
      _ia614g7d.WorkspaceMutationReceipt => 'WorkspaceMutationReceipt',
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
      case _i0kh9vnq.AccountSummary():
        return 'AccountSummary';
      case _iczr9u8f.AgentCatalogItem():
        return 'AgentCatalogItem';
      case _ib4whsrz.AgentCatalogPage():
        return 'AgentCatalogPage';
      case _i0h0m7az.AgentCatalogStatus():
        return 'AgentCatalogStatus';
      case _icsw3jh1.AgentCatalogType():
        return 'AgentCatalogType';
      case _izubbx9m.AgentCatalogVisibility():
        return 'AgentCatalogVisibility';
      case _i84solqu.GetAgentResourcesRequest():
        return 'GetAgentResourcesRequest';
      case _ilueer9m.ListAgentsRequest():
        return 'ListAgentsRequest';
      case _ify5ufwn.CodexOAuthTransaction():
        return 'CodexOAuthTransaction';
      case _i2qdkbo8.CompleteCodexOAuthRequest():
        return 'CompleteCodexOAuthRequest';
      case _ibhl6ekj.CompleteCodexOAuthResult():
        return 'CompleteCodexOAuthResult';
      case _iv7ukgnj.StartCodexOAuthRequest():
        return 'StartCodexOAuthRequest';
      case _itptq7z5.StartCodexOAuthResult():
        return 'StartCodexOAuthResult';
      case _iarqshx6.CancelTurnRequest():
        return 'CancelTurnRequest';
      case _isyd7s84.CompactConversationRequest():
        return 'CompactConversationRequest';
      case _ialxa16r.ContinueConversationRequest():
        return 'ContinueConversationRequest';
      case _iwrs6sde.ContinueTurnRequest():
        return 'ContinueTurnRequest';
      case _iivijtsr.Conversation():
        return 'Conversation';
      case _iz6esn7o.ConversationErrorCode():
        return 'ConversationErrorCode';
      case _i77s958n.ConversationEvent():
        return 'ConversationEvent';
      case _i5gn99j4.ConversationEventType():
        return 'ConversationEventType';
      case _i4box1gt.ConversationException():
        return 'ConversationException';
      case _iznwbo5b.ConversationExecution():
        return 'ConversationExecution';
      case _ij9w9f8d.ConversationExecutionView():
        return 'ConversationExecutionView';
      case _iq1eovrr.ConversationJob():
        return 'ConversationJob';
      case _ibea51bx.ConversationMessage():
        return 'ConversationMessage';
      case _iutotoh6.ConversationMessageView():
        return 'ConversationMessageView';
      case _iz02ruas.ConversationMutationResult():
        return 'ConversationMutationResult';
      case _icl1rfiv.ConversationPage():
        return 'ConversationPage';
      case _icx9bns3.ConversationProjectionView():
        return 'ConversationProjectionView';
      case _i4omaws8.ConversationSnapshot():
        return 'ConversationSnapshot';
      case _irrmkjcu.ConversationStreamEvent():
        return 'ConversationStreamEvent';
      case _i6hxcode.ConversationSubscribeRequest():
        return 'ConversationSubscribeRequest';
      case _i7a0mfc5.ConversationSummary():
        return 'ConversationSummary';
      case _iflac717.ConversationToolCall():
        return 'ConversationToolCall';
      case _ic5ojtne.ConversationToolCallView():
        return 'ConversationToolCallView';
      case _i7mmki1w.ConversationTurn():
        return 'ConversationTurn';
      case _ir5w321b.ConversationTurnView():
        return 'ConversationTurnView';
      case _iii6xlqw.ConversationUsage():
        return 'ConversationUsage';
      case _i4shnjby.CreateConversationRequest():
        return 'CreateConversationRequest';
      case _iqsppx3t.DeleteConversationRequest():
        return 'DeleteConversationRequest';
      case _iybdpw96.EditPendingConversationMessageRequest():
        return 'EditPendingConversationMessageRequest';
      case _ixb0z1tn.GetConversationRequest():
        return 'GetConversationRequest';
      case _ilyvwvdb.GetTurnRequest():
        return 'GetTurnRequest';
      case _it91nt4l.ListConversationMessagesRequest():
        return 'ListConversationMessagesRequest';
      case _itcpel99.ListConversationsRequest():
        return 'ListConversationsRequest';
      case _i32k4voa.ProviderAdmission():
        return 'ProviderAdmission';
      case _ih2np1vh.ProviderAdmissionLock():
        return 'ProviderAdmissionLock';
      case _i7moywui.ProviderAdmissionReservation():
        return 'ProviderAdmissionReservation';
      case _ido51m94.QueueConversationMessageRequest():
        return 'QueueConversationMessageRequest';
      case _iy526sio.RemovePendingConversationMessageRequest():
        return 'RemovePendingConversationMessageRequest';
      case _infbxzxr.ReorderPendingConversationMessageRequest():
        return 'ReorderPendingConversationMessageRequest';
      case _iocu6u94.StartTurnRequest():
        return 'StartTurnRequest';
      case _iw8le0j7.StartTurnResult():
        return 'StartTurnResult';
      case _i4cgq7zt.StopConversationRequest():
        return 'StopConversationRequest';
      case _inla43mu.SubmitToolDecisionRequest():
        return 'SubmitToolDecisionRequest';
      case _ih4jnnah.TurnSnapshot():
        return 'TurnSnapshot';
      case _ihs4d7mz.UpdateConversationRequest():
        return 'UpdateConversationRequest';
      case _i8unm495.UpdateConversationSettingsRequest():
        return 'UpdateConversationSettingsRequest';
      case _i6hg2xtf.CreateMcpServerRequest():
        return 'CreateMcpServerRequest';
      case _ihyupc89.CreateMcpServerResult():
        return 'CreateMcpServerResult';
      case _iabui7vl.DeleteMcpServerRequest():
        return 'DeleteMcpServerRequest';
      case _ilmfigs5.DiscoverMcpServerRequest():
        return 'DiscoverMcpServerRequest';
      case _i5i328k3.DiscoverMcpServerResult():
        return 'DiscoverMcpServerResult';
      case _igzjg3pi.DiscoveredMcpTool():
        return 'DiscoveredMcpTool';
      case _iw1ftww6.McpServerHealth():
        return 'McpServerHealth';
      case _i8ct1fsr.ApiModel():
        return 'ApiModel';
      case _ioo5yu9z.ApiModelProvider():
        return 'ApiModelProvider';
      case _i4akrsd1.CreateModelConnectionRequest():
        return 'CreateModelConnectionRequest';
      case _im8o8464.DeleteModelConnectionRequest():
        return 'DeleteModelConnectionRequest';
      case _iuwdkoab.ListModelConnectionsRequest():
        return 'ListModelConnectionsRequest';
      case _i926jgxf.ListWorkspaceModelSelectionsRequest():
        return 'ListWorkspaceModelSelectionsRequest';
      case _ikk9qcnz.ModelConnectionView():
        return 'ModelConnectionView';
      case _il1l34li.ModelSyncResult():
        return 'ModelSyncResult';
      case _ixyi2mo6.TestAndSyncModelConnectionRequest():
        return 'TestAndSyncModelConnectionRequest';
      case _iw5yf4pd.UpdateModelConnectionRequest():
        return 'UpdateModelConnectionRequest';
      case _ihf3aqrg.WorkspaceModelConnection():
        return 'WorkspaceModelConnection';
      case _i2zocl9o.WorkspaceModelSelectionView():
        return 'WorkspaceModelSelectionView';
      case _ii7xucwd.BeginUploadRequest():
        return 'BeginUploadRequest';
      case _iy4az4cb.BeginUploadResult():
        return 'BeginUploadResult';
      case _ip871ox8.CompleteUploadRequest():
        return 'CompleteUploadRequest';
      case _iae520xs.DeleteObjectRequest():
        return 'DeleteObjectRequest';
      case _i99cztt4.GetDownloadRequest():
        return 'GetDownloadRequest';
      case _ip02joz1.GetDownloadResult():
        return 'GetDownloadResult';
      case _ii2nljpm.ObjectDeletion():
        return 'ObjectDeletion';
      case _ivy9wxc7.ObjectErrorCode():
        return 'ObjectErrorCode';
      case _i4o8es85.ObjectException():
        return 'ObjectException';
      case _ino5s3hv.ObjectReference():
        return 'ObjectReference';
      case _is4lmm7s.ObjectResult():
        return 'ObjectResult';
      case _i6zmsyes.ObjectUpload():
        return 'ObjectUpload';
      case _i52p5grh.WorkspaceObject():
        return 'WorkspaceObject';
      case _i0ekjn7l.WorkspaceStreamEnvelope():
        return 'WorkspaceStreamEnvelope';
      case _i4zgsr0a.WorkspaceStreamEnvelopeKind():
        return 'WorkspaceStreamEnvelopeKind';
      case _ig40wm3p.WorkspaceSubscribeRequest():
        return 'WorkspaceSubscribeRequest';
      case _ivj0myfi.RecurringWorkerSchedule():
        return 'RecurringWorkerSchedule';
      case _ifhsy8zv.WorkerCoordinatorLease():
        return 'WorkerCoordinatorLease';
      case _io0q4g8e.MutateWorkspaceCredentialRequest():
        return 'MutateWorkspaceCredentialRequest';
      case _ipy8xct6.MutateWorkspaceCredentialResponse():
        return 'MutateWorkspaceCredentialResponse';
      case _ipvegfbn.PatchWorkspaceStateRequest():
        return 'PatchWorkspaceStateRequest';
      case _ig93yftz.PatchWorkspaceStateResponse():
        return 'PatchWorkspaceStateResponse';
      case _ipxnqptw.PutWorkspaceSecretRequest():
        return 'PutWorkspaceSecretRequest';
      case _iavc361v.PutWorkspaceSecretResponse():
        return 'PutWorkspaceSecretResponse';
      case _iz7boq8w.ReadWorkspaceStateRequest():
        return 'ReadWorkspaceStateRequest';
      case _iqk6zto1.ReadWorkspaceStateResponse():
        return 'ReadWorkspaceStateResponse';
      case _iolo6w4a.WorkspacePatchOperation():
        return 'WorkspacePatchOperation';
      case _ihbarnlu.WorkspacePatchOperationKind():
        return 'WorkspacePatchOperationKind';
      case _iqzfyfs9.WorkspaceResource():
        return 'WorkspaceResource';
      case _i8d1xr9g.WorkspaceResourceKind():
        return 'WorkspaceResourceKind';
      case _iilez6xa.WorkspaceResourcePage():
        return 'WorkspaceResourcePage';
      case _i0vhsjed.WorkspaceResourcePageRequest():
        return 'WorkspaceResourcePageRequest';
      case _iyjw9v2c.WorkspaceSecret():
        return 'WorkspaceSecret';
      case _iq96p1l9.WorkspaceSecretKind():
        return 'WorkspaceSecretKind';
      case _ioqbiy3d.WorkspaceSecretScope():
        return 'WorkspaceSecretScope';
      case _ib7b2bmq.AcceptWorkspaceInviteRequest():
        return 'AcceptWorkspaceInviteRequest';
      case _iyfjt29r.CloudWorkspace():
        return 'CloudWorkspace';
      case _i1uzipdf.CloudWorkspaceCapabilities():
        return 'CloudWorkspaceCapabilities';
      case _ixqnubu3.CloudWorkspaceDetail():
        return 'CloudWorkspaceDetail';
      case _ikaytupt.CloudWorkspaceErrorCode():
        return 'CloudWorkspaceErrorCode';
      case _iq0v59d3.CloudWorkspaceException():
        return 'CloudWorkspaceException';
      case _i4buxtw8.CloudWorkspaceInviteSummary():
        return 'CloudWorkspaceInviteSummary';
      case _i3c64tpx.CloudWorkspaceMemberSummary():
        return 'CloudWorkspaceMemberSummary';
      case _iqlfhfv2.CloudWorkspaceSummary():
        return 'CloudWorkspaceSummary';
      case _i2wx1hcz.CreateCloudWorkspaceRequest():
        return 'CreateCloudWorkspaceRequest';
      case _izpvgmoh.DeclineWorkspaceInviteRequest():
        return 'DeclineWorkspaceInviteRequest';
      case _irqsg6pc.DeleteCloudWorkspaceRequest():
        return 'DeleteCloudWorkspaceRequest';
      case _i3slgemv.GetCloudWorkspaceDetailRequest():
        return 'GetCloudWorkspaceDetailRequest';
      case _iojw3n39.InviteWorkspaceMemberRequest():
        return 'InviteWorkspaceMemberRequest';
      case _i90hckxm.LeaveCloudWorkspaceRequest():
        return 'LeaveCloudWorkspaceRequest';
      case _ig64imxt.ListCloudWorkspaceInvitesRequest():
        return 'ListCloudWorkspaceInvitesRequest';
      case _iop4tnuf.ListWorkspaceMembersRequest():
        return 'ListWorkspaceMembersRequest';
      case _imuwa8ax.PendingWorkspaceInviteSummary():
        return 'PendingWorkspaceInviteSummary';
      case _ioya5p5j.RemoveWorkspaceMemberRequest():
        return 'RemoveWorkspaceMemberRequest';
      case _ifsfc78n.RenameCloudWorkspaceRequest():
        return 'RenameCloudWorkspaceRequest';
      case _ivko4e0f.RenewWorkspaceInviteRequest():
        return 'RenewWorkspaceInviteRequest';
      case _iwlbozzh.RevokeWorkspaceInviteRequest():
        return 'RevokeWorkspaceInviteRequest';
      case _i7ana9ux.TransferCloudWorkspaceOwnershipRequest():
        return 'TransferCloudWorkspaceOwnershipRequest';
      case _i2qmz98c.UpdateWorkspaceMemberRoleRequest():
        return 'UpdateWorkspaceMemberRoleRequest';
      case _ifp2sq2r.WorkspaceAuditRecord():
        return 'WorkspaceAuditRecord';
      case _ivvnnphu.WorkspaceEvent():
        return 'WorkspaceEvent';
      case _ilpykuxc.WorkspaceInvite():
        return 'WorkspaceInvite';
      case _i56tb1yu.WorkspaceMember():
        return 'WorkspaceMember';
      case _ia614g7d.WorkspaceMutationReceipt():
        return 'WorkspaceMutationReceipt';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
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
      return deserialize<_i0kh9vnq.AccountSummary>(data['data']);
    }
    if (dataClassName == 'AgentCatalogItem') {
      return deserialize<_iczr9u8f.AgentCatalogItem>(data['data']);
    }
    if (dataClassName == 'AgentCatalogPage') {
      return deserialize<_ib4whsrz.AgentCatalogPage>(data['data']);
    }
    if (dataClassName == 'AgentCatalogStatus') {
      return deserialize<_i0h0m7az.AgentCatalogStatus>(data['data']);
    }
    if (dataClassName == 'AgentCatalogType') {
      return deserialize<_icsw3jh1.AgentCatalogType>(data['data']);
    }
    if (dataClassName == 'AgentCatalogVisibility') {
      return deserialize<_izubbx9m.AgentCatalogVisibility>(data['data']);
    }
    if (dataClassName == 'GetAgentResourcesRequest') {
      return deserialize<_i84solqu.GetAgentResourcesRequest>(data['data']);
    }
    if (dataClassName == 'ListAgentsRequest') {
      return deserialize<_ilueer9m.ListAgentsRequest>(data['data']);
    }
    if (dataClassName == 'CodexOAuthTransaction') {
      return deserialize<_ify5ufwn.CodexOAuthTransaction>(data['data']);
    }
    if (dataClassName == 'CompleteCodexOAuthRequest') {
      return deserialize<_i2qdkbo8.CompleteCodexOAuthRequest>(data['data']);
    }
    if (dataClassName == 'CompleteCodexOAuthResult') {
      return deserialize<_ibhl6ekj.CompleteCodexOAuthResult>(data['data']);
    }
    if (dataClassName == 'StartCodexOAuthRequest') {
      return deserialize<_iv7ukgnj.StartCodexOAuthRequest>(data['data']);
    }
    if (dataClassName == 'StartCodexOAuthResult') {
      return deserialize<_itptq7z5.StartCodexOAuthResult>(data['data']);
    }
    if (dataClassName == 'CancelTurnRequest') {
      return deserialize<_iarqshx6.CancelTurnRequest>(data['data']);
    }
    if (dataClassName == 'CompactConversationRequest') {
      return deserialize<_isyd7s84.CompactConversationRequest>(data['data']);
    }
    if (dataClassName == 'ContinueConversationRequest') {
      return deserialize<_ialxa16r.ContinueConversationRequest>(data['data']);
    }
    if (dataClassName == 'ContinueTurnRequest') {
      return deserialize<_iwrs6sde.ContinueTurnRequest>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_iivijtsr.Conversation>(data['data']);
    }
    if (dataClassName == 'ConversationErrorCode') {
      return deserialize<_iz6esn7o.ConversationErrorCode>(data['data']);
    }
    if (dataClassName == 'ConversationEvent') {
      return deserialize<_i77s958n.ConversationEvent>(data['data']);
    }
    if (dataClassName == 'ConversationEventType') {
      return deserialize<_i5gn99j4.ConversationEventType>(data['data']);
    }
    if (dataClassName == 'ConversationException') {
      return deserialize<_i4box1gt.ConversationException>(data['data']);
    }
    if (dataClassName == 'ConversationExecution') {
      return deserialize<_iznwbo5b.ConversationExecution>(data['data']);
    }
    if (dataClassName == 'ConversationExecutionView') {
      return deserialize<_ij9w9f8d.ConversationExecutionView>(data['data']);
    }
    if (dataClassName == 'ConversationJob') {
      return deserialize<_iq1eovrr.ConversationJob>(data['data']);
    }
    if (dataClassName == 'ConversationMessage') {
      return deserialize<_ibea51bx.ConversationMessage>(data['data']);
    }
    if (dataClassName == 'ConversationMessageView') {
      return deserialize<_iutotoh6.ConversationMessageView>(data['data']);
    }
    if (dataClassName == 'ConversationMutationResult') {
      return deserialize<_iz02ruas.ConversationMutationResult>(data['data']);
    }
    if (dataClassName == 'ConversationPage') {
      return deserialize<_icl1rfiv.ConversationPage>(data['data']);
    }
    if (dataClassName == 'ConversationProjectionView') {
      return deserialize<_icx9bns3.ConversationProjectionView>(data['data']);
    }
    if (dataClassName == 'ConversationSnapshot') {
      return deserialize<_i4omaws8.ConversationSnapshot>(data['data']);
    }
    if (dataClassName == 'ConversationStreamEvent') {
      return deserialize<_irrmkjcu.ConversationStreamEvent>(data['data']);
    }
    if (dataClassName == 'ConversationSubscribeRequest') {
      return deserialize<_i6hxcode.ConversationSubscribeRequest>(data['data']);
    }
    if (dataClassName == 'ConversationSummary') {
      return deserialize<_i7a0mfc5.ConversationSummary>(data['data']);
    }
    if (dataClassName == 'ConversationToolCall') {
      return deserialize<_iflac717.ConversationToolCall>(data['data']);
    }
    if (dataClassName == 'ConversationToolCallView') {
      return deserialize<_ic5ojtne.ConversationToolCallView>(data['data']);
    }
    if (dataClassName == 'ConversationTurn') {
      return deserialize<_i7mmki1w.ConversationTurn>(data['data']);
    }
    if (dataClassName == 'ConversationTurnView') {
      return deserialize<_ir5w321b.ConversationTurnView>(data['data']);
    }
    if (dataClassName == 'ConversationUsage') {
      return deserialize<_iii6xlqw.ConversationUsage>(data['data']);
    }
    if (dataClassName == 'CreateConversationRequest') {
      return deserialize<_i4shnjby.CreateConversationRequest>(data['data']);
    }
    if (dataClassName == 'DeleteConversationRequest') {
      return deserialize<_iqsppx3t.DeleteConversationRequest>(data['data']);
    }
    if (dataClassName == 'EditPendingConversationMessageRequest') {
      return deserialize<_iybdpw96.EditPendingConversationMessageRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'GetConversationRequest') {
      return deserialize<_ixb0z1tn.GetConversationRequest>(data['data']);
    }
    if (dataClassName == 'GetTurnRequest') {
      return deserialize<_ilyvwvdb.GetTurnRequest>(data['data']);
    }
    if (dataClassName == 'ListConversationMessagesRequest') {
      return deserialize<_it91nt4l.ListConversationMessagesRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'ListConversationsRequest') {
      return deserialize<_itcpel99.ListConversationsRequest>(data['data']);
    }
    if (dataClassName == 'ProviderAdmission') {
      return deserialize<_i32k4voa.ProviderAdmission>(data['data']);
    }
    if (dataClassName == 'ProviderAdmissionLock') {
      return deserialize<_ih2np1vh.ProviderAdmissionLock>(data['data']);
    }
    if (dataClassName == 'ProviderAdmissionReservation') {
      return deserialize<_i7moywui.ProviderAdmissionReservation>(data['data']);
    }
    if (dataClassName == 'QueueConversationMessageRequest') {
      return deserialize<_ido51m94.QueueConversationMessageRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'RemovePendingConversationMessageRequest') {
      return deserialize<_iy526sio.RemovePendingConversationMessageRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'ReorderPendingConversationMessageRequest') {
      return deserialize<_infbxzxr.ReorderPendingConversationMessageRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'StartTurnRequest') {
      return deserialize<_iocu6u94.StartTurnRequest>(data['data']);
    }
    if (dataClassName == 'StartTurnResult') {
      return deserialize<_iw8le0j7.StartTurnResult>(data['data']);
    }
    if (dataClassName == 'StopConversationRequest') {
      return deserialize<_i4cgq7zt.StopConversationRequest>(data['data']);
    }
    if (dataClassName == 'SubmitToolDecisionRequest') {
      return deserialize<_inla43mu.SubmitToolDecisionRequest>(data['data']);
    }
    if (dataClassName == 'TurnSnapshot') {
      return deserialize<_ih4jnnah.TurnSnapshot>(data['data']);
    }
    if (dataClassName == 'UpdateConversationRequest') {
      return deserialize<_ihs4d7mz.UpdateConversationRequest>(data['data']);
    }
    if (dataClassName == 'UpdateConversationSettingsRequest') {
      return deserialize<_i8unm495.UpdateConversationSettingsRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'CreateMcpServerRequest') {
      return deserialize<_i6hg2xtf.CreateMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'CreateMcpServerResult') {
      return deserialize<_ihyupc89.CreateMcpServerResult>(data['data']);
    }
    if (dataClassName == 'DeleteMcpServerRequest') {
      return deserialize<_iabui7vl.DeleteMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'DiscoverMcpServerRequest') {
      return deserialize<_ilmfigs5.DiscoverMcpServerRequest>(data['data']);
    }
    if (dataClassName == 'DiscoverMcpServerResult') {
      return deserialize<_i5i328k3.DiscoverMcpServerResult>(data['data']);
    }
    if (dataClassName == 'DiscoveredMcpTool') {
      return deserialize<_igzjg3pi.DiscoveredMcpTool>(data['data']);
    }
    if (dataClassName == 'McpServerHealth') {
      return deserialize<_iw1ftww6.McpServerHealth>(data['data']);
    }
    if (dataClassName == 'ApiModel') {
      return deserialize<_i8ct1fsr.ApiModel>(data['data']);
    }
    if (dataClassName == 'ApiModelProvider') {
      return deserialize<_ioo5yu9z.ApiModelProvider>(data['data']);
    }
    if (dataClassName == 'CreateModelConnectionRequest') {
      return deserialize<_i4akrsd1.CreateModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'DeleteModelConnectionRequest') {
      return deserialize<_im8o8464.DeleteModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'ListModelConnectionsRequest') {
      return deserialize<_iuwdkoab.ListModelConnectionsRequest>(data['data']);
    }
    if (dataClassName == 'ListWorkspaceModelSelectionsRequest') {
      return deserialize<_i926jgxf.ListWorkspaceModelSelectionsRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'ModelConnectionView') {
      return deserialize<_ikk9qcnz.ModelConnectionView>(data['data']);
    }
    if (dataClassName == 'ModelSyncResult') {
      return deserialize<_il1l34li.ModelSyncResult>(data['data']);
    }
    if (dataClassName == 'TestAndSyncModelConnectionRequest') {
      return deserialize<_ixyi2mo6.TestAndSyncModelConnectionRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'UpdateModelConnectionRequest') {
      return deserialize<_iw5yf4pd.UpdateModelConnectionRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceModelConnection') {
      return deserialize<_ihf3aqrg.WorkspaceModelConnection>(data['data']);
    }
    if (dataClassName == 'WorkspaceModelSelectionView') {
      return deserialize<_i2zocl9o.WorkspaceModelSelectionView>(data['data']);
    }
    if (dataClassName == 'BeginUploadRequest') {
      return deserialize<_ii7xucwd.BeginUploadRequest>(data['data']);
    }
    if (dataClassName == 'BeginUploadResult') {
      return deserialize<_iy4az4cb.BeginUploadResult>(data['data']);
    }
    if (dataClassName == 'CompleteUploadRequest') {
      return deserialize<_ip871ox8.CompleteUploadRequest>(data['data']);
    }
    if (dataClassName == 'DeleteObjectRequest') {
      return deserialize<_iae520xs.DeleteObjectRequest>(data['data']);
    }
    if (dataClassName == 'GetDownloadRequest') {
      return deserialize<_i99cztt4.GetDownloadRequest>(data['data']);
    }
    if (dataClassName == 'GetDownloadResult') {
      return deserialize<_ip02joz1.GetDownloadResult>(data['data']);
    }
    if (dataClassName == 'ObjectDeletion') {
      return deserialize<_ii2nljpm.ObjectDeletion>(data['data']);
    }
    if (dataClassName == 'ObjectErrorCode') {
      return deserialize<_ivy9wxc7.ObjectErrorCode>(data['data']);
    }
    if (dataClassName == 'ObjectException') {
      return deserialize<_i4o8es85.ObjectException>(data['data']);
    }
    if (dataClassName == 'ObjectReference') {
      return deserialize<_ino5s3hv.ObjectReference>(data['data']);
    }
    if (dataClassName == 'ObjectResult') {
      return deserialize<_is4lmm7s.ObjectResult>(data['data']);
    }
    if (dataClassName == 'ObjectUpload') {
      return deserialize<_i6zmsyes.ObjectUpload>(data['data']);
    }
    if (dataClassName == 'WorkspaceObject') {
      return deserialize<_i52p5grh.WorkspaceObject>(data['data']);
    }
    if (dataClassName == 'WorkspaceStreamEnvelope') {
      return deserialize<_i0ekjn7l.WorkspaceStreamEnvelope>(data['data']);
    }
    if (dataClassName == 'WorkspaceStreamEnvelopeKind') {
      return deserialize<_i4zgsr0a.WorkspaceStreamEnvelopeKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceSubscribeRequest') {
      return deserialize<_ig40wm3p.WorkspaceSubscribeRequest>(data['data']);
    }
    if (dataClassName == 'RecurringWorkerSchedule') {
      return deserialize<_ivj0myfi.RecurringWorkerSchedule>(data['data']);
    }
    if (dataClassName == 'WorkerCoordinatorLease') {
      return deserialize<_ifhsy8zv.WorkerCoordinatorLease>(data['data']);
    }
    if (dataClassName == 'MutateWorkspaceCredentialRequest') {
      return deserialize<_io0q4g8e.MutateWorkspaceCredentialRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'MutateWorkspaceCredentialResponse') {
      return deserialize<_ipy8xct6.MutateWorkspaceCredentialResponse>(
        data['data'],
      );
    }
    if (dataClassName == 'PatchWorkspaceStateRequest') {
      return deserialize<_ipvegfbn.PatchWorkspaceStateRequest>(data['data']);
    }
    if (dataClassName == 'PatchWorkspaceStateResponse') {
      return deserialize<_ig93yftz.PatchWorkspaceStateResponse>(data['data']);
    }
    if (dataClassName == 'PutWorkspaceSecretRequest') {
      return deserialize<_ipxnqptw.PutWorkspaceSecretRequest>(data['data']);
    }
    if (dataClassName == 'PutWorkspaceSecretResponse') {
      return deserialize<_iavc361v.PutWorkspaceSecretResponse>(data['data']);
    }
    if (dataClassName == 'ReadWorkspaceStateRequest') {
      return deserialize<_iz7boq8w.ReadWorkspaceStateRequest>(data['data']);
    }
    if (dataClassName == 'ReadWorkspaceStateResponse') {
      return deserialize<_iqk6zto1.ReadWorkspaceStateResponse>(data['data']);
    }
    if (dataClassName == 'WorkspacePatchOperation') {
      return deserialize<_iolo6w4a.WorkspacePatchOperation>(data['data']);
    }
    if (dataClassName == 'WorkspacePatchOperationKind') {
      return deserialize<_ihbarnlu.WorkspacePatchOperationKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceResource') {
      return deserialize<_iqzfyfs9.WorkspaceResource>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourceKind') {
      return deserialize<_i8d1xr9g.WorkspaceResourceKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourcePage') {
      return deserialize<_iilez6xa.WorkspaceResourcePage>(data['data']);
    }
    if (dataClassName == 'WorkspaceResourcePageRequest') {
      return deserialize<_i0vhsjed.WorkspaceResourcePageRequest>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecret') {
      return deserialize<_iyjw9v2c.WorkspaceSecret>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecretKind') {
      return deserialize<_iq96p1l9.WorkspaceSecretKind>(data['data']);
    }
    if (dataClassName == 'WorkspaceSecretScope') {
      return deserialize<_ioqbiy3d.WorkspaceSecretScope>(data['data']);
    }
    if (dataClassName == 'AcceptWorkspaceInviteRequest') {
      return deserialize<_ib7b2bmq.AcceptWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'CloudWorkspace') {
      return deserialize<_iyfjt29r.CloudWorkspace>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceCapabilities') {
      return deserialize<_i1uzipdf.CloudWorkspaceCapabilities>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceDetail') {
      return deserialize<_ixqnubu3.CloudWorkspaceDetail>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceErrorCode') {
      return deserialize<_ikaytupt.CloudWorkspaceErrorCode>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceException') {
      return deserialize<_iq0v59d3.CloudWorkspaceException>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceInviteSummary') {
      return deserialize<_i4buxtw8.CloudWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceMemberSummary') {
      return deserialize<_i3c64tpx.CloudWorkspaceMemberSummary>(data['data']);
    }
    if (dataClassName == 'CloudWorkspaceSummary') {
      return deserialize<_iqlfhfv2.CloudWorkspaceSummary>(data['data']);
    }
    if (dataClassName == 'CreateCloudWorkspaceRequest') {
      return deserialize<_i2wx1hcz.CreateCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'DeclineWorkspaceInviteRequest') {
      return deserialize<_izpvgmoh.DeclineWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'DeleteCloudWorkspaceRequest') {
      return deserialize<_irqsg6pc.DeleteCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'GetCloudWorkspaceDetailRequest') {
      return deserialize<_i3slgemv.GetCloudWorkspaceDetailRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'InviteWorkspaceMemberRequest') {
      return deserialize<_iojw3n39.InviteWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'LeaveCloudWorkspaceRequest') {
      return deserialize<_i90hckxm.LeaveCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'ListCloudWorkspaceInvitesRequest') {
      return deserialize<_ig64imxt.ListCloudWorkspaceInvitesRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'ListWorkspaceMembersRequest') {
      return deserialize<_iop4tnuf.ListWorkspaceMembersRequest>(data['data']);
    }
    if (dataClassName == 'PendingWorkspaceInviteSummary') {
      return deserialize<_imuwa8ax.PendingWorkspaceInviteSummary>(data['data']);
    }
    if (dataClassName == 'RemoveWorkspaceMemberRequest') {
      return deserialize<_ioya5p5j.RemoveWorkspaceMemberRequest>(data['data']);
    }
    if (dataClassName == 'RenameCloudWorkspaceRequest') {
      return deserialize<_ifsfc78n.RenameCloudWorkspaceRequest>(data['data']);
    }
    if (dataClassName == 'RenewWorkspaceInviteRequest') {
      return deserialize<_ivko4e0f.RenewWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'RevokeWorkspaceInviteRequest') {
      return deserialize<_iwlbozzh.RevokeWorkspaceInviteRequest>(data['data']);
    }
    if (dataClassName == 'TransferCloudWorkspaceOwnershipRequest') {
      return deserialize<_i7ana9ux.TransferCloudWorkspaceOwnershipRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'UpdateWorkspaceMemberRoleRequest') {
      return deserialize<_i2qmz98c.UpdateWorkspaceMemberRoleRequest>(
        data['data'],
      );
    }
    if (dataClassName == 'WorkspaceAuditRecord') {
      return deserialize<_ifp2sq2r.WorkspaceAuditRecord>(data['data']);
    }
    if (dataClassName == 'WorkspaceEvent') {
      return deserialize<_ivvnnphu.WorkspaceEvent>(data['data']);
    }
    if (dataClassName == 'WorkspaceInvite') {
      return deserialize<_ilpykuxc.WorkspaceInvite>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i56tb1yu.WorkspaceMember>(data['data']);
    }
    if (dataClassName == 'WorkspaceMutationReceipt') {
      return deserialize<_ia614g7d.WorkspaceMutationReceipt>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iacc.Protocol().registerHostProtocol('auravibes', this);
    _iaic.Protocol().registerHostProtocol('auravibes', this);
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
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
