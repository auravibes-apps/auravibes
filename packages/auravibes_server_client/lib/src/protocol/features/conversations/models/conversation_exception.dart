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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/conversations/models/conversation_error_code.dart'
    as _ipst1272;

abstract class ConversationException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  ConversationException._({required this.code});

  factory ConversationException({
    required _ipst1272.ConversationErrorCode code,
  }) = _ConversationExceptionImpl;

  factory ConversationException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationException(
      code: _ipst1272.ConversationErrorCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
    );
  }

  _ipst1272.ConversationErrorCode code;

  /// Returns a shallow copy of this [ConversationException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationException copyWith({_ipst1272.ConversationErrorCode? code});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationException',
      'code': code.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
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

class _ConversationExceptionImpl extends ConversationException {
  _ConversationExceptionImpl({required _ipst1272.ConversationErrorCode code})
    : super._(code: code);

  /// Returns a shallow copy of this [ConversationException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationException copyWith({_ipst1272.ConversationErrorCode? code}) {
    return ConversationException(code: code ?? this.code);
  }
}
