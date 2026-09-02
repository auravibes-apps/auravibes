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

abstract class StartCodexOAuthResult._({
  required var String transactionId,
  required var String authorizationUrl,
  required var DateTime expiresAt,
}) implements _i1.SerializableModel {
  factory({
    required String transactionId,
    required String authorizationUrl,
    required DateTime expiresAt,
  }) = _StartCodexOAuthResultImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StartCodexOAuthResult(
      transactionId: jsonSerialization['transactionId'] as String,
      authorizationUrl: jsonSerialization['authorizationUrl'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [StartCodexOAuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StartCodexOAuthResult copyWith({
    String? transactionId,
    String? authorizationUrl,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StartCodexOAuthResult',
      'transactionId': transactionId,
      'authorizationUrl': authorizationUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StartCodexOAuthResultImpl({
  required String transactionId,
  required String authorizationUrl,
  required DateTime expiresAt,
}) extends StartCodexOAuthResult {
  this
    : super._(
        transactionId: transactionId,
        authorizationUrl: authorizationUrl,
        expiresAt: expiresAt,
      );

  /// Returns a shallow copy of this [StartCodexOAuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StartCodexOAuthResult copyWith({
    String? transactionId,
    String? authorizationUrl,
    DateTime? expiresAt,
  }) {
    return StartCodexOAuthResult(
      transactionId: transactionId ?? this.transactionId,
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
