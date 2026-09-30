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
import 'package:serverpod/serverpod.dart' as _is;

abstract class McpCatalogCredentialField
    implements _is.SerializableModel, _is.ProtocolSerialization {
  McpCatalogCredentialField._({
    required this.key,
    required this.isSecret,
    required this.isRequired,
    this.label,
    this.description,
    this.helpUrl,
  });

  factory McpCatalogCredentialField({
    required String key,
    required bool isSecret,
    required bool isRequired,
    String? label,
    String? description,
    String? helpUrl,
  }) = _McpCatalogCredentialFieldImpl;

  factory McpCatalogCredentialField.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return McpCatalogCredentialField(
      key: jsonSerialization['key'] as String,
      isSecret: _is.BoolJsonExtension.fromJson(jsonSerialization['isSecret']),
      isRequired: _is.BoolJsonExtension.fromJson(
        jsonSerialization['isRequired'],
      ),
      label: jsonSerialization['label'] as String?,
      description: jsonSerialization['description'] as String?,
      helpUrl: jsonSerialization['helpUrl'] as String?,
    );
  }

  String key;

  bool isSecret;

  bool isRequired;

  String? label;

  String? description;

  String? helpUrl;

  /// Returns a shallow copy of this [McpCatalogCredentialField]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  McpCatalogCredentialField copyWith({
    String? key,
    bool? isSecret,
    bool? isRequired,
    String? label,
    String? description,
    String? helpUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'McpCatalogCredentialField',
      'key': key,
      'isSecret': isSecret,
      'isRequired': isRequired,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (helpUrl != null) 'helpUrl': helpUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'McpCatalogCredentialField',
      'key': key,
      'isSecret': isSecret,
      'isRequired': isRequired,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (helpUrl != null) 'helpUrl': helpUrl,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _McpCatalogCredentialFieldImpl extends McpCatalogCredentialField {
  _McpCatalogCredentialFieldImpl({
    required String key,
    required bool isSecret,
    required bool isRequired,
    String? label,
    String? description,
    String? helpUrl,
  }) : super._(
         key: key,
         isSecret: isSecret,
         isRequired: isRequired,
         label: label,
         description: description,
         helpUrl: helpUrl,
       );

  /// Returns a shallow copy of this [McpCatalogCredentialField]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  McpCatalogCredentialField copyWith({
    String? key,
    bool? isSecret,
    bool? isRequired,
    Object? label = _Undefined,
    Object? description = _Undefined,
    Object? helpUrl = _Undefined,
  }) {
    return McpCatalogCredentialField(
      key: key ?? this.key,
      isSecret: isSecret ?? this.isSecret,
      isRequired: isRequired ?? this.isRequired,
      label: label is String? ? label : this.label,
      description: description is String? ? description : this.description,
      helpUrl: helpUrl is String? ? helpUrl : this.helpUrl,
    );
  }
}
