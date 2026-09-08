import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('returns direct target unchanged without calling resolver', () async {
    final requestedTarget = AgentResolvedToolName.native(
      tableId: 'url',
      toolIdentifier: 'url',
    );
    var resolverCalled = false;

    final target = await resolveEffectiveToolApprovalTarget(
      requestedTarget: requestedTarget,
      arguments: const {},
      resolveSkillTarget: (_) async {
        resolverCalled = true;
        return null;
      },
    );

    expect(target, same(requestedTarget));
    expect(resolverCalled, isFalse);
  });

  test('resolves call_skill_tool to exact nested target', () async {
    final nestedTarget = AgentResolvedToolName.skillNative(
      tableId: 'skill__app__duckduckgo__search',
      skillSlug: 'duckduckgo',
      toolIdentifier: 'search',
    );
    final target = await resolveEffectiveToolApprovalTarget(
      requestedTarget: AgentResolvedToolName.skillControl(
        toolIdentifier: callSkillToolName,
      ),
      arguments: const {
        'skill': 'duckduckgo',
        'tool': 'search',
        'args': <String, Object?>{},
        'revision': 'r1',
      },
      resolveSkillTarget: (command) async {
        expect(command.skill, 'duckduckgo');
        expect(command.tool, 'search');
        expect(command.args, isEmpty);
        expect(command.revision, 'r1');
        return nestedTarget;
      },
    );

    expect(target?.fullName, 'skill__app__duckduckgo__search');
    expect(target, same(nestedTarget));
  });

  test('returns null for malformed call_skill_tool arguments', () async {
    var resolverCalled = false;

    final target = await resolveEffectiveToolApprovalTarget(
      requestedTarget: AgentResolvedToolName.skillControl(
        toolIdentifier: callSkillToolName,
      ),
      arguments: const {'skill': 'duckduckgo'},
      resolveSkillTarget: (_) async {
        resolverCalled = true;
        return null;
      },
    );

    expect(target, isNull);
    expect(resolverCalled, isFalse);
  });

  test('returns null when nested target is unresolved', () async {
    final target = await resolveEffectiveToolApprovalTarget(
      requestedTarget: AgentResolvedToolName.skillControl(
        toolIdentifier: callSkillToolName,
      ),
      arguments: const {
        'skill': 'duckduckgo',
        'tool': 'search',
        'args': <String, Object?>{},
        'revision': 'r1',
      },
      resolveSkillTarget: (_) async => null,
    );

    expect(target, isNull);
  });

  test('propagates nested resolver errors', () async {
    final error = StateError('resolver failed');

    await expectLater(
      resolveEffectiveToolApprovalTarget(
        requestedTarget: AgentResolvedToolName.skillControl(
          toolIdentifier: callSkillToolName,
        ),
        arguments: const {
          'skill': 'duckduckgo',
          'tool': 'search',
          'args': <String, Object?>{},
          'revision': 'r1',
        },
        resolveSkillTarget: (_) async => throw error,
      ),
      throwsA(same(error)),
    );
  });
}
