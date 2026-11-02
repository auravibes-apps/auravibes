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
import 'package:serverpod/serverpod.dart' as _is;

enum WorkspaceResourceKind implements _is.SerializableModel {
  view,
  folder,
  file,
  table,
  tableRecord,
  conversation,
  message,
  attachment,
  agent,
  agentAssociation,
  serviceConnection,
  modelConnection,
  model,
  modelSelection,
  tool,
  toolGroup,
  toolPermission,
  mcpServer,
  skill,
  skillSetting,
  conversationToolSelection,
  conversationSkillSelection,
  compactionSetting,
  workspaceSetting,
  workflow;

  static WorkspaceResourceKind fromJson(String name) {
    switch (name) {
      case 'view':
        return WorkspaceResourceKind.view;
      case 'folder':
        return WorkspaceResourceKind.folder;
      case 'file':
        return WorkspaceResourceKind.file;
      case 'table':
        return WorkspaceResourceKind.table;
      case 'tableRecord':
        return WorkspaceResourceKind.tableRecord;
      case 'conversation':
        return WorkspaceResourceKind.conversation;
      case 'message':
        return WorkspaceResourceKind.message;
      case 'attachment':
        return WorkspaceResourceKind.attachment;
      case 'agent':
        return WorkspaceResourceKind.agent;
      case 'agentAssociation':
        return WorkspaceResourceKind.agentAssociation;
      case 'serviceConnection':
        return WorkspaceResourceKind.serviceConnection;
      case 'modelConnection':
        return WorkspaceResourceKind.modelConnection;
      case 'model':
        return WorkspaceResourceKind.model;
      case 'modelSelection':
        return WorkspaceResourceKind.modelSelection;
      case 'tool':
        return WorkspaceResourceKind.tool;
      case 'toolGroup':
        return WorkspaceResourceKind.toolGroup;
      case 'toolPermission':
        return WorkspaceResourceKind.toolPermission;
      case 'mcpServer':
        return WorkspaceResourceKind.mcpServer;
      case 'skill':
        return WorkspaceResourceKind.skill;
      case 'skillSetting':
        return WorkspaceResourceKind.skillSetting;
      case 'conversationToolSelection':
        return WorkspaceResourceKind.conversationToolSelection;
      case 'conversationSkillSelection':
        return WorkspaceResourceKind.conversationSkillSelection;
      case 'compactionSetting':
        return WorkspaceResourceKind.compactionSetting;
      case 'workspaceSetting':
        return WorkspaceResourceKind.workspaceSetting;
      case 'workflow':
        return WorkspaceResourceKind.workflow;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "WorkspaceResourceKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
