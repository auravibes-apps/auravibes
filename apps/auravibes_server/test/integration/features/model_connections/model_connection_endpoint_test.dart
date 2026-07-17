import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/features/model_connections/domain/virtual_workspace_model_selection.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('ModelConnectionEndpoint', (sessionBuilder, endpoints) {
    test(
      'uses dedicated connection tables for authenticated CRUD and lists',
      () async {
        final userId = const Uuid().v4().toString();
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final databaseSession = session.build();
        await AuthUser.db.insertRow(
          databaseSession,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          databaseSession,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: 'models@example.com',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        await ApiModelProvider.db.insertRow(
          databaseSession,
          ApiModelProvider(
            providerId: 'openai',
            name: 'OpenAI',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ApiModel.db.insertRow(
          databaseSession,
          ApiModel(
            providerId: 'openai',
            modelId: 'gpt-test',
            name: 'GPT Test',
            limitContext: 128000,
            limitOutput: 16384,
            modalitiesInput: const ['text', 'image'],
            modalitiesOutput: const ['text'],
            costInput: 2,
            costCacheRead: 0.5,
            costOutput: 8,
            openWeights: false,
            supportsReasoning: true,
            isCanonical: true,
            supportsPriorityMode: true,
            supportsToolCalls: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect(
          (await endpoints.modelConnection.listCatalogProviders(
            session,
          )).single.providerId,
          'openai',
        );
        final catalogModels = await endpoints.modelConnection.listCatalogModels(
          session,
          providerId: 'openai',
        );
        expect(catalogModels.single.limitContext, 128000);
        expect(catalogModels.single.isCanonical, isTrue);
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              databaseSession,
              name: 'Models workspace',
              ownerUserId: userId,
              now: now,
            );
        final workspaceId = workspace.id!;

        final created = await endpoints.modelConnection.create(
          session,
          CreateModelConnectionRequest(
            workspaceId: workspaceId,
            requestId: 'create-1',
            connectionId: 'openai-primary',
            name: 'OpenAI',
            providerId: 'openai',
          ),
        );
        expect(created.id, 'openai-primary');
        expect(created.hasSecret, isFalse);
        expect(
          await WorkspaceResource.db.find(
            databaseSession,
            where: (table) => table.workspaceId.equals(workspaceId),
          ),
          isEmpty,
        );

        final listed = await endpoints.modelConnection.list(
          session,
          ListModelConnectionsRequest(workspaceId: workspaceId),
        );
        expect(listed.single.id, created.id);
        final selections = await endpoints.modelConnection.listSelections(
          session,
          ListWorkspaceModelSelectionsRequest(workspaceId: workspaceId),
        );
        expect(selections, hasLength(1));
        expect(
          selections.single.id,
          VirtualWorkspaceModelSelectionId.encode(
            connectionId: created.id,
            modelId: 'gpt-test',
          ),
        );
        expect(selections.single.modelId, 'gpt-test');
        expect(selections.single.modelName, 'GPT Test');

        final updated = await endpoints.modelConnection.update(
          session,
          UpdateModelConnectionRequest(
            workspaceId: workspaceId,
            requestId: 'update-1',
            connectionId: created.id,
            expectedRevision: created.revision,
            name: 'OpenAI Work',
          ),
        );
        expect(updated.name, 'OpenAI Work');
        expect(updated.revision, 2);

        await endpoints.modelConnection.delete(
          session,
          DeleteModelConnectionRequest(
            workspaceId: workspaceId,
            requestId: 'delete-1',
            connectionId: updated.id,
            expectedRevision: updated.revision,
          ),
        );
        expect(
          await endpoints.modelConnection.list(
            session,
            ListModelConnectionsRequest(workspaceId: workspaceId),
          ),
          isEmpty,
        );
      },
    );
  });
}
