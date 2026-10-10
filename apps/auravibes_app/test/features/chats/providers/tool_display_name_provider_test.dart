import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_server_settings_update.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillDefinitionKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMcpServersRepository(final Map<String, McpServerEntity> _servers)
    implements McpServersRepository {
  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async =>
      _servers[serverId];

  @override
  Future<void> saveMcpTestSummary({
    required String serverId,
    required McpConnectionTestSummary summary,
  }) => throw UnimplementedError();

  @override
  Future<void> updateMcpServerSettings(McpServerSettingsUpdate update) =>
      throw UnimplementedError();

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMcpServer(String serverId) {
    throw UnimplementedError();
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) {
    throw UnimplementedError();
  }
}

ProviderContainer createContainer(
  Map<String, McpServerEntity> servers, {
  List<Object> providerOverrides = const [],
}) {
  final overrides = [
    ...providerOverrides,
    mcpServersRepositoryProvider.overrideWithValue(
      _FakeMcpServersRepository(servers),
    ),
    workspaceSessionForRouteProvider('ws1').overrideWithValue(
      const AsyncData(
        WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
      ),
    ),
  ];

  return ProviderContainer(overrides: overrides.cast());
}

void main() {
  group('toolDisplayNameProvider', () {
    test('returns display name for MCP tool with server name', () async {
      final server = McpServerEntity(
        id: 'srv1',
        workspaceId: 'ws1',
        name: 'My Server',
        url: 'https://example.com',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );

      final container = createContainer({'srv1': server});
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('ws1', 'mcp_srv1_myserver_read_file').future,
      );
      expect(name, 'My Server: Read File');
    });

    test('returns display name for built-in tool', () async {
      final container = createContainer({});
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('ws1', 'built_in_123_calculator').future,
      );
      expect(name, 'Calculator');
    });

    test('returns display name for native tool', () async {
      final container = createContainer({});
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('ws1', 'native_456_read_file').future,
      );
      expect(name, 'Read File');
    });

    test('falls back to raw name for unknown format', () async {
      final container = createContainer({});
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('ws1', 'unknown_tool').future,
      );
      expect(name, 'Unknown Tool');
    });

    test('falls back to slug when server not found', () async {
      final container = createContainer({});
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('ws1', 'mcp_missing_myserver_do_stuff').future,
      );
      expect(name, 'Myserver: Do Stuff');
    });
  });

  group('skillToolCallDisplayTitlesProvider', () {
    test('resolves saved titles for app skill tools', () async {
      const registry = AppSkillRegistry();
      final appSkill = registry.getAll().firstWhere(
        (skill) => skill.tools.isNotEmpty,
      );
      final tool = appSkill.tools.first;
      final container = createContainer(
        {},
        providerOverrides: [
          workspaceSkillsProvider('ws1').overrideWith(
            (ref) async => [
              WorkspaceSkill(
                id: appSkill.identifier,
                slug: appSkill.slug,
                title: appSkill.title,
                description: appSkill.description,
                source: .app,
                kind: appSkill.kind == AppSkillDefinitionKind.template
                    ? SkillKind.template
                    : SkillKind.native,
                isEnabled: true,
                titleKey: appSkill.titleKey,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final titles = await container.read(
        skillToolCallDisplayTitlesProvider(
          'ws1',
          appSkill.slug,
          tool.slug,
        ).future,
      );

      expect(titles, (
        skillId: appSkill.identifier,
        skillSource: SkillSource.app,
        skillTitle: appSkill.title,
        skillTitleKey: appSkill.titleKey,
        toolTitle: tool.title,
        toolTitleKey: tool.titleKey,
        toolDescription: tool.description,
        toolDescriptionKey: tool.descriptionKey,
      ));
    });

    test('resolves saved titles for user template tools', () async {
      final templateTool = SkillTemplateToolEntity(
        id: 'tool-1',
        skillId: 'skill-1',
        templateType: .url,
        title: 'Search the web',
        description: 'Searches the web.',
        slug: 'search_web',
        isEnabled: true,
        requiresCredential: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );
      final container = createContainer(
        {},
        providerOverrides: [
          workspaceSkillsProvider('ws1').overrideWith(
            (ref) async => [
              const WorkspaceSkill(
                id: 'skill-1',
                slug: 'research',
                title: 'Research Assistant',
                description: '',
                source: .user,
                kind: .template,
                isEnabled: true,
              ),
            ],
          ),
          skillTemplateToolsProvider(
            'ws1',
            'skill-1',
          ).overrideWith((ref) async => [templateTool]),
        ],
      );
      addTearDown(container.dispose);

      final titles = await container.read(
        skillToolCallDisplayTitlesProvider(
          'ws1',
          'research',
          'search_web',
        ).future,
      );

      expect(titles, (
        skillId: 'skill-1',
        skillSource: SkillSource.user,
        skillTitle: 'Research Assistant',
        skillTitleKey: null,
        toolTitle: 'Search the web',
        toolTitleKey: null,
        toolDescription: 'Searches the web.',
        toolDescriptionKey: null,
      ));
    });

    test('returns skill title when tool metadata is missing', () async {
      final container = createContainer(
        {},
        providerOverrides: [
          workspaceSkillsProvider('ws1').overrideWith(
            (ref) async => [
              const WorkspaceSkill(
                id: 'skill-1',
                slug: 'research',
                title: 'Research Assistant',
                description: '',
                source: .user,
                kind: .template,
                isEnabled: true,
              ),
            ],
          ),
          skillTemplateToolsProvider(
            'ws1',
            'skill-1',
          ).overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final titles = await container.read(
        skillToolCallDisplayTitlesProvider(
          'ws1',
          'research',
          'missing_tool',
        ).future,
      );

      expect(titles?.skillTitle, 'Research Assistant');
      expect(titles?.toolTitle, isNull);
    });

    test('returns null when skill metadata is unavailable', () async {
      final container = createContainer(
        {},
        providerOverrides: [
          workspaceSkillsProvider('ws1').overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final titles = await container.read(
        skillToolCallDisplayTitlesProvider(
          'ws1',
          'missing_skill',
          'missing_tool',
        ).future,
      );

      expect(titles, isNull);
    });
  });

  group('mcpServerNameProvider', () {
    test('returns null when server not found', () async {
      final container = createContainer({});
      addTearDown(container.dispose);

      final name = await container.read(
        mcpServerNameProvider('ws1', 'nonexistent').future,
      );
      expect(name, isNull);
    });

    test('returns server name when found', () async {
      final server = McpServerEntity(
        id: 'srv1',
        workspaceId: 'ws1',
        name: 'Test Server',
        url: 'https://example.com',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );

      final container = createContainer({'srv1': server});
      addTearDown(container.dispose);

      final name = await container.read(
        mcpServerNameProvider('ws1', 'srv1').future,
      );
      expect(name, 'Test Server');
    });
  });
}
