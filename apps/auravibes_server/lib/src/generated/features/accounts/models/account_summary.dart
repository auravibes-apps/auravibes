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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class AccountSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AccountSummary._({
    required this.userId,
    required this.email,
  });

  factory AccountSummary({
    required String userId,
    required String email,
  }) = _AccountSummaryImpl;

  factory AccountSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountSummary(
      userId: jsonSerialization['userId'] as String,
      email: jsonSerialization['email'] as String,
    );
  }

  String userId;

  String email;

  /// Returns a shallow copy of this [AccountSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountSummary copyWith({
    String? userId,
    String? email,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountSummary',
      'userId': userId,
      'email': email,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AccountSummary',
      'userId': userId,
      'email': email,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AccountSummaryImpl extends AccountSummary {
  _AccountSummaryImpl({
    required String userId,
    required String email,
  }) : super._(
         userId: userId,
         email: email,
       );

  /// Returns a shallow copy of this [AccountSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountSummary copyWith({
    String? userId,
    String? email,
  }) {
    return AccountSummary(
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}
