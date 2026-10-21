import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connector_tool_catalog_provider.g.dart';

@riverpod
List<ConnectorToolCatalogItem> connectorToolCatalog(Ref ref) {
  final skills = ref.watch(appSkillRegistryProvider).getRuntimeAll();

  return [
    for (final connector in skills)
      for (final tool in connector.tools)
        if (tool.urlTemplate != null)
          ConnectorToolCatalogItem(
            toolId: connectorToolId(connector, tool),
            connectorName: connector.title,
            title: tool.title,
            description: tool.description,
          ),
  ]..sort((left, right) {
    final connectorOrder = left.connectorName.compareTo(right.connectorName);

    return connectorOrder == 0
        ? left.title.compareTo(right.title)
        : connectorOrder;
  });
}
