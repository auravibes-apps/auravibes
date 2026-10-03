import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoadedManifests(final List<SkillManifest> _manifests)
    implements BuildLoadedSkillManifestsUsecase {
  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => _manifests;
}

void main() {
  test('builds call_skill_tool args from loaded tool contracts', () async {
    final usecase = BuildDynamicSkillToolSpecsUsecase(
      _LoadedManifests([
        SkillManifest(
          slug: 'research',
          title: 'Research',
          description: 'Search sources.',
          revision: 'r1',
          tools: [
            SkillManifestTool(
              name: 'search',
              description: 'Search sources.',
              inputJsonSchema: const {
                'type': 'object',
                'properties': {
                  'query': {'type': 'string'},
                  'limit': {'type': 'integer'},
                },
                'required': ['query'],
                'additionalProperties': false,
              },
              optionalNullMeansOmission: true,
            ),
          ],
        ),
      ]),
    );

    final specs = await usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );
    final callSkill = specs.singleWhere(
      (spec) => spec.name == callSkillToolName,
    );

    expect(
      (callSkill.inputJsonSchema['properties']!
          as Map<String, Object?>)['args'],
      {
        'anyOf': [
          {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
              'limit': {
                'type': ['integer', 'null'],
              },
            },
            'required': ['query', 'limit'],
            'additionalProperties': false,
          },
        ],
      },
    );
    expect(
      strictToolSchemaIssue(
        Map<String, dynamic>.from(callSkill.inputJsonSchema),
      ),
      isNull,
    );
  });

  test(
    'keeps stable call name and typed fallback for unsupported contracts',
    () async {
      final usecase = BuildDynamicSkillToolSpecsUsecase(
        _LoadedManifests([
          SkillManifest(
            slug: 'research',
            title: 'Research',
            description: 'Search sources.',
            revision: 'r1',
            tools: [
              SkillManifestTool(
                name: 'search',
                description: 'Search sources.',
                inputJsonSchema: const {
                  'type': 'object',
                  'properties': {
                    'filters': {
                      'type': 'object',
                      'properties': {
                        'tag': {'type': 'string'},
                      },
                      'additionalProperties': true,
                    },
                  },
                  'required': <String>[],
                  'additionalProperties': false,
                },
              ),
            ],
          ),
        ]),
      );

      final callSkill = (await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      )).singleWhere((spec) => spec.name == callSkillToolName);

      expect(callSkill.name, callSkillToolName);
      expect(
        strictToolSchemaIssue(
          Map<String, dynamic>.from(callSkill.inputJsonSchema),
        )?.path,
        r'$.properties.args.anyOf[0].required',
      );
    },
  );
}
