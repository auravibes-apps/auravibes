import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceConnectionListItem', () {
    test('maps model Connections', () {
      final item = ServiceConnectionListItem.fromModelConnection(
        _modelConnection(),
      );

      expect(item.id, 'model-1');
      expect(item.workspaceId, 'workspace-1');
      expect(item.name, 'OpenAI Main');
      expect(item.serviceName, 'gpt-4.1');
      expect(item.kind, ServiceConnectionListItemKind.modelProvider);
      expect(item.keySuffix, 'sk-1');
    });

    test('maps generic Connector Connections', () {
      final item = ServiceConnectionListItem.fromConnectorConnection(
        id: 'connector-1',
        workspaceId: 'workspace-1',
        name: 'Notion work',
        serviceId: 'notion',
        keySuffix: 'tion',
        hasSecret: true,
      );

      expect(item.id, 'connector-1');
      expect(item.workspaceId, 'workspace-1');
      expect(item.name, 'Notion work');
      expect(item.serviceName, 'notion');
      expect(item.kind, ServiceConnectionListItemKind.connector);
      expect(item.keySuffix, 'tion');
      expect(item.displayStatus, ServiceConnectionDisplayStatus.connected);
    });

    test('shows a generic Connector without a secret as unavailable', () {
      final item = ServiceConnectionListItem.fromConnectorConnection(
        id: 'connector-1',
        workspaceId: 'workspace-1',
        name: 'Notion work',
        serviceId: 'notion',
        keySuffix: null,
        hasSecret: false,
      );

      expect(item.kind, ServiceConnectionListItemKind.connector);
      expect(item.displayStatus, ServiceConnectionDisplayStatus.unknown);
    });
  });
}

ModelConnectionEntity _modelConnection() {
  final timestamp = DateTime(2026);

  return ModelConnectionEntity(
    id: 'model-1',
    name: 'OpenAI Main',
    modelId: 'gpt-4.1',
    createdAt: timestamp,
    updatedAt: timestamp,
    workspaceId: 'workspace-1',
    hasKey: true,
    keySuffix: 'sk-1',
  );
}
