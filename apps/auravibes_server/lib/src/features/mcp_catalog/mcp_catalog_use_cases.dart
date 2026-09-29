import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'mcp_catalog_repository.dart';

class McpCatalogUseCases(final McpCatalogRepository _repository) {
  Future<List<McpCatalogListing>> list(Session session) async {
    final entries = await _repository.listEnabled(session);
    return [
      for (final entry in entries) ?_validListing(entry),
    ];
  }
}

McpCatalogListing? _validListing(McpCatalogEntry entry) {
  try {
    return parseMcpCatalogListing(entry);
  } on FormatException {
    return null;
  }
}

McpCatalogListing parseMcpCatalogListing(McpCatalogEntry entry) {
  if (entry.catalogId.trim().isEmpty ||
      entry.name.trim().isEmpty ||
      !{'streamableHttp', 'sse'}.contains(entry.transport) ||
      !_isHttpUrl(entry.url)) {
    throw const FormatException('Invalid MCP catalog listing');
  }
  final decoded = jsonDecode(entry.optionsJson);
  if (decoded is! List) {
    throw const FormatException('Invalid MCP catalog options');
  }
  final optionKeys = <String>{};
  final options = <McpCatalogConnectionOption>[];
  for (final rawOption in decoded) {
    final option = _map(rawOption, {'key', 'name', 'authType', 'fields'});
    final key = _nonEmpty(option['key']);
    final name = _nonEmpty(option['name']);
    final authType = _nonEmpty(option['authType']);
    if (!optionKeys.add(key) ||
        !{
          'none',
          'oauth',
          'bearerToken',
          'apiKey',
          'httpHeaders',
        }.contains(authType)) {
      throw const FormatException('Invalid MCP catalog option');
    }
    final rawFields = option['fields'];
    if (rawFields is! List) {
      throw const FormatException('Invalid MCP catalog fields');
    }
    final fieldKeys = <String>{};
    final fields = <McpCatalogCredentialField>[];
    for (final rawField in rawFields) {
      final field = _map(rawField, {
        'key',
        'isSecret',
        'isRequired',
        'label',
        'description',
        'helpUrl',
      });
      final fieldKey = _nonEmpty(field['key']);
      if (!fieldKeys.add(fieldKey) ||
          field['isSecret'] is! bool ||
          field['isRequired'] is! bool) {
        throw const FormatException('Invalid MCP catalog field');
      }
      final helpUrl = _optionalString(field['helpUrl']);
      if (helpUrl != null && !_isHttpUrl(helpUrl)) {
        throw const FormatException('Invalid MCP catalog help URL');
      }
      fields.add(
        McpCatalogCredentialField(
          key: fieldKey,
          isSecret: field['isSecret']! as bool,
          isRequired: field['isRequired']! as bool,
          label: _optionalString(field['label']),
          description: _optionalString(field['description']),
          helpUrl: helpUrl,
        ),
      );
    }
    if (authType == 'oauth' &&
        fields.any((field) => field.key != 'clientId' || field.isSecret)) {
      throw const FormatException('Unsupported MCP OAuth catalog field');
    }
    if ({'none', 'apiKey', 'httpHeaders'}.contains(authType)) {
      final names = <String>{};
      if (fields.any((field) => !names.add(field.key.toLowerCase()))) {
        throw const FormatException('Duplicate MCP HTTP header');
      }
    }
    options.add(
      McpCatalogConnectionOption(
        key: key,
        name: name,
        authType: authType,
        fields: fields,
      ),
    );
  }
  return McpCatalogListing(
    id: entry.catalogId,
    name: entry.name,
    description: entry.description,
    url: entry.url,
    transport: entry.transport,
    options: options,
  );
}

Map<String, Object?> _map(Object? value, Set<String> allowed) {
  if (value is! Map<String, dynamic> ||
      value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Invalid MCP catalog definition');
  }
  return value;
}

String _nonEmpty(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid MCP catalog text');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Invalid MCP catalog text');
  }
  return value;
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}
