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

enum ObjectErrorCode implements _i1.SerializableModel {
  configurationMissing,
  invalidRequest,
  unsupportedMediaType,
  sizeLimitExceeded,
  objectNotFound,
  uploadExpired,
  uploadMismatch,
  scanInfected,
  scanFailed,
  staleRevision,
  idempotencyConflict,
  objectReferenced;

  static ObjectErrorCode fromJson(String name) {
    switch (name) {
      case 'configurationMissing':
        return ObjectErrorCode.configurationMissing;
      case 'invalidRequest':
        return ObjectErrorCode.invalidRequest;
      case 'unsupportedMediaType':
        return ObjectErrorCode.unsupportedMediaType;
      case 'sizeLimitExceeded':
        return ObjectErrorCode.sizeLimitExceeded;
      case 'objectNotFound':
        return ObjectErrorCode.objectNotFound;
      case 'uploadExpired':
        return ObjectErrorCode.uploadExpired;
      case 'uploadMismatch':
        return ObjectErrorCode.uploadMismatch;
      case 'scanInfected':
        return ObjectErrorCode.scanInfected;
      case 'scanFailed':
        return ObjectErrorCode.scanFailed;
      case 'staleRevision':
        return ObjectErrorCode.staleRevision;
      case 'idempotencyConflict':
        return ObjectErrorCode.idempotencyConflict;
      case 'objectReferenced':
        return ObjectErrorCode.objectReferenced;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ObjectErrorCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
