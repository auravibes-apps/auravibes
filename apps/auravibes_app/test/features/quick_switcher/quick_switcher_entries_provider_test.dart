import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/quick_switcher/providers/quick_switcher_entries_provider.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('includes entries only from verified workspaces', () async {
    final availableWorkspace = _workspace('available', 'Available');
    final lockedWorkspace = _workspace('locked', 'Locked');
    const availableSession = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: 'available'),
    );
    const lockedSession = WorkspaceSession(
      CloudWorkspaceRef(
        localWorkspaceId: 'locked',
        serverUrl: 'https://cloud.example',
        accountId: 'account',
        cloudWorkspaceId: 2,
      ),
    );
    final date = DateTime.utc(2026);
    final container = ProviderContainer(
      overrides: [
        allWorkspacesProvider.overrideWith(
          (_) => Stream.value([availableWorkspace, lockedWorkspace]),
        ),
        workspaceAvailabilityProvider(
          'available',
        ).overrideWith((_) async => const WorkspaceAvailable(availableSession)),
        workspaceAvailabilityProvider('locked').overrideWith(
          (_) async => const WorkspaceAuthenticationRequired(lockedSession),
        ),
        conversationsStreamProvider(
          workspaceId: 'available',
          pagination: (limit: 10, offset: 0),
        ).overrideWith(
          (_) => Stream.value([
            ConversationEntity(
              id: 'conversation',
              title: 'Recent conversation',
              workspaceId: 'available',
              isPinned: false,
              createdAt: date,
              updatedAt: date,
            ),
          ]),
        ),
        agentsProvider('available').overrideWith(
          (_) => Stream.value([
            AgentEntity(
              id: 'agent',
              workspaceId: 'available',
              name: 'Available agent',
              content: 'Prompt',
              skills: const [],
              createdAt: date,
              updatedAt: date,
            ),
          ]),
        ),
        workspaceSkillsProvider('available').overrideWith(
          (_) async => [
            const WorkspaceSkill(
              id: 'skill',
              slug: 'available-skill',
              title: 'Available skill',
              description: 'A skill',
              source: .app,
              kind: .native,
              isEnabled: true,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    final allWorkspacesSubscription = container.listen(allWorkspacesProvider, (
      _,
      _,
    ) {
      final _ = Object();
    });
    final entriesSubscription = container.listen(
      quickSwitcherEntriesProvider('available'),
      (_, _) {
        final _ = Object();
      },
    );
    addTearDown(allWorkspacesSubscription.close);
    addTearDown(entriesSubscription.close);

    final results = await container.read(
      quickSwitcherEntriesProvider('available').future,
    );

    expect(
      results.entries
          .where((entry) => entry.workspaceId == 'available')
          .map((entry) => entry.title),
      containsAll([
        'Available',
        'Recent conversation',
        'Available agent',
        'Available skill',
      ]),
    );
    expect(
      results.entries.any((entry) => entry.workspaceId == 'locked'),
      isFalse,
    );
  });
}

WorkspaceEntity _workspace(String id, String name) => WorkspaceEntity(
  id: id,
  name: name,
  type: id == 'locked' ? .remote : .local,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);
