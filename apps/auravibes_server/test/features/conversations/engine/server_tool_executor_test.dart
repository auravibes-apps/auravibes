import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:test/test.dart';

void main() {
  const skills = [
    {
      'id': 'skill-1',
      'slug': 'research',
      'title': 'Research',
      'content': 'Use primary sources.',
      'isEnabled': true,
    },
  ];
  final descriptor = AgentResolvedToolName.skillTemplate(
    tableId: 'tool-1',
    skillSlug: 'research',
    toolIdentifier: 'search',
  );
  final tools = [
    ServerResolvedTool(
      descriptor: descriptor,
      spec: ToolSpec(
        name: descriptor.fullName,
        description: 'Search sources.',
        inputJsonSchema: const {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer'},
          },
          'required': ['limit'],
          'additionalProperties': false,
        },
      ),
    ),
  ];

  Future<SkillCommandTarget> command({
    String skill = 'research',
    String tool = 'search',
    Object? limit = 1,
    String? revision,
  }) async {
    final manifest = await buildCloudSkillManifest(
      slug: 'research',
      userSkills: skills,
      tools: tools,
    );
    return SkillCommandTarget.fromArguments({
      'skill': skill,
      'tool': tool,
      'args': {'limit': limit},
      'revision': revision ?? manifest!.revision,
    });
  }

  test('resolves current target and validates its schema', () async {
    expect(
      await resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: tools,
      ),
      same(tools.single),
    );
  });

  test('rejects unloaded target', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: const [],
      ),
      throwsStateError,
    );
  });

  test('rejects stale manifest revision', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(revision: 'stale'),
        userSkills: skills,
        tools: tools,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('list_skills to refresh'),
        ),
      ),
    );
  });

  test('rejects invalid target arguments', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(limit: 'wrong'),
        userSkills: skills,
        tools: tools,
      ),
      throwsFormatException,
    );
  });
}
