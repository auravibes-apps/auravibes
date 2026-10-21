import 'package:auravibes_engine/src/connectors/connector_definition.dart';
import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';

class ServiceSkillPreset {
  const ServiceSkillPreset({
    required this.identifier,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    required this.tools,
    this.resources = const [],
    this.compatibleModelProviderIds = const [],
  });

  final String identifier;
  final String slug;
  final String title;
  final String description;
  final String content;
  final List<ConnectorToolDefinition> tools;
  final List<AppSkillResourceDefinition> resources;
  final List<String> compatibleModelProviderIds;

  ConnectorDefinition get connector => ConnectorDefinition(
    identifier: identifier,
    title: title,
    description: description,
    tools: tools,
    compatibleModelProviderIds: compatibleModelProviderIds,
  );

  AppSkillDefinition get skill => AppSkillDefinition(
    identifier: identifier,
    slug: slug,
    title: title,
    description: description,
    content: content,
    resources: resources,
    connectorToolIds: [
      for (final tool in tools) 'connector/$identifier/${tool.slug}',
    ],
  );
}
