/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../features/mcp_catalog/models/mcp_catalog_connection_option.dart'
    as _ifvbp24o;

abstract class McpCatalogListing
    implements _is.SerializableModel, _is.ProtocolSerialization {
  McpCatalogListing._({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.transport,
    required this.options,
  });

  factory McpCatalogListing({
    required String id,
    required String name,
    required String description,
    required String url,
    required String transport,
    required List<_ifvbp24o.McpCatalogConnectionOption> options,
  }) = _McpCatalogListingImpl;

  factory McpCatalogListing.fromJson(Map<String, dynamic> jsonSerialization) {
    return McpCatalogListing(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      url: jsonSerialization['url'] as String,
      transport: jsonSerialization['transport'] as String,
      options: _if5qez1k.Protocol()
          .deserialize<List<_ifvbp24o.McpCatalogConnectionOption>>(
            jsonSerialization['options'],
          ),
    );
  }

  String id;

  String name;

  String description;

  String url;

  String transport;

  List<_ifvbp24o.McpCatalogConnectionOption> options;

  /// Returns a shallow copy of this [McpCatalogListing]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  McpCatalogListing copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? transport,
    List<_ifvbp24o.McpCatalogConnectionOption>? options,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'McpCatalogListing',
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'options': options.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'McpCatalogListing',
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'options': options.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _McpCatalogListingImpl extends McpCatalogListing {
  _McpCatalogListingImpl({
    required String id,
    required String name,
    required String description,
    required String url,
    required String transport,
    required List<_ifvbp24o.McpCatalogConnectionOption> options,
  }) : super._(
         id: id,
         name: name,
         description: description,
         url: url,
         transport: transport,
         options: options,
       );

  /// Returns a shallow copy of this [McpCatalogListing]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  McpCatalogListing copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? transport,
    List<_ifvbp24o.McpCatalogConnectionOption>? options,
  }) {
    return McpCatalogListing(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      options: options ?? this.options.map((e0) => e0.copyWith()).toList(),
    );
  }
}
