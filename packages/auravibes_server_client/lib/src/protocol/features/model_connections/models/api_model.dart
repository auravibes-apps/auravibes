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
import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i2;

abstract class ApiModel implements _i1.SerializableModel {
  ApiModel._({
    this.id,
    required this.providerId,
    required this.modelId,
    required this.name,
    required this.limitContext,
    required this.limitOutput,
    required this.modalitiesInput,
    required this.modalitiesOutput,
    this.family,
    required this.costInput,
    required this.costCacheRead,
    required this.costOutput,
    required this.openWeights,
    required this.supportsReasoning,
    required this.isCanonical,
    required this.supportsPriorityMode,
    required this.supportsToolCalls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiModel({
    int? id,
    required String providerId,
    required String modelId,
    required String name,
    required int limitContext,
    required int limitOutput,
    required List<String> modalitiesInput,
    required List<String> modalitiesOutput,
    String? family,
    required double costInput,
    required double costCacheRead,
    required double costOutput,
    required bool openWeights,
    required bool supportsReasoning,
    required bool isCanonical,
    required bool supportsPriorityMode,
    required bool supportsToolCalls,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApiModelImpl;

  factory ApiModel.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiModel(
      id: jsonSerialization['id'] as int?,
      providerId: jsonSerialization['providerId'] as String,
      modelId: jsonSerialization['modelId'] as String,
      name: jsonSerialization['name'] as String,
      limitContext: jsonSerialization['limitContext'] as int,
      limitOutput: jsonSerialization['limitOutput'] as int,
      modalitiesInput: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['modalitiesInput'],
      ),
      modalitiesOutput: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['modalitiesOutput'],
      ),
      family: jsonSerialization['family'] as String?,
      costInput: (jsonSerialization['costInput'] as num).toDouble(),
      costCacheRead: (jsonSerialization['costCacheRead'] as num).toDouble(),
      costOutput: (jsonSerialization['costOutput'] as num).toDouble(),
      openWeights: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['openWeights'],
      ),
      supportsReasoning: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['supportsReasoning'],
      ),
      isCanonical: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isCanonical'],
      ),
      supportsPriorityMode: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['supportsPriorityMode'],
      ),
      supportsToolCalls: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['supportsToolCalls'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String providerId;

  String modelId;

  String name;

  int limitContext;

  int limitOutput;

  List<String> modalitiesInput;

  List<String> modalitiesOutput;

  String? family;

  double costInput;

  double costCacheRead;

  double costOutput;

  bool openWeights;

  bool supportsReasoning;

  bool isCanonical;

  bool supportsPriorityMode;

  bool supportsToolCalls;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ApiModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiModel copyWith({
    int? id,
    String? providerId,
    String? modelId,
    String? name,
    int? limitContext,
    int? limitOutput,
    List<String>? modalitiesInput,
    List<String>? modalitiesOutput,
    String? family,
    double? costInput,
    double? costCacheRead,
    double? costOutput,
    bool? openWeights,
    bool? supportsReasoning,
    bool? isCanonical,
    bool? supportsPriorityMode,
    bool? supportsToolCalls,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiModel',
      if (id != null) 'id': id,
      'providerId': providerId,
      'modelId': modelId,
      'name': name,
      'limitContext': limitContext,
      'limitOutput': limitOutput,
      'modalitiesInput': modalitiesInput.toJson(),
      'modalitiesOutput': modalitiesOutput.toJson(),
      if (family != null) 'family': family,
      'costInput': costInput,
      'costCacheRead': costCacheRead,
      'costOutput': costOutput,
      'openWeights': openWeights,
      'supportsReasoning': supportsReasoning,
      'isCanonical': isCanonical,
      'supportsPriorityMode': supportsPriorityMode,
      'supportsToolCalls': supportsToolCalls,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiModelImpl extends ApiModel {
  _ApiModelImpl({
    int? id,
    required String providerId,
    required String modelId,
    required String name,
    required int limitContext,
    required int limitOutput,
    required List<String> modalitiesInput,
    required List<String> modalitiesOutput,
    String? family,
    required double costInput,
    required double costCacheRead,
    required double costOutput,
    required bool openWeights,
    required bool supportsReasoning,
    required bool isCanonical,
    required bool supportsPriorityMode,
    required bool supportsToolCalls,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         providerId: providerId,
         modelId: modelId,
         name: name,
         limitContext: limitContext,
         limitOutput: limitOutput,
         modalitiesInput: modalitiesInput,
         modalitiesOutput: modalitiesOutput,
         family: family,
         costInput: costInput,
         costCacheRead: costCacheRead,
         costOutput: costOutput,
         openWeights: openWeights,
         supportsReasoning: supportsReasoning,
         isCanonical: isCanonical,
         supportsPriorityMode: supportsPriorityMode,
         supportsToolCalls: supportsToolCalls,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ApiModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiModel copyWith({
    Object? id = _Undefined,
    String? providerId,
    String? modelId,
    String? name,
    int? limitContext,
    int? limitOutput,
    List<String>? modalitiesInput,
    List<String>? modalitiesOutput,
    Object? family = _Undefined,
    double? costInput,
    double? costCacheRead,
    double? costOutput,
    bool? openWeights,
    bool? supportsReasoning,
    bool? isCanonical,
    bool? supportsPriorityMode,
    bool? supportsToolCalls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiModel(
      id: id is int? ? id : this.id,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      name: name ?? this.name,
      limitContext: limitContext ?? this.limitContext,
      limitOutput: limitOutput ?? this.limitOutput,
      modalitiesInput:
          modalitiesInput ?? this.modalitiesInput.map((e0) => e0).toList(),
      modalitiesOutput:
          modalitiesOutput ?? this.modalitiesOutput.map((e0) => e0).toList(),
      family: family is String? ? family : this.family,
      costInput: costInput ?? this.costInput,
      costCacheRead: costCacheRead ?? this.costCacheRead,
      costOutput: costOutput ?? this.costOutput,
      openWeights: openWeights ?? this.openWeights,
      supportsReasoning: supportsReasoning ?? this.supportsReasoning,
      isCanonical: isCanonical ?? this.isCanonical,
      supportsPriorityMode: supportsPriorityMode ?? this.supportsPriorityMode,
      supportsToolCalls: supportsToolCalls ?? this.supportsToolCalls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
