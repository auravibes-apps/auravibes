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

import '../../../features/workspace_state/models/workspace_resource_page_request.dart'
    as _i2;

import 'package:auravibes_server/src/generated/protocol.dart' as _i3;

abstract class ReadWorkspaceStateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ReadWorkspaceStateRequest._({
    required this.workspaceId,
    required this.pages,
    this.afterSequence,
    required this.eventLimit,
  });

  factory ReadWorkspaceStateRequest({
    required int workspaceId,
    required List<_i2.WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    required int eventLimit,
  }) = _ReadWorkspaceStateRequestImpl;

  factory ReadWorkspaceStateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ReadWorkspaceStateRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      pages: _i3.Protocol().deserialize<List<_i2.WorkspaceResourcePageRequest>>(
        jsonSerialization['pages'],
      ),
      afterSequence: jsonSerialization['afterSequence'] as int?,
      eventLimit: jsonSerialization['eventLimit'] as int,
    );
  }

  int workspaceId;

  List<_i2.WorkspaceResourcePageRequest> pages;

  int? afterSequence;

  int eventLimit;

  /// Returns a shallow copy of this [ReadWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReadWorkspaceStateRequest copyWith({
    int? workspaceId,
    List<_i2.WorkspaceResourcePageRequest>? pages,
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
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReadWorkspaceStateRequestImpl extends ReadWorkspaceStateRequest {
  _ReadWorkspaceStateRequestImpl({
    required int workspaceId,
    required List<_i2.WorkspaceResourcePageRequest> pages,
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
  @_i1.useResult
  @override
  ReadWorkspaceStateRequest copyWith({
    int? workspaceId,
    List<_i2.WorkspaceResourcePageRequest>? pages,
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
