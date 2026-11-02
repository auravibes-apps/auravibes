import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('keeps Connector tool execution metadata in the catalog', () {
    final container = ProviderContainer.test();
    final tool = container
        .read(connectorToolCatalogProvider)
        .singleWhere((item) => item.toolId == 'connector/brave/web_search');

    expect(tool.connectorName, 'Brave Search');
    expect(tool.requiresConnection, isTrue);
    expect(tool.inputJsonSchema['required'], contains('query'));
  });
}
