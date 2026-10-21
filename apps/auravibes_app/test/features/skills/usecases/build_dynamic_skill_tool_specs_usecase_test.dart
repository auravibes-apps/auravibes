import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes only stable Skill activation and resource commands', () async {
    final specs = await BuildDynamicSkillToolSpecsUsecase().call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(specs.map((spec) => spec.name), [
      activateSkillToolName,
      loadSkillResourceToolName,
    ]);
    expect(specs, everyElement(isA<ToolSpec>()));
    expect(specs.map((spec) => spec.name), isNot(contains('call_skill_tool')));
  });
}
