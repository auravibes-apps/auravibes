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

enum CloudWorkspaceErrorCode implements _i1.SerializableModel {
  authenticationRequired,
  emailAccountRequired,
  workspaceNotFound,
  membershipRequired,
  permissionDenied,
  invalidRole,
  ownerRequired,
  ownerCannotLeave,
  ownerCannotBeRemoved,
  ownershipTransferRequired,
  inviteNotFound,
  inviteExpired,
  inviteRevoked,
  inviteEmailMismatch,
  duplicateInvite,
  duplicateMembership,
  confirmationNameMismatch,
  validationFailed,
  invalidCursor,
  staleRevision,
  idempotencyConflict,
  conflict
  ;

  static CloudWorkspaceErrorCode fromJson(String name) {
    switch (name) {
      case 'authenticationRequired':
        return CloudWorkspaceErrorCode.authenticationRequired;
      case 'emailAccountRequired':
        return CloudWorkspaceErrorCode.emailAccountRequired;
      case 'workspaceNotFound':
        return CloudWorkspaceErrorCode.workspaceNotFound;
      case 'membershipRequired':
        return CloudWorkspaceErrorCode.membershipRequired;
      case 'permissionDenied':
        return CloudWorkspaceErrorCode.permissionDenied;
      case 'invalidRole':
        return CloudWorkspaceErrorCode.invalidRole;
      case 'ownerRequired':
        return CloudWorkspaceErrorCode.ownerRequired;
      case 'ownerCannotLeave':
        return CloudWorkspaceErrorCode.ownerCannotLeave;
      case 'ownerCannotBeRemoved':
        return CloudWorkspaceErrorCode.ownerCannotBeRemoved;
      case 'ownershipTransferRequired':
        return CloudWorkspaceErrorCode.ownershipTransferRequired;
      case 'inviteNotFound':
        return CloudWorkspaceErrorCode.inviteNotFound;
      case 'inviteExpired':
        return CloudWorkspaceErrorCode.inviteExpired;
      case 'inviteRevoked':
        return CloudWorkspaceErrorCode.inviteRevoked;
      case 'inviteEmailMismatch':
        return CloudWorkspaceErrorCode.inviteEmailMismatch;
      case 'duplicateInvite':
        return CloudWorkspaceErrorCode.duplicateInvite;
      case 'duplicateMembership':
        return CloudWorkspaceErrorCode.duplicateMembership;
      case 'confirmationNameMismatch':
        return CloudWorkspaceErrorCode.confirmationNameMismatch;
      case 'validationFailed':
        return CloudWorkspaceErrorCode.validationFailed;
      case 'invalidCursor':
        return CloudWorkspaceErrorCode.invalidCursor;
      case 'staleRevision':
        return CloudWorkspaceErrorCode.staleRevision;
      case 'idempotencyConflict':
        return CloudWorkspaceErrorCode.idempotencyConflict;
      case 'conflict':
        return CloudWorkspaceErrorCode.conflict;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CloudWorkspaceErrorCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
