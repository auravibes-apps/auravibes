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

import '../../../features/mcp_catalog/models/mcp_catalog_credential_field.dart'
    as _i3x0ibmr;

abstract class McpCatalogConnectionOption
    implements _is.SerializableModel, _is.ProtocolSerialization {
  McpCatalogConnectionOption._({
    required this.key,
    required this.name,
    required this.authType,
    required this.fields,
  });

  factory McpCatalogConnectionOption({
    required String key,
    required String name,
    required String authType,
    required List<_i3x0ibmr.McpCatalogCredentialField> fields,
  }) = _McpCatalogConnectionOptionImpl;

  factory McpCatalogConnectionOption.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return McpCatalogConnectionOption(
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      authType: jsonSerialization['authType'] as String,
      fields: _if5qez1k.Protocol()
          .deserialize<List<_i3x0ibmr.McpCatalogCredentialField>>(
            jsonSerialization['fields'],
          ),
    );
  }

  String key;

  String name;

  String authType;

  List<_i3x0ibmr.McpCatalogCredentialField> fields;

  /// Returns a shallow copy of this [McpCatalogConnectionOption]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  McpCatalogConnectionOption copyWith({
    String? key,
    String? name,
    String? authType,
    List<_i3x0ibmr.McpCatalogCredentialField>? fields,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'McpCatalogConnectionOption',
      'key': key,
      'name': name,
      'authType': authType,
      'fields': fields.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'McpCatalogConnectionOption',
      'key': key,
      'name': name,
      'authType': authType,
      'fields': fields.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _McpCatalogConnectionOptionImpl extends McpCatalogConnectionOption {
  _McpCatalogConnectionOptionImpl({
    required String key,
    required String name,
    required String authType,
    required List<_i3x0ibmr.McpCatalogCredentialField> fields,
  }) : super._(
         key: key,
         name: name,
         authType: authType,
         fields: fields,
       );

  /// Returns a shallow copy of this [McpCatalogConnectionOption]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  McpCatalogConnectionOption copyWith({
    String? key,
    String? name,
    String? authType,
    List<_i3x0ibmr.McpCatalogCredentialField>? fields,
  }) {
    return McpCatalogConnectionOption(
      key: key ?? this.key,
      name: name ?? this.name,
      authType: authType ?? this.authType,
      fields: fields ?? this.fields.map((e0) => e0.copyWith()).toList(),
    );
  }
}
