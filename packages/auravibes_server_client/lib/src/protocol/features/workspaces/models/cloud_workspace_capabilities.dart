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

abstract class CloudWorkspaceCapabilities
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CloudWorkspaceCapabilities._({
    required this.canViewMembers,
    required this.canInviteMembers,
    required this.canInviteAdmins,
    required this.canManageMembers,
    required this.canManageAdmins,
    required this.canRename,
    required this.canTransferOwnership,
    required this.canLeave,
    required this.canDelete,
  });

  factory CloudWorkspaceCapabilities({
    required bool canViewMembers,
    required bool canInviteMembers,
    required bool canInviteAdmins,
    required bool canManageMembers,
    required bool canManageAdmins,
    required bool canRename,
    required bool canTransferOwnership,
    required bool canLeave,
    required bool canDelete,
  }) = _CloudWorkspaceCapabilitiesImpl;

  factory CloudWorkspaceCapabilities.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceCapabilities(
      canViewMembers: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canViewMembers'],
      ),
      canInviteMembers: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canInviteMembers'],
      ),
      canInviteAdmins: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canInviteAdmins'],
      ),
      canManageMembers: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canManageMembers'],
      ),
      canManageAdmins: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canManageAdmins'],
      ),
      canRename: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canRename'],
      ),
      canTransferOwnership: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canTransferOwnership'],
      ),
      canLeave: _isc.BoolJsonExtension.fromJson(jsonSerialization['canLeave']),
      canDelete: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canDelete'],
      ),
    );
  }

  bool canViewMembers;

  bool canInviteMembers;

  bool canInviteAdmins;

  bool canManageMembers;

  bool canManageAdmins;

  bool canRename;

  bool canTransferOwnership;

  bool canLeave;

  bool canDelete;

  /// Returns a shallow copy of this [CloudWorkspaceCapabilities]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CloudWorkspaceCapabilities copyWith({
    bool? canViewMembers,
    bool? canInviteMembers,
    bool? canInviteAdmins,
    bool? canManageMembers,
    bool? canManageAdmins,
    bool? canRename,
    bool? canTransferOwnership,
    bool? canLeave,
    bool? canDelete,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceCapabilities',
      'canViewMembers': canViewMembers,
      'canInviteMembers': canInviteMembers,
      'canInviteAdmins': canInviteAdmins,
      'canManageMembers': canManageMembers,
      'canManageAdmins': canManageAdmins,
      'canRename': canRename,
      'canTransferOwnership': canTransferOwnership,
      'canLeave': canLeave,
      'canDelete': canDelete,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CloudWorkspaceCapabilities',
      'canViewMembers': canViewMembers,
      'canInviteMembers': canInviteMembers,
      'canInviteAdmins': canInviteAdmins,
      'canManageMembers': canManageMembers,
      'canManageAdmins': canManageAdmins,
      'canRename': canRename,
      'canTransferOwnership': canTransferOwnership,
      'canLeave': canLeave,
      'canDelete': canDelete,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CloudWorkspaceCapabilitiesImpl extends CloudWorkspaceCapabilities {
  _CloudWorkspaceCapabilitiesImpl({
    required bool canViewMembers,
    required bool canInviteMembers,
    required bool canInviteAdmins,
    required bool canManageMembers,
    required bool canManageAdmins,
    required bool canRename,
    required bool canTransferOwnership,
    required bool canLeave,
    required bool canDelete,
  }) : super._(
         canViewMembers: canViewMembers,
         canInviteMembers: canInviteMembers,
         canInviteAdmins: canInviteAdmins,
         canManageMembers: canManageMembers,
         canManageAdmins: canManageAdmins,
         canRename: canRename,
         canTransferOwnership: canTransferOwnership,
         canLeave: canLeave,
         canDelete: canDelete,
       );

  /// Returns a shallow copy of this [CloudWorkspaceCapabilities]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CloudWorkspaceCapabilities copyWith({
    bool? canViewMembers,
    bool? canInviteMembers,
    bool? canInviteAdmins,
    bool? canManageMembers,
    bool? canManageAdmins,
    bool? canRename,
    bool? canTransferOwnership,
    bool? canLeave,
    bool? canDelete,
  }) {
    return CloudWorkspaceCapabilities(
      canViewMembers: canViewMembers ?? this.canViewMembers,
      canInviteMembers: canInviteMembers ?? this.canInviteMembers,
      canInviteAdmins: canInviteAdmins ?? this.canInviteAdmins,
      canManageMembers: canManageMembers ?? this.canManageMembers,
      canManageAdmins: canManageAdmins ?? this.canManageAdmins,
      canRename: canRename ?? this.canRename,
      canTransferOwnership: canTransferOwnership ?? this.canTransferOwnership,
      canLeave: canLeave ?? this.canLeave,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}
