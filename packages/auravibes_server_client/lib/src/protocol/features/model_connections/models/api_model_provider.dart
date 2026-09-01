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

abstract class ApiModelProvider._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var String providerId,
  required var String name,
  var String? type,
  var String? url,
  var String? documentationUrl,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required String providerId,
    required String name,
    String? type,
    String? url,
    String? documentationUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApiModelProviderImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiModelProvider(
      id: jsonSerialization['id'] as int?,
      providerId: jsonSerialization['providerId'] as String,
      name: jsonSerialization['name'] as String,
      type: jsonSerialization['type'] as String?,
      url: jsonSerialization['url'] as String?,
      documentationUrl: jsonSerialization['documentationUrl'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ApiModelProvider]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiModelProvider copyWith({
    int? id,
    String? providerId,
    String? name,
    String? type,
    String? url,
    String? documentationUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiModelProvider',
      if (id != null) 'id': id,
      'providerId': providerId,
      'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
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

class _ApiModelProviderImpl({
  int? id,
  required String providerId,
  required String name,
  String? type,
  String? url,
  String? documentationUrl,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ApiModelProvider {
  this
    : super._(
        id: id,
        providerId: providerId,
        name: name,
        type: type,
        url: url,
        documentationUrl: documentationUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ApiModelProvider]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiModelProvider copyWith({
    Object? id = _Undefined,
    String? providerId,
    String? name,
    Object? type = _Undefined,
    Object? url = _Undefined,
    Object? documentationUrl = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiModelProvider(
      id: id is int? ? id : this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      type: type is String? ? type : this.type,
      url: url is String? ? url : this.url,
      documentationUrl: documentationUrl is String?
          ? documentationUrl
          : this.documentationUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
