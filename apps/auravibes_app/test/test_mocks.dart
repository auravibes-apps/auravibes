import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_models_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/model_connections_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_result.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_result.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

var _fallbackValuesRegistered = false;

void registerTestFallbackValues() {
  if (_fallbackValuesRegistered) return;
  _fallbackValuesRegistered = true;

  registerFallbackValue(_FakeAgentIterationContext());
  registerFallbackValue(_FakeConversationPatch());
  registerFallbackValue(_FakeConversationsCompanion());
  registerFallbackValue(_FakeConversationToCreate());
  registerFallbackValue(_FakeMcpServersCompanion());
  registerFallbackValue(_FakeMcpServerToCreate());
  registerFallbackValue(_FakeMessagePatch());
  registerFallbackValue(_FakeMessageToCreate());
  registerFallbackValue(_FakeModelConnectionFilter());
  registerFallbackValue(_FakeServiceConnectionsCompanion());
  registerFallbackValue(_FakeModelConnectionToCreate());
  registerFallbackValue(_FakeModelConnectionToUpdate());
  registerFallbackValue(_FakeResolvedTool());
  registerFallbackValue(_FakeModelProvider());
  registerFallbackValue(StackTrace.current);
  registerFallbackValue(_FakeToolsGroupsCompanion());
  registerFallbackValue(_FakeToolsGroupToCreate());
  registerFallbackValue(_FakeWorkspaceModelSelectionFilter());
  registerFallbackValue(_FakeWorkspaceModelSelectionToCreate());
  registerFallbackValue(_FakeWorkspaceModelSelectionWithConnectionEntity());
  registerFallbackValue(_FakeWorkspaceToolToCreate());
  registerFallbackValue(<WorkspaceModelSelectionsCompanion>[]);
}

class _FakeAgentIterationContext extends Fake
    implements AgentIterationContext {}

class _FakeConversationPatch extends Fake implements ConversationPatch {}

class _FakeConversationsCompanion extends Fake
    implements ConversationsCompanion {}

class _FakeConversationToCreate extends Fake implements ConversationToCreate {}

class _FakeMcpServersCompanion extends Fake implements McpServersCompanion {}

class _FakeMcpServerToCreate extends Fake implements McpServerToCreate {}

class _FakeMessagePatch extends Fake implements MessagePatch {}

class _FakeMessageToCreate extends Fake implements MessageToCreate {}

class _FakeModelConnectionFilter extends Fake
    implements ModelConnectionFilter {}

class _FakeServiceConnectionsCompanion extends Fake
    implements ServiceConnectionsCompanion {}

class _FakeModelConnectionToCreate extends Fake
    implements ModelConnectionToCreate {}

class _FakeModelConnectionToUpdate extends Fake
    implements ModelConnectionToUpdate {}

class _FakeModelProvider extends Fake implements ModelProvider {}

class _FakeResolvedTool extends Fake implements ResolvedTool {}

class _FakeToolsGroupsCompanion extends Fake implements ToolsGroupsCompanion {}

class _FakeToolsGroupToCreate extends Fake implements ToolsGroupToCreate {}

class _FakeWorkspaceModelSelectionFilter extends Fake
    implements WorkspaceModelSelectionFilter {}

class _FakeWorkspaceModelSelectionToCreate extends Fake
    implements WorkspaceModelSelectionToCreate {}

class _FakeWorkspaceModelSelectionWithConnectionEntity extends Fake
    implements WorkspaceModelSelectionWithConnectionEntity {}

class _FakeWorkspaceToolToCreate extends Fake
    implements WorkspaceToolToCreate {}

class MockApiModelProvidersDao extends Mock implements ApiModelProvidersDao {}

class MockApiModelRepository extends Mock implements ApiModelRepository {}

class MockApiModelsDao extends Mock implements ApiModelsDao {}

class MockChatResult extends Mock implements ChatResult<ChatMessage> {}

class MockChatbotService extends Mock implements ChatbotService {}

class MockContinueAgentUsecase extends Mock implements ContinueAgentUsecase {}

class MockConversationDao extends Mock implements ConversationDao {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockConversationToolsRepository extends Mock
    implements ConversationToolsRepository {}

class MockEncryptionService extends Mock implements EncryptionService {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockGenerateTitleUsecase extends Mock implements GenerateTitleUsecase {}

class MockGetAgentIterationDecisionUsecase extends Mock
    implements GetAgentIterationDecisionUsecase {}

class MockGetConversationBusyStateUsecase extends Mock
    implements GetConversationBusyStateUsecase {}

class MockLoadConversationToolSpecsUsecase extends Mock
    implements LoadConversationToolSpecsUsecase {}

class MockLoadLatestMessageToolCallsUsecase extends Mock
    implements LoadLatestMessageToolCallsUsecase {}

class MockMaybeAutoCompactConversationUsecase extends Mock
    implements MaybeAutoCompactConversationUsecase {}

class MockMcpServersDao extends Mock implements McpServersDao {}

class MockMessageRepository extends Mock implements MessageRepository {}

class MockModelApiService extends Mock implements ModelApiService {}

class MockModelConnectionsDao extends Mock implements ModelConnectionsDao {}

class MockModelProviderServices extends Mock implements ModelProviderServices {}

class MockResolveToolApprovalDecisionUsecase extends Mock
    implements ResolveToolApprovalDecisionUsecase {}

class MockResumeConversationIfReadyUsecase extends Mock
    implements ResumeConversationIfReadyUsecase {}

class MockRunAgentIterationUsecase extends Mock
    implements RunAgentIterationUsecase {}

class MockRunAllowedToolsUsecase extends Mock
    implements RunAllowedToolsUsecase {}

class MockSelectPromptMessagesUsecase extends Mock
    implements SelectPromptMessagesUsecase {}

class MockSyncSkillToolPermissionsUsecase extends Mock
    implements SyncSkillToolPermissionsUsecase {}

class NoopSyncSkillToolPermissionsUsecase extends Fake
    implements SyncSkillToolPermissionsUsecase {
  @override
  Future<void> call({
    required String conversationId,
    required String workspaceId,
  }) => Future<void>.value();

  @override
  Future<String?> permissionTableIdFor({
    required String conversationId,
    required String workspaceId,
    required String toolName,
  }) async => null;
}

class MockSendMessageUsecase extends Mock implements SendMessageUsecase {}

class MockToolResolverService extends Mock implements ToolResolverService {}

class MockToolsGroupsDao extends Mock implements ToolsGroupsDao {}

class MockToolsGroupsRepository extends Mock implements ToolsGroupsRepository {}

class MockWorkspaceDao extends Mock implements WorkspaceDao {}

class MockWorkspaceModelSelectionRepository extends Mock
    implements WorkspaceModelSelectionRepository {}

class MockWorkspaceModelSelectionsDao extends Mock
    implements WorkspaceModelSelectionsDao {}

class MockWorkspaceToolsDao extends Mock implements WorkspaceToolsDao {}

class MockWorkspaceToolsRepository extends Mock
    implements WorkspaceToolsRepository {}
