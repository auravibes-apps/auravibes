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
import '../../../features/objects/models/object_error_code.dart' as _i2;

abstract class ObjectException
    implements _i1.SerializableException, _i1.SerializableModel {
  ObjectException._({required this.code});

  factory ObjectException({required _i2.ObjectErrorCode code}) =
      _ObjectExceptionImpl;

  factory ObjectException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectException(
      code: _i2.ObjectErrorCode.fromJson((jsonSerialization['code'] as String)),
    );
  }

  _i2.ObjectErrorCode code;

  /// Returns a shallow copy of this [ObjectException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ObjectException copyWith({_i2.ObjectErrorCode? code});
  @override
  Map<String, dynamic> toJson() {
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
  _ObjectExceptionImpl({required _i2.ObjectErrorCode code})
    : super._(code: code);

  /// Returns a shallow copy of this [ObjectException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ObjectException copyWith({_i2.ObjectErrorCode? code}) {
    return ObjectException(code: code ?? this.code);
  }
}
