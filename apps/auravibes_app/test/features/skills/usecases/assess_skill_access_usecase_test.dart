import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final enabledTool in [false, true]) {
    test(
      'cloud instruction availability follows enabled tools: $enabledTool',
      () async {
        final cloud = _cloudStore(enabledTool: enabledTool);
        final skill = await cloud.skill('skill');
        final _ = skill ?? fail('missing fixture');
        final result =
            await AssessSkillAccessUsecase(
              hasCredential: (_) async => false,
              hasAppCredential: (_) async => false,
              cloudStore: cloud,
            ).call(
              skill: .fromUserSkill(skill),
              tools: await cloud.tools(skill.id),
            );
        expect(result.instructionsAvailable, enabledTool);
        expect(
          result.status,
          enabledTool ? SkillAccessStatus.partial : SkillAccessStatus.missing,
        );
      },
    );
  }

  test(
    'optional missing access preserves instructions and identifies tool',
    () async {
      final requested = <String>[];
      final result = await AssessSkillAccessUsecase(
        hasCredential: (id) async {
          requested.add(id);

          return false;
        },
        hasAppCredential: (_) async => false,
      ).call(skill: _skill(optional: true), tools: [_tool()]);
      expect(result.status, SkillAccessStatus.partial);
      expect(result.instructionsAvailable, isTrue);
      expect(result.tools.single.status, SkillToolAccessStatus.missing);
      expect(result.tools.single.credentialDefinitionId, 'parent-access');
      expect(requested, ['parent-access']);
    },
  );

  test('required missing access and unknown reads remain distinct', () async {
    for (final unknown in [false, true]) {
      final result = await AssessSkillAccessUsecase(
        hasCredential: (_) async {
          if (unknown) throw StateError('metadata unavailable');

          return false;
        },
        hasAppCredential: (_) async => false,
      ).call(skill: _skill(), tools: [_tool()]);
      expect(
        result.status,
        unknown ? SkillAccessStatus.unknown : SkillAccessStatus.missing,
      );
      expect(result.instructionsAvailable, isFalse);
    }
  });

  test('assesses overrides and disabled tools independently', () async {
    final requested = <String>[];
    final result =
        await AssessSkillAccessUsecase(
          hasCredential: (id) async {
            requested.add(id);

            return id == 'parent-access';
          },
          hasAppCredential: (_) async => false,
        ).call(
          skill: _skill(),
          tools: [
            _tool(),
            _tool(id: 'override', definitionId: 'other-access'),
            _tool(
              id: 'disabled',
              definitionId: 'disabled-access',
              enabled: false,
            ),
            _tool(id: 'no-access', requiresAccess: false),
          ],
        );
    expect(result.status, SkillAccessStatus.partial);
    expect(result.tools.map((tool) => tool.status), [
      SkillToolAccessStatus.available,
      SkillToolAccessStatus.missing,
      SkillToolAccessStatus.disabled,
      SkillToolAccessStatus.available,
    ]);
    expect(requested, ['parent-access', 'other-access']);
  });

  test(
    'credentialless instructions do not inspect credential storage',
    () async {
      final result = await AssessSkillAccessUsecase(
        hasCredential: (_) => throw StateError('must not read credentials'),
        hasAppCredential: (_) => throw StateError('must not read credentials'),
      ).call(skill: _skill(definitionId: null), tools: []);
      expect(result.status, SkillAccessStatus.notRequired);
      expect(result.instructionsAvailable, isTrue);
    },
  );

  test(
    'stored credentials are reported without performing a remote request',
    () async {
      final result = await AssessSkillAccessUsecase(
        hasCredential: (_) async => true,
        hasAppCredential: (_) async => false,
      ).call(skill: _skill(), tools: [_tool()]);
      expect(result.status, SkillAccessStatus.saved);
      expect(result.tools.single.status, SkillToolAccessStatus.available);
    },
  );

  test(
    'mixed built-in tools do not turn one usable tool into complete access',
    () async {
      final result = await AssessSkillAccessUsecase(
        hasCredential: (_) =>
            throw StateError('built-in uses its candidate resolver'),
        hasAppCredential: (_) async => false,
      ).call(skill: _skill(app: true), tools: []);
      expect(result.status, SkillAccessStatus.partial);
      expect(result.tools.map((tool) => tool.status), [
        SkillToolAccessStatus.available,
        SkillToolAccessStatus.missing,
      ]);
    },
  );
}

SkillDetail _skill({
  bool optional = false,
  String? definitionId = 'parent-access',
  bool app = false,
}) => SkillDetail(
  id: 'skill',
  workspaceId: 'workspace',
  source: app ? .app : .user,
  kind: .template,
  title: 'Research',
  slug: 'research',
  description: '',
  content: 'Instructions',
  isEnabled: true,
  isCredentialOptional: optional,
  credentialDefinitionId: definitionId,
  appTools: app
      ? const [
          AppSkillToolDefinition(slug: 'free', title: 'Free', description: ''),
          AppSkillToolDefinition(
            slug: 'protected',
            title: 'Protected',
            description: '',
            requiresCredential: true,
          ),
        ]
      : const [],
);

SkillTemplateToolEntity _tool({
  String id = 'tool',
  String? definitionId,
  bool requiresAccess = true,
  bool enabled = true,
}) => SkillTemplateToolEntity(
  id: id,
  skillId: 'skill',
  templateType: .url,
  title: id,
  description: '',
  slug: id,
  isEnabled: enabled,
  requiresCredential: requiresAccess,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  credentialDefinitionId: definitionId,
);

CloudSkillStore _cloudStore({required bool enabledTool}) {
  final resources = [
    _resource(.skill, 'skill', {
      'kind': 'template',
      'title': 'Research',
      'slug': 'research',
      'description': '',
      'content': 'Instructions',
      'isEnabled': true,
      'isCredentialOptional': true,
      'credentialDefinitionId': 'parent-access',
    }),
    _resource(.skillTemplateTool, 'public', {
      'skillId': 'skill',
      'templateType': 'url',
      'title': 'Public',
      'slug': 'public',
      'description': '',
      'isEnabled': enabledTool,
      'requiresCredential': false,
      'templateJson': '{"url":"https://example.com"}',
      'inputsJson': '{}',
    }),
  ];

  return CloudSkillStore(
    .forTesting(
      patch: ({required requestId, required operations}) =>
          throw StateError('read only'),
      watch: (kinds) => Stream.value(
        resources.where((item) => kinds.contains(item.resourceKind)).toList(),
      ),
      putSecret: (_) => throw StateError('no secret writes'),
      mutateCredential: (_) => throw StateError('no credential writes'),
    ),
    'workspace',
  );
}

WorkspaceResource _resource(
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?> data,
) => WorkspaceResource(
  workspaceId: 1,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  revision: 1,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);
