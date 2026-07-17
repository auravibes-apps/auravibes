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

abstract class CompleteCodexOAuthRequest implements _i1.SerializableModel {
  CompleteCodexOAuthRequest._({
    required this.transactionId,
    required this.state,
    required this.code,
  });

  factory CompleteCodexOAuthRequest({
    required String transactionId,
    required String state,
    required String code,
  }) = _CompleteCodexOAuthRequestImpl;

  factory CompleteCodexOAuthRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CompleteCodexOAuthRequest(
      transactionId: jsonSerialization['transactionId'] as String,
      state: jsonSerialization['state'] as String,
      code: jsonSerialization['code'] as String,
    );
  }

  String transactionId;

  String state;

  String code;

  /// Returns a shallow copy of this [CompleteCodexOAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompleteCodexOAuthRequest copyWith({
    String? transactionId,
    String? state,
    String? code,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompleteCodexOAuthRequest',
      'transactionId': transactionId,
      'state': state,
      'code': code,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CompleteCodexOAuthRequestImpl extends CompleteCodexOAuthRequest {
  _CompleteCodexOAuthRequestImpl({
    required String transactionId,
    required String state,
    required String code,
  }) : super._(
         transactionId: transactionId,
         state: state,
         code: code,
       );

  /// Returns a shallow copy of this [CompleteCodexOAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompleteCodexOAuthRequest copyWith({
    String? transactionId,
    String? state,
    String? code,
  }) {
    return CompleteCodexOAuthRequest(
      transactionId: transactionId ?? this.transactionId,
      state: state ?? this.state,
      code: code ?? this.code,
    );
  }
}
