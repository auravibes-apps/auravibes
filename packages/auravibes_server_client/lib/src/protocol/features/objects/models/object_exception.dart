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

import '../../../features/objects/models/object_error_code.dart' as _isve5p20;

abstract class ObjectException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  ObjectException._({required this.code});

  factory ObjectException({required _isve5p20.ObjectErrorCode code}) =
      _ObjectExceptionImpl;

  factory ObjectException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectException(
      code: _isve5p20.ObjectErrorCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
    );
  }

  _isve5p20.ObjectErrorCode code;

  /// Returns a shallow copy of this [ObjectException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ObjectException copyWith({_isve5p20.ObjectErrorCode? code});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectException',
      'code': code.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ObjectException',
      'code': code.toJson(),
    };
  }

  @override
  String toString() {
    return 'ObjectException(code: $code)';
  }
}

class _ObjectExceptionImpl extends ObjectException {
  _ObjectExceptionImpl({required _isve5p20.ObjectErrorCode code})
    : super._(code: code);

  /// Returns a shallow copy of this [ObjectException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ObjectException copyWith({_isve5p20.ObjectErrorCode? code}) {
    return ObjectException(code: code ?? this.code);
  }
}
