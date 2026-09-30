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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class McpCatalogEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  McpCatalogEntry._({
    this.id,
    required this.catalogId,
    required this.name,
    required this.description,
    required this.url,
    required this.transport,
    required this.isEnabled,
    required this.optionsJson,
  });

  factory McpCatalogEntry({
    int? id,
    required String catalogId,
    required String name,
    required String description,
    required String url,
    required String transport,
    required bool isEnabled,
    required String optionsJson,
  }) = _McpCatalogEntryImpl;

  factory McpCatalogEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return McpCatalogEntry(
      id: jsonSerialization['id'] as int?,
      catalogId: jsonSerialization['catalogId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      url: jsonSerialization['url'] as String,
      transport: jsonSerialization['transport'] as String,
      isEnabled: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['isEnabled'],
      ),
      optionsJson: jsonSerialization['optionsJson'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String catalogId;

  String name;

  String description;

  String url;

  String transport;

  bool isEnabled;

  String optionsJson;

  /// Returns a shallow copy of this [McpCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  McpCatalogEntry copyWith({
    int? id,
    String? catalogId,
    String? name,
    String? description,
    String? url,
    String? transport,
    bool? isEnabled,
    String? optionsJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'McpCatalogEntry',
      if (id != null) 'id': id,
      'catalogId': catalogId,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'isEnabled': isEnabled,
      'optionsJson': optionsJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'McpCatalogEntry',
      if (id != null) 'id': id,
      'catalogId': catalogId,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'isEnabled': isEnabled,
      'optionsJson': optionsJson,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _McpCatalogEntryImpl extends McpCatalogEntry {
  _McpCatalogEntryImpl({
    int? id,
    required String catalogId,
    required String name,
    required String description,
    required String url,
    required String transport,
    required bool isEnabled,
    required String optionsJson,
  }) : super._(
         id: id,
         catalogId: catalogId,
         name: name,
         description: description,
         url: url,
         transport: transport,
         isEnabled: isEnabled,
         optionsJson: optionsJson,
       );

  /// Returns a shallow copy of this [McpCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  McpCatalogEntry copyWith({
    Object? id = _Undefined,
    String? catalogId,
    String? name,
    String? description,
    String? url,
    String? transport,
    bool? isEnabled,
    String? optionsJson,
  }) {
    return McpCatalogEntry(
      id: id is int? ? id : this.id,
      catalogId: catalogId ?? this.catalogId,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      isEnabled: isEnabled ?? this.isEnabled,
      optionsJson: optionsJson ?? this.optionsJson,
    );
  }
}
