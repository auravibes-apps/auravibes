import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

List<McpCatalogListing> filterMcpCatalog(
  List<McpCatalogListing> listings, {
  String query = '',
  String? transport,
  String? authType,
}) {
  final term = query.trim().toLowerCase();
  return listings.where((listing) {
    return (term.isEmpty ||
            listing.name.toLowerCase().contains(term) ||
            listing.description.toLowerCase().contains(term)) &&
        (transport == null || listing.transport == transport) &&
        (authType == null ||
            listing.options.any((option) => option.authType == authType));
  }).toList();
}

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

  McpServerFormToCreate toForm() {
    if (missingRequiredFields.isNotEmpty) {
      throw const FormatException('Required catalog fields are missing.');
    }
    if (option.authType == 'oauth' &&
        option.fields.any(
          (field) => field.key != 'clientId' || field.isSecret,
        )) {
      throw const FormatException('Unsupported OAuth catalog field.');
    }
    if ({'none', 'apiKey', 'httpHeaders'}.contains(option.authType)) {
      final names = <String>{};
      if (option.fields.any(
        (field) => !names.add(field.key.toLowerCase()),
      )) {
        throw const FormatException('Duplicate catalog HTTP header.');
      }
    }
    final submitted = {
      for (final field in option.fields)
        if (values[field.key]?.trim().isNotEmpty == true)
          field.key: values[field.key]!.trim(),
    };
    if (option.authType == 'apiKey' &&
        (option.fields.length != 1 || !option.fields.single.isSecret)) {
      throw const FormatException('Invalid API key catalog option.');
    }
    if (option.authType == 'bearerToken' &&
        (option.fields.length != 1 || !option.fields.single.isSecret)) {
      throw const FormatException('Invalid bearer catalog option.');
    }
    final auth = switch (option.authType) {
      'none' when submitted.isEmpty => McpAuthenticationTypeOptions.none,
      'none' ||
      'apiKey' ||
      'httpHeaders' => McpAuthenticationTypeOptions.httpHeaders,
      'bearerToken' => McpAuthenticationTypeOptions.bearerToken,
      'oauth' => McpAuthenticationTypeOptions.oauth,
      _ => throw const FormatException('Unsupported catalog auth type.'),
    };
    final headers = auth == McpAuthenticationTypeOptions.httpHeaders
        ? submitted
        : null;
    if (headers != null) _validateHeaderFields(headers);
    return McpServerFormToCreate(
      name: snapshot['name']! as String,
      url: snapshot['url']! as String,
      transport: switch (snapshot['transport']) {
        'streamableHttp' => const McpTransportTypeStreamableHttp(),
        'sse' => const McpTransportTypeSSE(),
        _ => throw const FormatException('Unsupported catalog transport.'),
      },
      authenticationType: auth,
      bearerToken: auth == McpAuthenticationTypeOptions.bearerToken
          ? submitted.values.firstOrNull
          : null,
      oauthClientId: auth == McpAuthenticationTypeOptions.oauth
          ? submitted['clientId']
          : null,
      description: snapshot['description']! as String,
      httpHeaders: headers,
      catalogSnapshotJson: jsonEncode(snapshot),
    );
  }

  @override
  String toString() =>
      'McpCatalogInstallation(workspaceId: $workspaceId, '
      'listingId: ${listing.id}, optionKey: ${option.key})';
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
