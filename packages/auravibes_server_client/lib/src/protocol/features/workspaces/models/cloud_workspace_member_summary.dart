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

abstract class CloudWorkspaceMemberSummary._({
  required var String userId,
  var String? email,
  required var String role,
  required var int revision,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    required String userId,
    String? email,
    required String role,
    required int revision,
    required DateTime createdAt,
  }) = _CloudWorkspaceMemberSummaryImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceMemberSummary(
      userId: jsonSerialization['userId'] as String,
      email: jsonSerialization['email'] as String?,
      role: jsonSerialization['role'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [CloudWorkspaceMemberSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspaceMemberSummary copyWith({
    String? userId,
    String? email,
    String? role,
    int? revision,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceMemberSummary',
      'userId': userId,
      if (email != null) 'email': email,
      'role': role,
      'revision': revision,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _CloudWorkspaceMemberSummaryImpl({
  required String userId,
  String? email,
  required String role,
  required int revision,
  required DateTime createdAt,
}) extends CloudWorkspaceMemberSummary {
  this
    : super._(
        userId: userId,
        email: email,
        role: role,
        revision: revision,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [CloudWorkspaceMemberSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudWorkspaceMemberSummary copyWith({
    String? userId,
    Object? email = _Undefined,
    String? role,
    int? revision,
    DateTime? createdAt,
  }) {
    return CloudWorkspaceMemberSummary(
      userId: userId ?? this.userId,
      email: email is String? ? email : this.email,
      role: role ?? this.role,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
