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

import '../../../features/agents/models/agent_catalog_visibility.dart'
    as _iv2rkvle;

abstract class AgentCatalogItem
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AgentCatalogItem._({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.visibility,
    required this.skillCount,
  });

  factory AgentCatalogItem({
    required String id,
    required String name,
    required String description,
    required bool isEnabled,
    required _iv2rkvle.AgentCatalogVisibility visibility,
    required int skillCount,
  }) = _AgentCatalogItemImpl;

  factory AgentCatalogItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentCatalogItem(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      isEnabled: _is.BoolJsonExtension.fromJson(jsonSerialization['isEnabled']),
      visibility: _iv2rkvle.AgentCatalogVisibility.fromJson(
        (jsonSerialization['visibility'] as String),
      ),
      skillCount: jsonSerialization['skillCount'] as int,
    );
  }

  String id;

  String name;

  String description;

  bool isEnabled;

  _iv2rkvle.AgentCatalogVisibility visibility;

  int skillCount;

  /// Returns a shallow copy of this [AgentCatalogItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AgentCatalogItem copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    _iv2rkvle.AgentCatalogVisibility? visibility,
    int? skillCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentCatalogItem',
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'visibility': visibility.toJson(),
      'skillCount': skillCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AgentCatalogItem',
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'visibility': visibility.toJson(),
      'skillCount': skillCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AgentCatalogItemImpl extends AgentCatalogItem {
  _AgentCatalogItemImpl({
    required String id,
    required String name,
    required String description,
    required bool isEnabled,
    required _iv2rkvle.AgentCatalogVisibility visibility,
    required int skillCount,
  }) : super._(
         id: id,
         name: name,
         description: description,
         isEnabled: isEnabled,
         visibility: visibility,
         skillCount: skillCount,
       );

  /// Returns a shallow copy of this [AgentCatalogItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AgentCatalogItem copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    _iv2rkvle.AgentCatalogVisibility? visibility,
    int? skillCount,
  }) {
    return AgentCatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      visibility: visibility ?? this.visibility,
      skillCount: skillCount ?? this.skillCount,
    );
  }
}
