import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/user_tools/calculator_tool.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        AppSkillToolDefinition,
        buildSkillCommandToolSpecs,
        materializeSkillToolSchema,
        skillsManagerToolSpecs,
        strictToolSchemaIssue,
        subAgentToolSpecs,
        urlToolSpec;
import 'package:flutter_test/flutter_test.dart';

typedef _SchemaEntry = ({
  String name,
  String path,
  Map<String, dynamic> schema,
});

void main() {
  test(
    'first-party fixed schemas pass strict preflight or declared exception',
    () {
      final entries = <_SchemaEntry>[
        for (final skill in const AppSkillRegistry().getRuntimeAll())
          for (final tool in skill.tools)
            (
              name: '${skill.slug}/${tool.slug}',
              path: 'AppSkillRegistry.${skill.slug}.${tool.slug}',
              schema: _appSkillSchema(tool),
            ),
        for (final spec in skillsManagerToolSpecs)
          (
            name: spec.name,
            path: 'skillsManagerToolSpecs.${spec.name}',
            schema: Map<String, dynamic>.from(spec.inputJsonSchema),
          ),
        for (final spec in buildSkillCommandToolSpecs())
          if (spec.name != 'call_skill_tool')
            (
              name: spec.name,
              path: 'buildSkillCommandToolSpecs.${spec.name}',
              schema: Map<String, dynamic>.from(spec.inputJsonSchema),
            ),
        for (final spec in subAgentToolSpecs)
          (
            name: spec.name,
            path: 'subAgentToolSpecs.${spec.name}',
            schema: Map<String, dynamic>.from(spec.inputJsonSchema),
          ),
        (
          name: urlToolSpec.name,
          path: 'urlToolSpec',
          schema: Map<String, dynamic>.from(urlToolSpec.inputJsonSchema),
        ),
        (
          name: 'calculator',
          path: 'CalculatorTool.getTool',
          schema: Map<String, dynamic>.from(
            const CalculatorTool().getTool().inputJsonSchema,
          ),
        ),
      ];
      final names = entries.map((entry) => entry.name).toList();
      expect(
        names.toSet().length,
        names.length,
        reason: 'Duplicate inventory name',
      );
      expect(
        _strictSchemaExceptions.keys.toSet().difference(names.toSet()),
        isEmpty,
        reason: 'Exception no longer has an inventoried ToolSpec',
      );

      final issues = <String>[];
      for (final entry in entries) {
        final issue = strictToolSchemaIssue(entry.schema);
        final exception = _strictSchemaExceptions[entry.name];
        if (issue == null) {
          if (exception != null) {
            issues.add(
              '${entry.name} (${entry.path}): stale strict-schema exception',
            );
          }
          continue;
        }
        if (exception == null) {
          issues.add(
            '${entry.name} (${entry.path}): ${issue.reason.name} '
            'at ${issue.path}: ${issue.detail}',
          );
          continue;
        }
        if (issue.path != exception.path) {
          issues.add(
            '${entry.name} (${entry.path}): exception changed from '
            '${exception.path} to ${issue.path}',
          );
        }
        if (exception.reason.isEmpty ||
            !exception.issue.contains('/issues/1129')) {
          issues.add(
            '${entry.name} (${entry.path}): '
            'exception needs reason and issue link',
          );
        }
      }
      expect(issues, isEmpty, reason: issues.join('\n'));
    },
  );
}

Map<String, dynamic> _appSkillSchema(AppSkillToolDefinition tool) {
  if (tool.urlTemplate == null) {
    return Map<String, dynamic>.from(tool.inputJsonSchema);
  }

  return Map<String, dynamic>.from(
    materializeSkillToolSchema(
      tool.inputJsonSchema,
      requiresCredential: tool.requiresCredential,
      credentialIds: tool.requiresCredential
          ? const ['schema-audit-credential']
          : const [],
      strictProviderSchema: true,
    ),
  );
}

typedef _StrictSchemaException = ({String path, String reason, String issue});

const _strictSchemaExceptions = <String, _StrictSchemaException>{
  'firecrawl/extract': (
    path: r'$.properties.schema.properties',
    reason: 'extraction schema accepts user-defined output properties',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
  'skill__app_native__skills_manager__update_user_skill': (
    path: r'$.required',
    reason: 'null clears credential assignment; omission preserves it',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
  'skill__app_native__skills_manager__create_skill_template_tool': (
    path: r'$.required',
    reason: 'free-form definition, template, and input objects need open keys',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
  'skill__app_native__skills_manager__update_skill_template_tool': (
    path: r'$.required',
    reason: 'free-form definition, template, and input objects need open keys',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
  'skill__app_native__skills_manager__create_skill_credential_definition': (
    path: r'$.properties.attributes.properties',
    reason: 'credential attributes have user-defined keys',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
  'skill__app_native__skills_manager__update_skill_credential_definition': (
    path: r'$.required',
    reason: 'credential attributes have user-defined keys',
    issue: 'https://github.com/auravibes-apps/auravibes/issues/1129',
  ),
};
