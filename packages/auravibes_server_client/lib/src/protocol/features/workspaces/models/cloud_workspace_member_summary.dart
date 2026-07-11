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

abstract class CloudWorkspaceMemberSummary implements _i1.SerializableModel {
  CloudWorkspaceMemberSummary._({
    required this.userId,
    this.email,
    required this.role,
    required this.createdAt,
  });

  factory CloudWorkspaceMemberSummary({
    required String userId,
    String? email,
    required String role,
    required DateTime createdAt,
  }) = _CloudWorkspaceMemberSummaryImpl;

  factory CloudWorkspaceMemberSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceMemberSummary(
      userId: jsonSerialization['userId'] as String,
      email: jsonSerialization['email'] as String?,
      role: jsonSerialization['role'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  String userId;

  String? email;

  String role;

  DateTime createdAt;

  /// Returns a shallow copy of this [CloudWorkspaceMemberSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspaceMemberSummary copyWith({
    String? userId,
    String? email,
    String? role,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceMemberSummary',
      'userId': userId,
      if (email != null) 'email': email,
      'role': role,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudWorkspaceMemberSummaryImpl extends CloudWorkspaceMemberSummary {
  _CloudWorkspaceMemberSummaryImpl({
    required String userId,
    String? email,
    required String role,
    required DateTime createdAt,
  }) : super._(
         userId: userId,
         email: email,
         role: role,
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
    DateTime? createdAt,
  }) {
    return CloudWorkspaceMemberSummary(
      userId: userId ?? this.userId,
      email: email is String? ? email : this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
