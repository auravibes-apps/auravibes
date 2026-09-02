import 'package:auravibes_engine/src/skills/skill_command.dart';
import 'package:auravibes_engine/src/tool_name_resolver.dart';

typedef ResolveSkillApprovalTarget = Future<AgentResolvedToolName?> Function(
  SkillCommandTarget command,
);

Future<AgentResolvedToolName?> resolveEffectiveToolApprovalTarget({
  required AgentResolvedToolName requestedTarget,
  required Map<String, Object?> arguments,
  required ResolveSkillApprovalTarget resolveSkillTarget,
}) async {
  if (requestedTarget.kind != AgentResolvedToolKind.skillControl ||
      requestedTarget.toolIdentifier != callSkillToolName) {
    return requestedTarget;
  }

  final SkillCommandTarget command;
  try {
    command = SkillCommandTarget.fromArguments(arguments);
  } on FormatException {
    return null;
  }

  return await resolveSkillTarget(command);
}
