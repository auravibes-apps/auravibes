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

import '../../../features/conversations/models/conversation_error_code.dart'
    as _i2;

abstract class ConversationException._({
  required var _i2.ConversationErrorCode code,
}) implements _i1.SerializableException, _i1.SerializableModel {
  factory({required _i2.ConversationErrorCode code}) =
      _ConversationExceptionImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationException(
      code: _i2.ConversationErrorCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
    );
  }

  /// Returns a shallow copy of this [ConversationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationException copyWith({_i2.ConversationErrorCode? code});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationException',
      'code': code.toJson(),
    };
  }

  @override
  String toString() {
    return 'ConversationException(code: $code)';
  }
}

class _ConversationExceptionImpl({required _i2.ConversationErrorCode code})
    extends ConversationException {
  this : super._(code: code);

  /// Returns a shallow copy of this [ConversationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationException copyWith({_i2.ConversationErrorCode? code}) {
    return ConversationException(code: code ?? this.code);
  }
}
