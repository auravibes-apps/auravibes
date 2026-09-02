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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class DiscoveredMcpTool._({
  required var String name,
  var String? description,
  required var String inputSchemaJson,
}) implements _i1.SerializableModel {
  factory({
    required String name,
    String? description,
    required String inputSchemaJson,
  }) = _DiscoveredMcpToolImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return DiscoveredMcpTool(
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      inputSchemaJson: jsonSerialization['inputSchemaJson'] as String,
    );
  }

  /// Returns a shallow copy of this [DiscoveredMcpTool]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DiscoveredMcpTool copyWith({
    String? name,
    String? description,
    String? inputSchemaJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DiscoveredMcpTool',
      'name': name,
      if (description != null) 'description': description,
      'inputSchemaJson': inputSchemaJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _DiscoveredMcpToolImpl({
  required String name,
  String? description,
  required String inputSchemaJson,
}) extends DiscoveredMcpTool {
  this
    : super._(
        name: name,
        description: description,
        inputSchemaJson: inputSchemaJson,
      );

  /// Returns a shallow copy of this [DiscoveredMcpTool]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DiscoveredMcpTool copyWith({
    String? name,
    Object? description = _Undefined,
    String? inputSchemaJson,
  }) {
    return DiscoveredMcpTool(
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      inputSchemaJson: inputSchemaJson ?? this.inputSchemaJson,
    );
  }
}
