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

abstract class CloudWorkspaceSummary implements _i1.SerializableModel {
  CloudWorkspaceSummary._({
    required this.id,
    required this.name,
    required this.role,
    required this.revision,
    required this.sequence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CloudWorkspaceSummary({
    required int id,
    required String name,
    required String role,
    required int revision,
    required int sequence,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CloudWorkspaceSummaryImpl;

  factory CloudWorkspaceSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceSummary(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] as String,
      revision: jsonSerialization['revision'] as int,
      sequence: jsonSerialization['sequence'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int id;

  String name;

  String role;

  int revision;

  int sequence;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [CloudWorkspaceSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspaceSummary copyWith({
    int? id,
    String? name,
    String? role,
    int? revision,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceSummary',
      'id': id,
      'name': name,
      'role': role,
      'revision': revision,
      'sequence': sequence,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CloudWorkspaceSummaryImpl extends CloudWorkspaceSummary {
  _CloudWorkspaceSummaryImpl({
    required int id,
    required String name,
    required String role,
    required int revision,
    required int sequence,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         role: role,
         revision: revision,
         sequence: sequence,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [CloudWorkspaceSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudWorkspaceSummary copyWith({
    int? id,
    String? name,
    String? role,
    int? revision,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CloudWorkspaceSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      revision: revision ?? this.revision,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
