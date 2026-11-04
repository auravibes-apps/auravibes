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

abstract class SetConversationLabelsRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SetConversationLabelsRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.labelIds,
  });

  factory SetConversationLabelsRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required List<String> labelIds,
  }) = _SetConversationLabelsRequestImpl;

  factory SetConversationLabelsRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SetConversationLabelsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      labelIds: _isctvzjc.Protocol().deserialize<List<String>>(
        jsonSerialization['labelIds'],
      ),
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  List<String> labelIds;

  /// Returns a shallow copy of this [SetConversationLabelsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SetConversationLabelsRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    List<String>? labelIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SetConversationLabelsRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'labelIds': labelIds.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SetConversationLabelsRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'labelIds': labelIds.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SetConversationLabelsRequestImpl extends SetConversationLabelsRequest {
  _SetConversationLabelsRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required List<String> labelIds,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         labelIds: labelIds,
       );

  /// Returns a shallow copy of this [SetConversationLabelsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SetConversationLabelsRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    List<String>? labelIds,
  }) {
    return SetConversationLabelsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      labelIds: labelIds ?? this.labelIds.map((e0) => e0).toList(),
    );
  }
}
