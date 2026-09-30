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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

import '../../../features/workspace_state/models/workspace_resource_page_request.dart'
    as _iwpkqfsy;

abstract class ReadWorkspaceStateRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReadWorkspaceStateRequest._({
    required this.workspaceId,
    required this.pages,
    this.afterSequence,
    required this.eventLimit,
  });

  factory ReadWorkspaceStateRequest({
    required int workspaceId,
    required List<_iwpkqfsy.WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    required int eventLimit,
  }) = _ReadWorkspaceStateRequestImpl;

  factory ReadWorkspaceStateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ReadWorkspaceStateRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      pages: _if5qez1k.Protocol()
          .deserialize<List<_iwpkqfsy.WorkspaceResourcePageRequest>>(
            jsonSerialization['pages'],
          ),
      afterSequence: jsonSerialization['afterSequence'] as int?,
      eventLimit: jsonSerialization['eventLimit'] as int,
    );
  }

  int workspaceId;

  List<_iwpkqfsy.WorkspaceResourcePageRequest> pages;

  int? afterSequence;

  int eventLimit;

  /// Returns a shallow copy of this [ReadWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReadWorkspaceStateRequest copyWith({
    int? workspaceId,
    List<_iwpkqfsy.WorkspaceResourcePageRequest>? pages,
    int? afterSequence,
    int? eventLimit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReadWorkspaceStateRequest',
      'workspaceId': workspaceId,
      'pages': pages.toJson(valueToJson: (v) => v.toJson()),
      if (afterSequence != null) 'afterSequence': afterSequence,
      'eventLimit': eventLimit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReadWorkspaceStateRequest',
      'workspaceId': workspaceId,
      'pages': pages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (afterSequence != null) 'afterSequence': afterSequence,
      'eventLimit': eventLimit,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReadWorkspaceStateRequestImpl extends ReadWorkspaceStateRequest {
  _ReadWorkspaceStateRequestImpl({
    required int workspaceId,
    required List<_iwpkqfsy.WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    required int eventLimit,
  }) : super._(
         workspaceId: workspaceId,
         pages: pages,
         afterSequence: afterSequence,
         eventLimit: eventLimit,
       );

  /// Returns a shallow copy of this [ReadWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReadWorkspaceStateRequest copyWith({
    int? workspaceId,
    List<_iwpkqfsy.WorkspaceResourcePageRequest>? pages,
    Object? afterSequence = _Undefined,
    int? eventLimit,
  }) {
    return ReadWorkspaceStateRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      pages: pages ?? this.pages.map((e0) => e0.copyWith()).toList(),
      afterSequence: afterSequence is int? ? afterSequence : this.afterSequence,
      eventLimit: eventLimit ?? this.eventLimit,
    );
  }
}
