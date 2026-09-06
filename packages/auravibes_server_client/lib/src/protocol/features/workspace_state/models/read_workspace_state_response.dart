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
import 'package:auravibes_server_client/src/protocol/protocol.dart'
    as _isctvzjc;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/workspace_state/models/workspace_resource_page.dart'
    as _ig5amtqi;
import '../../../features/workspaces/models/workspace_event.dart' as _i2zlrl9f;

abstract class ReadWorkspaceStateResponse
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReadWorkspaceStateResponse._({
    required this.pages,
    required this.currentSequence,
    required this.events,
    this.earliestRetainedSequence,
    required this.requiresSnapshot,
  });

  factory ReadWorkspaceStateResponse({
    required List<_ig5amtqi.WorkspaceResourcePage> pages,
    required int currentSequence,
    required List<_i2zlrl9f.WorkspaceEvent> events,
    int? earliestRetainedSequence,
    required bool requiresSnapshot,
  }) = _ReadWorkspaceStateResponseImpl;

  factory ReadWorkspaceStateResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ReadWorkspaceStateResponse(
      pages: _isctvzjc.Protocol()
          .deserialize<List<_ig5amtqi.WorkspaceResourcePage>>(
            jsonSerialization['pages'],
          ),
      currentSequence: jsonSerialization['currentSequence'] as int,
      events: _isctvzjc.Protocol().deserialize<List<_i2zlrl9f.WorkspaceEvent>>(
        jsonSerialization['events'],
      ),
      earliestRetainedSequence:
          jsonSerialization['earliestRetainedSequence'] as int?,
      requiresSnapshot: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['requiresSnapshot'],
      ),
    );
  }

  List<_ig5amtqi.WorkspaceResourcePage> pages;

  int currentSequence;

  List<_i2zlrl9f.WorkspaceEvent> events;

  int? earliestRetainedSequence;

  bool requiresSnapshot;

  /// Returns a shallow copy of this [ReadWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReadWorkspaceStateResponse copyWith({
    List<_ig5amtqi.WorkspaceResourcePage>? pages,
    int? currentSequence,
    List<_i2zlrl9f.WorkspaceEvent>? events,
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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReadWorkspaceStateResponse',
      'pages': pages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'currentSequence': currentSequence,
      'events': events.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (earliestRetainedSequence != null)
        'earliestRetainedSequence': earliestRetainedSequence,
      'requiresSnapshot': requiresSnapshot,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReadWorkspaceStateResponseImpl extends ReadWorkspaceStateResponse {
  _ReadWorkspaceStateResponseImpl({
    required List<_ig5amtqi.WorkspaceResourcePage> pages,
    required int currentSequence,
    required List<_i2zlrl9f.WorkspaceEvent> events,
    int? earliestRetainedSequence,
    required bool requiresSnapshot,
  }) : super._(
         pages: pages,
         currentSequence: currentSequence,
         events: events,
         earliestRetainedSequence: earliestRetainedSequence,
         requiresSnapshot: requiresSnapshot,
       );

  /// Returns a shallow copy of this [ReadWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReadWorkspaceStateResponse copyWith({
    List<_ig5amtqi.WorkspaceResourcePage>? pages,
    int? currentSequence,
    List<_i2zlrl9f.WorkspaceEvent>? events,
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
