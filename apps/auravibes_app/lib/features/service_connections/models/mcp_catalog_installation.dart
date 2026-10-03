import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef McpCatalogFilter = ({
  String query,
  String? transport,
  String? authType,
});

List<McpCatalogListing> filterMcpCatalog(
  List<McpCatalogListing> listings,
  McpCatalogFilter filter,
) {
  final query = filter.query.trim().toLowerCase();

  return listings
      .where((listing) => _matchesMcpCatalogFilter(listing, query, filter))
      .toList();
}

bool _matchesMcpCatalogFilter(
  McpCatalogListing listing,
  String query,
  McpCatalogFilter filter,
) =>
    _matchesMcpCatalogText(listing, query) &&
    (filter.transport == null || listing.transport == filter.transport) &&
    (filter.authType == null ||
        listing.options.any((option) => option.authType == filter.authType));

bool _matchesMcpCatalogText(McpCatalogListing listing, String query) =>
    query.isEmpty ||
    listing.name.toLowerCase().contains(query) ||
    listing.description.toLowerCase().contains(query);

/// Transient field values never enter the copied catalog metadata.
class McpCatalogInstallation {
  new({
    required this.workspaceId,
    required McpCatalogListing listing,
    required McpCatalogConnectionOption option,
    required Map<String, String> values,
  }) : listing = listing,
       option = option,
       values = Map.unmodifiable(values),
       snapshot = Map.unmodifiable({
         'id': listing.id,
         'name': listing.name,
         'description': listing.description,
         'url': listing.url,
         'transport': listing.transport,
         'option': Map<String, Object?>.unmodifiable({
           'key': option.key,
           'name': option.name,
           'authType': option.authType,
           'fields': List<Map<String, Object?>>.unmodifiable([
             for (final field in option.fields)
               Map<String, Object?>.unmodifiable({
                 'key': field.key,
                 'isSecret': field.isSecret,
                 'isRequired': field.isRequired,
                 'label': field.label,
                 'description': field.description,
                 'helpUrl': field.helpUrl,
               }),
           ]),
         }),
       });

  final String workspaceId;
  final McpCatalogListing listing;
  final McpCatalogConnectionOption option;
  final Map<String, String> values;
  final Map<String, Object?> snapshot;

  List<String> get missingRequiredFields => [
    for (final field in option.fields)
      if (field.isRequired && (values[field.key]?.trim().isNotEmpty != true))
        field.key,
  ];

  @override
  String toString() =>
      'McpCatalogInstallation(workspaceId: $workspaceId, '
      'listingId: ${listing.id}, optionKey: ${option.key})';
}

extension _McpCatalogInstallationValidation on McpCatalogInstallation {
  void _validateRequiredFields() {
    if (missingRequiredFields.isNotEmpty) {
      throw const FormatException('Required catalog fields are missing.');
    }
  }

  void _validateOption() {
    _validateOAuthFields();
    _validateUniqueHeaderNames();
    _validateSingleSecretField('apiKey');
    _validateSingleSecretField('bearerToken');
  }

  void _validateOAuthFields() {
    if (option.authType == 'oauth' &&
        option.fields.any(
          (field) => field.key != 'clientId' || field.isSecret,
        )) {
      throw const FormatException('Unsupported OAuth catalog field.');
    }
  }

  void _validateUniqueHeaderNames() {
    if (!{'none', 'apiKey', 'httpHeaders'}.contains(option.authType)) return;
    final names = <String>{};
    if (option.fields.any((field) => !names.add(field.key.toLowerCase()))) {
      throw const FormatException('Duplicate catalog HTTP header.');
    }
  }

  void _validateSingleSecretField(String authType) {
    if (option.authType != authType) return;
    if (option.fields.length == 1 && option.fields.single.isSecret) return;
    final message = authType == 'apiKey'
        ? 'Invalid API key catalog option.'
        : 'Invalid bearer catalog option.';
    throw FormatException(message);
  }
}

extension McpCatalogInstallationForm on McpCatalogInstallation {
  McpServerFormToCreate toForm() {
    _validateRequiredFields();
    _validateOption();
    final submitted = _submittedValues();
    final auth = _authenticationType(submitted);
    final headers = _headersFor(auth, submitted);

    return _formFor(auth, submitted, headers);
  }

  Map<String, String> _submittedValues() => {
    for (final field in option.fields)
      if (values[field.key]?.trim().isNotEmpty == true)
        field.key: values[field.key]!.trim(),
  };

  McpAuthenticationTypeOptions _authenticationType(
    Map<String, String> submitted,
  ) => switch (option.authType) {
    'none' when submitted.isEmpty => McpAuthenticationTypeOptions.none,
    'none' ||
    'apiKey' ||
    'httpHeaders' => McpAuthenticationTypeOptions.httpHeaders,
    'bearerToken' => McpAuthenticationTypeOptions.bearerToken,
    'oauth' => McpAuthenticationTypeOptions.oauth,
    _ => throw const FormatException('Unsupported catalog auth type.'),
  };

  Map<String, String>? _headersFor(
    McpAuthenticationTypeOptions auth,
    Map<String, String> submitted,
  ) {
    if (auth != McpAuthenticationTypeOptions.httpHeaders) return null;
    _validateHeaderFields(submitted);

    return submitted;
  }

  McpServerFormToCreate _formFor(
    McpAuthenticationTypeOptions auth,
    Map<String, String> submitted,
    Map<String, String>? headers,
  ) => _catalogFormBase(auth).copyWith(
    bearerToken: _catalogBearerToken(auth, submitted),
    oauthClientId: _catalogOAuthClientId(auth, submitted),
    httpHeaders: headers,
  );

  McpServerFormToCreate _catalogFormBase(McpAuthenticationTypeOptions auth) =>
      McpServerFormToCreate(
        name: snapshot['name']! as String,
        url: snapshot['url']! as String,
        transport: _transportFromSnapshot(),
        authenticationType: auth,
        bearerToken: null,
        description: snapshot['description']! as String,
        catalogSnapshotJson: jsonEncode(snapshot),
      );

  String? _catalogBearerToken(
    McpAuthenticationTypeOptions auth,
    Map<String, String> submitted,
  ) => auth == McpAuthenticationTypeOptions.bearerToken
      ? submitted.values.firstOrNull
      : null;

  String? _catalogOAuthClientId(
    McpAuthenticationTypeOptions auth,
    Map<String, String> submitted,
  ) =>
      auth == McpAuthenticationTypeOptions.oauth ? submitted['clientId'] : null;

  McpTransportType _transportFromSnapshot() => switch (snapshot['transport']) {
    'streamableHttp' => const McpTransportTypeStreamableHttp(),
    'sse' => const McpTransportTypeSSE(),
    _ => throw const FormatException('Unsupported catalog transport.'),
  };
}

void _validateHeaderFields(Map<String, String> headers) {
  final namePattern = RegExp(r'^[!#$%&\x27*+.^_`|~0-9A-Za-z-]+$');
  const reserved = {
    'host',
    'content-type',
    'content-length',
    'transfer-encoding',
    'accept',
    'connection',
    'mcp-session-id',
  };
  for (final entry in headers.entries) {
    final key = entry.key.toLowerCase();
    if (!namePattern.hasMatch(entry.key) ||
        reserved.contains(key) ||
        key.startsWith('proxy-') ||
        entry.value.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid catalog HTTP header.');
    }
  }
}
