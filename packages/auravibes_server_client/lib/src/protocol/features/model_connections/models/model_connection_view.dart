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

abstract class ModelConnectionView._({
  required var String id,
  required var String name,
  required var String providerId,
  var String? url,
  required var bool hasSecret,
  var String? keySuffix,
  required var int revision,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    required String id,
    required String name,
    required String providerId,
    String? url,
    required bool hasSecret,
    String? keySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ModelConnectionViewImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ModelConnectionView(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      providerId: jsonSerialization['providerId'] as String,
      url: jsonSerialization['url'] as String?,
      hasSecret: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasSecret']),
      keySuffix: jsonSerialization['keySuffix'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ModelConnectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ModelConnectionView copyWith({
    String? id,
    String? name,
    String? providerId,
    String? url,
    bool? hasSecret,
    String? keySuffix,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModelConnectionView',
      'id': id,
      'name': name,
      'providerId': providerId,
      if (url != null) 'url': url,
      'hasSecret': hasSecret,
      if (keySuffix != null) 'keySuffix': keySuffix,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ModelConnectionViewImpl({
  required String id,
  required String name,
  required String providerId,
  String? url,
  required bool hasSecret,
  String? keySuffix,
  required int revision,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ModelConnectionView {
  this
    : super._(
        id: id,
        name: name,
        providerId: providerId,
        url: url,
        hasSecret: hasSecret,
        keySuffix: keySuffix,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ModelConnectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ModelConnectionView copyWith({
    String? id,
    String? name,
    String? providerId,
    Object? url = _Undefined,
    bool? hasSecret,
    Object? keySuffix = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModelConnectionView(
      id: id ?? this.id,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      url: url is String? ? url : this.url,
      hasSecret: hasSecret ?? this.hasSecret,
      keySuffix: keySuffix is String? ? keySuffix : this.keySuffix,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
