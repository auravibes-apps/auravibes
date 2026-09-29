import 'package:auravibes_server/src/features/mcp_catalog/mcp_catalog_use_cases.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('maps a valid option and its field definitions', () {
    final listing = parseMcpCatalogListing(
      McpCatalogEntry(
        catalogId: 'example',
        name: 'Example',
        description: 'Example tools',
        url: 'https://example.com/mcp',
        transport: 'streamableHttp',
        isEnabled: true,
        optionsJson: '''[{"key":"personal","name":"Personal","authType":"apiKey","fields":[{"key":"apiKey","isSecret":true,"isRequired":true,"label":"API key","description":"Account key","helpUrl":"https://example.com/help"}]}]''',
      ),
    );

    expect(listing.id, 'example');
    expect(listing.options.single.key, 'personal');
    expect(listing.options.single.fields.single.isSecret, isTrue);
    expect(
      listing.options.single.fields.single.helpUrl,
      'https://example.com/help',
    );
    expect(listing.toJson().toString(), isNot(contains('submittedValue')));
  });

  test('rejects invalid stored option and field definitions', () {
    for (final optionsJson in [
      'not-json',
      '[{"key":"x","name":"X","authType":"apiKey","fields":[{"key":"token","isSecret":true,"isRequired":true,"value":"leak"}]}]',
      '[{"key":"x","name":"X","authType":"apiKey","fields":[{"key":"token","isSecret":true,"isRequired":true},{"key":"token","isSecret":false,"isRequired":false}]}]',
      '[{"key":"x","name":"X","authType":"unknown","fields":[]}]',
    ]) {
      expect(
        () => parseMcpCatalogListing(
          McpCatalogEntry(
            catalogId: 'example',
            name: 'Example',
            description: '',
            url: 'https://example.com/mcp',
            transport: 'streamableHttp',
            isEnabled: true,
            optionsJson: optionsJson,
          ),
        ),
        throwsFormatException,
      );
    }
  });
}
