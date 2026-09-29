import 'package:auravibes_app/features/service_connections/models/mcp_catalog_installation.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final apiKey = McpCatalogConnectionOption(
    key: 'team',
    name: 'Team',
    authType: 'httpHeaders',
    fields: [
      McpCatalogCredentialField(
        key: 'X-API-Key',
        isSecret: true,
        isRequired: true,
      ),
      McpCatalogCredentialField(
        key: 'X-Region',
        isSecret: false,
        isRequired: false,
      ),
    ],
  );
  final public = McpCatalogConnectionOption(
    key: 'public',
    name: 'Public',
    authType: 'none',
    fields: [],
  );
  final listing = McpCatalogListing(
    id: 'listing-1',
    name: 'Search',
    description: 'Finds current web pages',
    url: 'https://example.com/mcp',
    transport: 'streamableHttp',
    options: [apiKey, public],
  );

  test('searches name and description and filters transport and auth', () {
    expect(filterMcpCatalog([listing], query: 'SEARCH'), [listing]);
    expect(filterMcpCatalog([listing], query: 'web pages'), [listing]);
    expect(filterMcpCatalog([listing], query: 'missing'), isEmpty);
    expect(
      filterMcpCatalog(
        [listing],
        transport: 'streamableHttp',
        authType: 'httpHeaders',
      ),
      [listing],
    );
    expect(filterMcpCatalog([listing], transport: 'sse'), isEmpty);
    expect(filterMcpCatalog([listing], authType: 'oauth'), isEmpty);
  });

  test('validates required fields and snapshots metadata without values', () {
    final request = McpCatalogInstallation(
      workspaceId: 'workspace-a',
      listing: listing,
      option: apiKey,
      values: {'X-API-Key': 'secret-value', 'X-Region': 'eu'},
    );
    expect(request.missingRequiredFields, isEmpty);
    expect(request.snapshot['name'], 'Search');
    expect(request.snapshot['option'], isA<Map<String, Object?>>());
    expect(request.snapshot.toString(), isNot(contains('secret-value')));
    expect(request.toString(), isNot(contains('secret-value')));
    expect(request.toForm().toString(), isNot(contains('secret-value')));
    expect(request.toForm().httpHeaders, {
      'X-API-Key': 'secret-value',
      'X-Region': 'eu',
    });
    expect(
      request.toForm().catalogSnapshotJson,
      isNot(contains('secret-value')),
    );
    listing.name = 'Changed';
    apiKey.name = 'Changed option';
    expect(request.snapshot['name'], 'Search');
    expect((request.snapshot['option']! as Map)['name'], 'Team');

    final invalid = McpCatalogInstallation(
      workspaceId: 'workspace-a',
      listing: listing,
      option: apiKey,
      values: {'X-Region': 'eu'},
    );
    expect(invalid.missingRequiredFields, ['X-API-Key']);
  });

  test('rejects reserved and line-breaking HTTP header fields', () {
    for (final key in ['Host', 'X\r\nInjected']) {
      final invalidOption = McpCatalogConnectionOption(
        key: 'invalid',
        name: 'Invalid',
        authType: 'apiKey',
        fields: [
          McpCatalogCredentialField(key: key, isSecret: true, isRequired: true),
        ],
      );
      expect(
        () => McpCatalogInstallation(
          workspaceId: 'workspace-a',
          listing: listing,
          option: invalidOption,
          values: {key: 'secret-value'},
        ).toForm(),
        throwsFormatException,
      );
    }
  });
}
