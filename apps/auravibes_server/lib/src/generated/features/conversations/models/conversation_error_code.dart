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

enum ConversationErrorCode implements _i1.SerializableModel {
  authenticationRequired,
  permissionDenied,
  notFound,
  validationFailed,
  staleRevision,
  idempotencyConflict,
  turnConflict,
  toolDecisionConflict
  ;

  static ConversationErrorCode fromJson(String name) {
    switch (name) {
      case 'authenticationRequired':
        return ConversationErrorCode.authenticationRequired;
      case 'permissionDenied':
        return ConversationErrorCode.permissionDenied;
      case 'notFound':
        return ConversationErrorCode.notFound;
      case 'validationFailed':
        return ConversationErrorCode.validationFailed;
      case 'staleRevision':
        return ConversationErrorCode.staleRevision;
      case 'idempotencyConflict':
        return ConversationErrorCode.idempotencyConflict;
      case 'turnConflict':
        return ConversationErrorCode.turnConflict;
      case 'toolDecisionConflict':
        return ConversationErrorCode.toolDecisionConflict;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ConversationErrorCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
