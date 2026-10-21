import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('instructions need no connection when Skill has no Connector refs', () async {
    var resolverCalled = false;
    final result = await AssessSkillAccessUsecase(
      connectorReferencesReady: (_) async {
        resolverCalled = true;
        return false;
      },
    ).call(skill: _skill());

    expect(result.status, SkillAccessStatus.notRequired);
    expect(result.instructionsAvailable, isTrue);
    expect(result.tools, isEmpty);
    expect(resolverCalled, isFalse);
  });

  test('ready Connector references make Skill guidance available', () async {
    final requested = <List<String>>[];
    final result = await AssessSkillAccessUsecase(
      connectorReferencesReady: (toolIds) async {
        requested.add(toolIds);
        return true;
      },
    ).call(skill: _skill(connectorToolIds: ['connector/notion/search']));

    expect(result.status, SkillAccessStatus.saved);
    expect(result.instructionsAvailable, isTrue);
    expect(result.tools.single.id, 'connector/notion/search');
    expect(result.tools.single.status, SkillToolAccessStatus.available);
    expect(requested, [<String>['connector/notion/search']]);
  });

  test('missing references block guidance and show unavailable tools', () async {
    final result = await AssessSkillAccessUsecase(
      connectorReferencesReady: (_) async => false,
    ).call(skill: _skill(connectorToolIds: ['connector/notion/search']));

    expect(result.status, SkillAccessStatus.missing);
    expect(result.instructionsAvailable, isFalse);
    expect(result.tools.single.status, SkillToolAccessStatus.missing);
  });

  test('resolver errors report unknown access', () async {
    final result = await AssessSkillAccessUsecase(
      connectorReferencesReady: (_) => throw StateError('catalog unavailable'),
    ).call(skill: _skill(connectorToolIds: ['connector/notion/search']));

    expect(result.status, SkillAccessStatus.unknown);
    expect(result.instructionsAvailable, isFalse);
    expect(result.tools.single.status, SkillToolAccessStatus.unknown);
  });
}

SkillDetail _skill({List<String> connectorToolIds = const []}) => SkillDetail(
  id: 'skill',
  workspaceId: 'workspace',
  source: .user,
  kind: .template,
  title: 'Research',
  slug: 'research',
  description: '',
  content: 'Instructions',
  isEnabled: true,
  connectorToolIds: connectorToolIds,
);
