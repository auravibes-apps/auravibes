import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/execution/run_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/execution/skill_http_client.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';

class const AppSkillExecutor(
  final RunSkillUrlTemplate _runSkillUrlTemplate,
  final SkillHttpClient _httpClient,
) {
  CancelableOperation<Object?> run({
    required AppSkillDefinition skill,
    required String toolSlug,
    required Map<String, dynamic> input,
    Map<String, String> credentials = const {},
  }) {
    final resolvedTool = _toolBySlug(skill, toolSlug);
    if (resolvedTool == null) {
      throw UnsupportedError('Unknown app skill tool: ${skill.slug}/$toolSlug');
    }

    final template = resolvedTool.urlTemplate;
    if (template != null) {
      return _runSkillUrlTemplate
          .call(
            template: template.template,
            inputs: input,
            credentials: credentials,
            inputDefinitions: template.inputs,
            credentialDefinitions: template.credentialDefinitions,
          )
          .then<Object?>((response) => response.body);
    }

    final callback = resolvedTool.callback;
    if (callback != null) {
      return callback({...input, 'credential': credentials}, _httpClient);
    }

    throw UnsupportedError('App skill tool has no executor: $toolSlug');
  }

  AppSkillToolDefinition? _toolBySlug(
    AppSkillDefinition skill,
    String toolSlug,
  ) {
    for (final tool in skill.nativeTools) {
      if (tool.slug == toolSlug) return tool;
    }

    return null;
  }
}
