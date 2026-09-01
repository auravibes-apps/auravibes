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

import '../../../features/workspace_state/models/workspace_resource_page.dart'
    as _i2;
import '../../../features/workspaces/models/workspace_event.dart' as _i3;

import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i4;

abstract class ReadWorkspaceStateResponse._({
  required var List<_i2.WorkspaceResourcePage> pages,
  required var int currentSequence,
  required var List<_i3.WorkspaceEvent> events,
  var int? earliestRetainedSequence,
  required var bool requiresSnapshot,
}) implements _i1.SerializableModel {
  factory({
    required List<_i2.WorkspaceResourcePage> pages,
    required int currentSequence,
    required List<_i3.WorkspaceEvent> events,
    int? earliestRetainedSequence,
    required bool requiresSnapshot,
  }) = _ReadWorkspaceStateResponseImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ReadWorkspaceStateResponse(
      pages: _i4.Protocol().deserialize<List<_i2.WorkspaceResourcePage>>(
        jsonSerialization['pages'],
      ),
      currentSequence: jsonSerialization['currentSequence'] as int,
      events: _i4.Protocol().deserialize<List<_i3.WorkspaceEvent>>(
        jsonSerialization['events'],
      ),
      earliestRetainedSequence:
          jsonSerialization['earliestRetainedSequence'] as int?,
      requiresSnapshot: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['requiresSnapshot'],
      ),
    );
  }

  /// Returns a shallow copy of this [ReadWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReadWorkspaceStateResponse copyWith({
    List<_i2.WorkspaceResourcePage>? pages,
    int? currentSequence,
    List<_i3.WorkspaceEvent>? events,
    int? earliestRetainedSequence,
    bool? requiresSnapshot,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReadWorkspaceStateResponse',
      'pages': pages.toJson(valueToJson: (v) => v.toJson()),
      'currentSequence': currentSequence,
      'events': events.toJson(valueToJson: (v) => v.toJson()),
      if (earliestRetainedSequence != null)
        'earliestRetainedSequence': earliestRetainedSequence,
      'requiresSnapshot': requiresSnapshot,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ReadWorkspaceStateResponseImpl({
  required List<_i2.WorkspaceResourcePage> pages,
  required int currentSequence,
  required List<_i3.WorkspaceEvent> events,
  int? earliestRetainedSequence,
  required bool requiresSnapshot,
}) extends ReadWorkspaceStateResponse {
  this
    : super._(
        pages: pages,
        currentSequence: currentSequence,
        events: events,
        earliestRetainedSequence: earliestRetainedSequence,
        requiresSnapshot: requiresSnapshot,
      );

  /// Returns a shallow copy of this [ReadWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReadWorkspaceStateResponse copyWith({
    List<_i2.WorkspaceResourcePage>? pages,
    int? currentSequence,
    List<_i3.WorkspaceEvent>? events,
    Object? earliestRetainedSequence = _Undefined,
    bool? requiresSnapshot,
  }) {
    return ReadWorkspaceStateResponse(
      pages: pages ?? this.pages.map((e0) => e0.copyWith()).toList(),
      currentSequence: currentSequence ?? this.currentSequence,
      events: events ?? this.events.map((e0) => e0.copyWith()).toList(),
      earliestRetainedSequence: earliestRetainedSequence is int?
          ? earliestRetainedSequence
          : this.earliestRetainedSequence,
      requiresSnapshot: requiresSnapshot ?? this.requiresSnapshot,
    );
  }
}
