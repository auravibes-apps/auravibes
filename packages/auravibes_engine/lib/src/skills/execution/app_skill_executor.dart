import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/execution/run_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/execution/skill_job_response_decoder.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';

class const AppSkillExecutor(final SkillTemplateExecutor _templateExecutor) {
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
      final definition = resolvedTool.definition!;
      return _templateExecutor
          .call(
            definition: definition,
            inputs: input,
            credentials: credentials,
            schema: resolvedTool.inputJsonSchema,
          )
          .then<Object?>((response) {
            final operation = resolvedTool.jobOperation;
            if (operation == null) return response.body;

            return const SkillJobResponseDecoder().call(
              provider: skill.slug,
              operation: operation,
              statusCode: response.statusCode,
              body: response.body,
              requestedJobId: input['jobId'] as String?,
            );
          });
    }

    throw UnsupportedError('App skill tool has no executor: $toolSlug');
  }

  AppSkillToolDefinition? _toolBySlug(
    AppSkillDefinition skill,
    String toolSlug,
  ) {
    for (final tool in skill.tools) {
      if (tool.slug == toolSlug) return tool;
    }

    return null;
  }
}
