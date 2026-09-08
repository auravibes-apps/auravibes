import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/services/model_provider_services/models/antropic_response_models_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('secret-bearing DTOs do not expose values through toString', () {
    final values = <({Object value, String secret})>[
      (
        value: const AddModelProviderModel(key: 'model-api-key'),
        secret: 'model-api-key',
      ),
      (
        value: const McpFormState(bearerToken: 'mcp-bearer-token'),
        secret: 'mcp-bearer-token',
      ),
      (
        value: const MessageToolCallEntity(
          id: 'call',
          name: 'tool',
          argumentsRaw: '{"token":"tool-token"}',
          responseRaw: 'tool-response-secret',
        ),
        secret: 'tool-token',
      ),
      (
        value: const MessageToolCallEntity(
          id: 'call',
          name: 'tool',
          argumentsRaw: '{"token":"tool-token"}',
          responseRaw: 'tool-response-secret',
        ),
        secret: 'tool-response-secret',
      ),
      (
        value: const ModelConnectionToCreate(
          name: 'Provider',
          workspaceId: 'workspace',
          modelId: 'model',
          key: 'connection-api-key',
        ),
        secret: 'connection-api-key',
      ),
      (
        value: const ModelConnectionToUpdate(key: 'updated-api-key'),
        secret: 'updated-api-key',
      ),
      (
        value: const SkillCredentialToCreate(
          credentialDefinitionId: 'definition',
          name: 'Credential',
          attributes: {'apiKey': 'skill-api-key'},
        ),
        secret: 'skill-api-key',
      ),
      (
        value: const SkillCredentialToUpdate(
          secretAttributes: {'apiKey': 'updated-skill-api-key'},
        ),
        secret: 'updated-skill-api-key',
      ),
      (
        value: const AntropicResponseModels.error(
          error: AntropicResponseModelsErrorMessage(
            message: 'provider-error-secret',
            type: 'provider_error',
          ),
          requestId: 'request-id',
          type: 'error',
        ),
        secret: 'provider-error-secret',
      ),
    ];

    for (final item in values) {
      expect(item.value.toString(), isNot(contains(item.secret)));
    }
  });

  test('wrapped exceptions do not expose cause values through toString', () {
    const secret = 'secret-cause-value';
    final cause = Exception(secret);
    final values = <Object>[
      AgentException('failure', cause),
      ConversationException('failure', cause),
      ConversationToolsException('failure', cause: cause),
      CompactionFailedException(cause: cause),
      McpServersException('failure', cause),
      MessageException('failure', cause),
      ModelConnectionException('failure', cause),
      WorkspaceException('failure', cause: cause),
      WorkspaceToolsException('failure', cause),
    ];

    for (final value in values) {
      expect(value.toString(), isNot(contains(secret)));
    }
  });
}
