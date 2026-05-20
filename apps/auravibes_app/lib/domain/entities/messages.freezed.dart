// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageToolCallEntity {

 String get id; String get name; String get argumentsRaw;/// The raw response from tool execution, if successful.
 String? get responseRaw;/// The result status of this tool call.
///
/// - null: Tool is pending or currently running
/// - non-null: Tool has completed with this result status
@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? get resultStatus;
/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageToolCallEntityCopyWith<MessageToolCallEntity> get copyWith => _$MessageToolCallEntityCopyWithImpl<MessageToolCallEntity>(this as MessageToolCallEntity, _$identity);

  /// Serializes this MessageToolCallEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageToolCallEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.responseRaw, responseRaw) || other.responseRaw == responseRaw)&&(identical(other.resultStatus, resultStatus) || other.resultStatus == resultStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,argumentsRaw,responseRaw,resultStatus);

@override
String toString() {
  return 'MessageToolCallEntity(id: $id, name: $name, argumentsRaw: $argumentsRaw, responseRaw: $responseRaw, resultStatus: $resultStatus)';
}


}

/// @nodoc
abstract mixin class $MessageToolCallEntityCopyWith<$Res>  {
  factory $MessageToolCallEntityCopyWith(MessageToolCallEntity value, $Res Function(MessageToolCallEntity) _then) = _$MessageToolCallEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String argumentsRaw, String? responseRaw,@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class _$MessageToolCallEntityCopyWithImpl<$Res>
    implements $MessageToolCallEntityCopyWith<$Res> {
  _$MessageToolCallEntityCopyWithImpl(this._self, this._then);

  final MessageToolCallEntity _self;
  final $Res Function(MessageToolCallEntity) _then;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? argumentsRaw = null,Object? responseRaw = freezed,Object? resultStatus = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageToolCallEntity].
extension MessageToolCallEntityPatterns on MessageToolCallEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageToolCallEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageToolCallEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageToolCallEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageToolCallEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String argumentsRaw,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that.id,_that.name,_that.argumentsRaw,_that.responseRaw,_that.resultStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String argumentsRaw,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)  $default,) {final _that = this;
switch (_that) {
case _MessageToolCallEntity():
return $default(_that.id,_that.name,_that.argumentsRaw,_that.responseRaw,_that.resultStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String argumentsRaw,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)?  $default,) {final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that.id,_that.name,_that.argumentsRaw,_that.responseRaw,_that.resultStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageToolCallEntity extends MessageToolCallEntity {
  const _MessageToolCallEntity({required this.id, required this.name, required this.argumentsRaw, this.responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) this.resultStatus}): super._();
  factory _MessageToolCallEntity.fromJson(Map<String, dynamic> json) => _$MessageToolCallEntityFromJson(json);

@override final  String id;
@override final  String name;
@override final  String argumentsRaw;
/// The raw response from tool execution, if successful.
@override final  String? responseRaw;
/// The result status of this tool call.
///
/// - null: Tool is pending or currently running
/// - non-null: Tool has completed with this result status
@override@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) final  ToolCallResultStatus? resultStatus;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageToolCallEntityCopyWith<_MessageToolCallEntity> get copyWith => __$MessageToolCallEntityCopyWithImpl<_MessageToolCallEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToolCallEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageToolCallEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.responseRaw, responseRaw) || other.responseRaw == responseRaw)&&(identical(other.resultStatus, resultStatus) || other.resultStatus == resultStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,argumentsRaw,responseRaw,resultStatus);

@override
String toString() {
  return 'MessageToolCallEntity(id: $id, name: $name, argumentsRaw: $argumentsRaw, responseRaw: $responseRaw, resultStatus: $resultStatus)';
}


}

/// @nodoc
abstract mixin class _$MessageToolCallEntityCopyWith<$Res> implements $MessageToolCallEntityCopyWith<$Res> {
  factory _$MessageToolCallEntityCopyWith(_MessageToolCallEntity value, $Res Function(_MessageToolCallEntity) _then) = __$MessageToolCallEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String argumentsRaw, String? responseRaw,@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class __$MessageToolCallEntityCopyWithImpl<$Res>
    implements _$MessageToolCallEntityCopyWith<$Res> {
  __$MessageToolCallEntityCopyWithImpl(this._self, this._then);

  final _MessageToolCallEntity _self;
  final $Res Function(_MessageToolCallEntity) _then;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? argumentsRaw = null,Object? responseRaw = freezed,Object? resultStatus = freezed,}) {
  return _then(_MessageToolCallEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}


}


/// @nodoc
mixin _$MessageMetadataEntity {

 List<MessageToolCallEntity> get toolCalls; int? get promptTokens; int? get completionTokens; int? get totalTokens; String? get thinking; Map<String, Object?> get modelMetadata; int get metadataVersion; bool get isCompactionSummary; CompactionKind? get compactionKind; String? get compactedFromMessageId; String? get compactedThroughMessageId; List<String> get compactedMessageIds; DateTime? get compactionCreatedAt;
/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<MessageMetadataEntity> get copyWith => _$MessageMetadataEntityCopyWithImpl<MessageMetadataEntity>(this as MessageMetadataEntity, _$identity);

  /// Serializes this MessageMetadataEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageMetadataEntity&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&const DeepCollectionEquality().equals(other.modelMetadata, modelMetadata)&&(identical(other.metadataVersion, metadataVersion) || other.metadataVersion == metadataVersion)&&(identical(other.isCompactionSummary, isCompactionSummary) || other.isCompactionSummary == isCompactionSummary)&&(identical(other.compactionKind, compactionKind) || other.compactionKind == compactionKind)&&(identical(other.compactedFromMessageId, compactedFromMessageId) || other.compactedFromMessageId == compactedFromMessageId)&&(identical(other.compactedThroughMessageId, compactedThroughMessageId) || other.compactedThroughMessageId == compactedThroughMessageId)&&const DeepCollectionEquality().equals(other.compactedMessageIds, compactedMessageIds)&&(identical(other.compactionCreatedAt, compactionCreatedAt) || other.compactionCreatedAt == compactionCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(toolCalls),promptTokens,completionTokens,totalTokens,thinking,const DeepCollectionEquality().hash(modelMetadata),metadataVersion,isCompactionSummary,compactionKind,compactedFromMessageId,compactedThroughMessageId,const DeepCollectionEquality().hash(compactedMessageIds),compactionCreatedAt);

@override
String toString() {
  return 'MessageMetadataEntity(toolCalls: $toolCalls, promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens, thinking: $thinking, modelMetadata: $modelMetadata, metadataVersion: $metadataVersion, isCompactionSummary: $isCompactionSummary, compactionKind: $compactionKind, compactedFromMessageId: $compactedFromMessageId, compactedThroughMessageId: $compactedThroughMessageId, compactedMessageIds: $compactedMessageIds, compactionCreatedAt: $compactionCreatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageMetadataEntityCopyWith<$Res>  {
  factory $MessageMetadataEntityCopyWith(MessageMetadataEntity value, $Res Function(MessageMetadataEntity) _then) = _$MessageMetadataEntityCopyWithImpl;
@useResult
$Res call({
 List<MessageToolCallEntity> toolCalls, int? promptTokens, int? completionTokens, int? totalTokens, String? thinking, Map<String, Object?> modelMetadata, int metadataVersion, bool isCompactionSummary, CompactionKind? compactionKind, String? compactedFromMessageId, String? compactedThroughMessageId, List<String> compactedMessageIds, DateTime? compactionCreatedAt
});




}
/// @nodoc
class _$MessageMetadataEntityCopyWithImpl<$Res>
    implements $MessageMetadataEntityCopyWith<$Res> {
  _$MessageMetadataEntityCopyWithImpl(this._self, this._then);

  final MessageMetadataEntity _self;
  final $Res Function(MessageMetadataEntity) _then;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolCalls = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? thinking = freezed,Object? modelMetadata = null,Object? metadataVersion = null,Object? isCompactionSummary = null,Object? compactionKind = freezed,Object? compactedFromMessageId = freezed,Object? compactedThroughMessageId = freezed,Object? compactedMessageIds = null,Object? compactionCreatedAt = freezed,}) {
  return _then(_self.copyWith(
toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<MessageToolCallEntity>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,modelMetadata: null == modelMetadata ? _self.modelMetadata : modelMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,metadataVersion: null == metadataVersion ? _self.metadataVersion : metadataVersion // ignore: cast_nullable_to_non_nullable
as int,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageId: freezed == compactedFromMessageId ? _self.compactedFromMessageId : compactedFromMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedThroughMessageId: freezed == compactedThroughMessageId ? _self.compactedThroughMessageId : compactedThroughMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedMessageIds: null == compactedMessageIds ? _self.compactedMessageIds : compactedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageMetadataEntity].
extension MessageMetadataEntityPatterns on MessageMetadataEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageMetadataEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageMetadataEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageMetadataEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageMetadataEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageMetadataEntity():
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageMetadataEntity extends MessageMetadataEntity {
  const _MessageMetadataEntity({final  List<MessageToolCallEntity> toolCalls = const <MessageToolCallEntity>[], this.promptTokens, this.completionTokens, this.totalTokens, this.thinking, final  Map<String, Object?> modelMetadata = const <String, Object?>{}, this.metadataVersion = 1, this.isCompactionSummary = false, this.compactionKind, this.compactedFromMessageId, this.compactedThroughMessageId, final  List<String> compactedMessageIds = const <String>[], this.compactionCreatedAt}): _toolCalls = toolCalls,_modelMetadata = modelMetadata,_compactedMessageIds = compactedMessageIds,super._();
  factory _MessageMetadataEntity.fromJson(Map<String, dynamic> json) => _$MessageMetadataEntityFromJson(json);

 final  List<MessageToolCallEntity> _toolCalls;
@override@JsonKey() List<MessageToolCallEntity> get toolCalls {
  if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolCalls);
}

@override final  int? promptTokens;
@override final  int? completionTokens;
@override final  int? totalTokens;
@override final  String? thinking;
 final  Map<String, Object?> _modelMetadata;
@override@JsonKey() Map<String, Object?> get modelMetadata {
  if (_modelMetadata is EqualUnmodifiableMapView) return _modelMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_modelMetadata);
}

@override@JsonKey() final  int metadataVersion;
@override@JsonKey() final  bool isCompactionSummary;
@override final  CompactionKind? compactionKind;
@override final  String? compactedFromMessageId;
@override final  String? compactedThroughMessageId;
 final  List<String> _compactedMessageIds;
@override@JsonKey() List<String> get compactedMessageIds {
  if (_compactedMessageIds is EqualUnmodifiableListView) return _compactedMessageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compactedMessageIds);
}

@override final  DateTime? compactionCreatedAt;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageMetadataEntityCopyWith<_MessageMetadataEntity> get copyWith => __$MessageMetadataEntityCopyWithImpl<_MessageMetadataEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageMetadataEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageMetadataEntity&&const DeepCollectionEquality().equals(other._toolCalls, _toolCalls)&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&const DeepCollectionEquality().equals(other._modelMetadata, _modelMetadata)&&(identical(other.metadataVersion, metadataVersion) || other.metadataVersion == metadataVersion)&&(identical(other.isCompactionSummary, isCompactionSummary) || other.isCompactionSummary == isCompactionSummary)&&(identical(other.compactionKind, compactionKind) || other.compactionKind == compactionKind)&&(identical(other.compactedFromMessageId, compactedFromMessageId) || other.compactedFromMessageId == compactedFromMessageId)&&(identical(other.compactedThroughMessageId, compactedThroughMessageId) || other.compactedThroughMessageId == compactedThroughMessageId)&&const DeepCollectionEquality().equals(other._compactedMessageIds, _compactedMessageIds)&&(identical(other.compactionCreatedAt, compactionCreatedAt) || other.compactionCreatedAt == compactionCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_toolCalls),promptTokens,completionTokens,totalTokens,thinking,const DeepCollectionEquality().hash(_modelMetadata),metadataVersion,isCompactionSummary,compactionKind,compactedFromMessageId,compactedThroughMessageId,const DeepCollectionEquality().hash(_compactedMessageIds),compactionCreatedAt);

@override
String toString() {
  return 'MessageMetadataEntity(toolCalls: $toolCalls, promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens, thinking: $thinking, modelMetadata: $modelMetadata, metadataVersion: $metadataVersion, isCompactionSummary: $isCompactionSummary, compactionKind: $compactionKind, compactedFromMessageId: $compactedFromMessageId, compactedThroughMessageId: $compactedThroughMessageId, compactedMessageIds: $compactedMessageIds, compactionCreatedAt: $compactionCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageMetadataEntityCopyWith<$Res> implements $MessageMetadataEntityCopyWith<$Res> {
  factory _$MessageMetadataEntityCopyWith(_MessageMetadataEntity value, $Res Function(_MessageMetadataEntity) _then) = __$MessageMetadataEntityCopyWithImpl;
@override @useResult
$Res call({
 List<MessageToolCallEntity> toolCalls, int? promptTokens, int? completionTokens, int? totalTokens, String? thinking, Map<String, Object?> modelMetadata, int metadataVersion, bool isCompactionSummary, CompactionKind? compactionKind, String? compactedFromMessageId, String? compactedThroughMessageId, List<String> compactedMessageIds, DateTime? compactionCreatedAt
});




}
/// @nodoc
class __$MessageMetadataEntityCopyWithImpl<$Res>
    implements _$MessageMetadataEntityCopyWith<$Res> {
  __$MessageMetadataEntityCopyWithImpl(this._self, this._then);

  final _MessageMetadataEntity _self;
  final $Res Function(_MessageMetadataEntity) _then;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolCalls = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? thinking = freezed,Object? modelMetadata = null,Object? metadataVersion = null,Object? isCompactionSummary = null,Object? compactionKind = freezed,Object? compactedFromMessageId = freezed,Object? compactedThroughMessageId = freezed,Object? compactedMessageIds = null,Object? compactionCreatedAt = freezed,}) {
  return _then(_MessageMetadataEntity(
toolCalls: null == toolCalls ? _self._toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<MessageToolCallEntity>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,modelMetadata: null == modelMetadata ? _self._modelMetadata : modelMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,metadataVersion: null == metadataVersion ? _self.metadataVersion : metadataVersion // ignore: cast_nullable_to_non_nullable
as int,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageId: freezed == compactedFromMessageId ? _self.compactedFromMessageId : compactedFromMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedThroughMessageId: freezed == compactedThroughMessageId ? _self.compactedThroughMessageId : compactedThroughMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedMessageIds: null == compactedMessageIds ? _self._compactedMessageIds : compactedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MessageEntity {

/// Unique identifier for the message
 String get id;/// ID of the conversation this message belongs to
 String get conversationId;/// Content of the message (JSON structure based on message type)
 String get content;/// Type of the message
 MessageType get messageType;/// Whether this message was sent by the user
 bool get isUser;/// Status of the message
 MessageStatus get status;/// Timestamp when the message was created
 DateTime get createdAt;/// Timestamp when the message was last updated
 DateTime get updatedAt;/// Additional metadata for the message (JSON)
 MessageMetadataEntity? get metadata;
/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageEntityCopyWith<MessageEntity> get copyWith => _$MessageEntityCopyWithImpl<MessageEntity>(this as MessageEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,conversationId,content,messageType,isUser,status,createdAt,updatedAt,metadata);

@override
String toString() {
  return 'MessageEntity(id: $id, conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $MessageEntityCopyWith<$Res>  {
  factory $MessageEntityCopyWith(MessageEntity value, $Res Function(MessageEntity) _then) = _$MessageEntityCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, DateTime updatedAt, MessageMetadataEntity? metadata
});


$MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$MessageEntityCopyWithImpl<$Res>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._self, this._then);

  final MessageEntity _self;
  final $Res Function(MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,
  ));
}
/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageEntity].
extension MessageEntityPatterns on MessageEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata)  $default,) {final _that = this;
switch (_that) {
case _MessageEntity():
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata)?  $default,) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _MessageEntity extends MessageEntity {
  const _MessageEntity({required this.id, required this.conversationId, required this.content, required this.messageType, required this.isUser, required this.status, required this.createdAt, required this.updatedAt, this.metadata}): super._();
  

/// Unique identifier for the message
@override final  String id;
/// ID of the conversation this message belongs to
@override final  String conversationId;
/// Content of the message (JSON structure based on message type)
@override final  String content;
/// Type of the message
@override final  MessageType messageType;
/// Whether this message was sent by the user
@override final  bool isUser;
/// Status of the message
@override final  MessageStatus status;
/// Timestamp when the message was created
@override final  DateTime createdAt;
/// Timestamp when the message was last updated
@override final  DateTime updatedAt;
/// Additional metadata for the message (JSON)
@override final  MessageMetadataEntity? metadata;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageEntityCopyWith<_MessageEntity> get copyWith => __$MessageEntityCopyWithImpl<_MessageEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,conversationId,content,messageType,isUser,status,createdAt,updatedAt,metadata);

@override
String toString() {
  return 'MessageEntity(id: $id, conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$MessageEntityCopyWith<$Res> implements $MessageEntityCopyWith<$Res> {
  factory _$MessageEntityCopyWith(_MessageEntity value, $Res Function(_MessageEntity) _then) = __$MessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, DateTime updatedAt, MessageMetadataEntity? metadata
});


@override $MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$MessageEntityCopyWithImpl<$Res>
    implements _$MessageEntityCopyWith<$Res> {
  __$MessageEntityCopyWithImpl(this._self, this._then);

  final _MessageEntity _self;
  final $Res Function(_MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? metadata = freezed,}) {
  return _then(_MessageEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,
  ));
}

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$MessageToCreate {

/// ID of the conversation this message belongs to
 String get conversationId;/// Content of the message (JSON structure based on message type)
 String get content;/// Type of the message
 MessageType get messageType;/// Whether this message was sent by the user
 bool get isUser; MessageStatus get status;/// Additional metadata for the message (JSON)
 String? get metadata;
/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageToCreateCopyWith<MessageToCreate> get copyWith => _$MessageToCreateCopyWithImpl<MessageToCreate>(this as MessageToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageToCreate&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,content,messageType,isUser,status,metadata);

@override
String toString() {
  return 'MessageToCreate(conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $MessageToCreateCopyWith<$Res>  {
  factory $MessageToCreateCopyWith(MessageToCreate value, $Res Function(MessageToCreate) _then) = _$MessageToCreateCopyWithImpl;
@useResult
$Res call({
 String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, String? metadata
});




}
/// @nodoc
class _$MessageToCreateCopyWithImpl<$Res>
    implements $MessageToCreateCopyWith<$Res> {
  _$MessageToCreateCopyWithImpl(this._self, this._then);

  final MessageToCreate _self;
  final $Res Function(MessageToCreate) _then;

/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageToCreate].
extension MessageToCreatePatterns on MessageToCreate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageToCreate value)  $default,){
final _that = this;
switch (_that) {
case _MessageToCreate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata)  $default,) {final _that = this;
switch (_that) {
case _MessageToCreate():
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata)?  $default,) {final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _MessageToCreate extends MessageToCreate {
  const _MessageToCreate({required this.conversationId, required this.content, required this.messageType, required this.isUser, required this.status, this.metadata}): super._();
  

/// ID of the conversation this message belongs to
@override final  String conversationId;
/// Content of the message (JSON structure based on message type)
@override final  String content;
/// Type of the message
@override final  MessageType messageType;
/// Whether this message was sent by the user
@override final  bool isUser;
@override final  MessageStatus status;
/// Additional metadata for the message (JSON)
@override final  String? metadata;

/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageToCreateCopyWith<_MessageToCreate> get copyWith => __$MessageToCreateCopyWithImpl<_MessageToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageToCreate&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,content,messageType,isUser,status,metadata);

@override
String toString() {
  return 'MessageToCreate(conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$MessageToCreateCopyWith<$Res> implements $MessageToCreateCopyWith<$Res> {
  factory _$MessageToCreateCopyWith(_MessageToCreate value, $Res Function(_MessageToCreate) _then) = __$MessageToCreateCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, String? metadata
});




}
/// @nodoc
class __$MessageToCreateCopyWithImpl<$Res>
    implements _$MessageToCreateCopyWith<$Res> {
  __$MessageToCreateCopyWithImpl(this._self, this._then);

  final _MessageToCreate _self;
  final $Res Function(_MessageToCreate) _then;

/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? metadata = freezed,}) {
  return _then(_MessageToCreate(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$MessagePatch {

/// Content of the message (JSON structure based on message type)
 String? get content;/// Additional metadata for the message (JSON)
 MessageMetadataEntity? get metadata; MessageStatus? get status;
/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagePatchCopyWith<MessagePatch> get copyWith => _$MessagePatchCopyWithImpl<MessagePatch>(this as MessagePatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagePatch&&(identical(other.content, content) || other.content == content)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,content,metadata,status);

@override
String toString() {
  return 'MessagePatch(content: $content, metadata: $metadata, status: $status)';
}


}

/// @nodoc
abstract mixin class $MessagePatchCopyWith<$Res>  {
  factory $MessagePatchCopyWith(MessagePatch value, $Res Function(MessagePatch) _then) = _$MessagePatchCopyWithImpl;
@useResult
$Res call({
 String? content, MessageMetadataEntity? metadata, MessageStatus? status
});


$MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$MessagePatchCopyWithImpl<$Res>
    implements $MessagePatchCopyWith<$Res> {
  _$MessagePatchCopyWithImpl(this._self, this._then);

  final MessagePatch _self;
  final $Res Function(MessagePatch) _then;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = freezed,Object? metadata = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus?,
  ));
}
/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessagePatch].
extension MessagePatchPatterns on MessagePatch {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessagePatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessagePatch value)  $default,){
final _that = this;
switch (_that) {
case _MessagePatch():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessagePatch value)?  $default,){
final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that.content,_that.metadata,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)  $default,) {final _that = this;
switch (_that) {
case _MessagePatch():
return $default(_that.content,_that.metadata,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that.content,_that.metadata,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _MessagePatch extends MessagePatch {
  const _MessagePatch({this.content, this.metadata, this.status}): super._();
  

/// Content of the message (JSON structure based on message type)
@override final  String? content;
/// Additional metadata for the message (JSON)
@override final  MessageMetadataEntity? metadata;
@override final  MessageStatus? status;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagePatchCopyWith<_MessagePatch> get copyWith => __$MessagePatchCopyWithImpl<_MessagePatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagePatch&&(identical(other.content, content) || other.content == content)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,content,metadata,status);

@override
String toString() {
  return 'MessagePatch(content: $content, metadata: $metadata, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MessagePatchCopyWith<$Res> implements $MessagePatchCopyWith<$Res> {
  factory _$MessagePatchCopyWith(_MessagePatch value, $Res Function(_MessagePatch) _then) = __$MessagePatchCopyWithImpl;
@override @useResult
$Res call({
 String? content, MessageMetadataEntity? metadata, MessageStatus? status
});


@override $MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$MessagePatchCopyWithImpl<$Res>
    implements _$MessagePatchCopyWith<$Res> {
  __$MessagePatchCopyWithImpl(this._self, this._then);

  final _MessagePatch _self;
  final $Res Function(_MessagePatch) _then;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = freezed,Object? metadata = freezed,Object? status = freezed,}) {
  return _then(_MessagePatch(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus?,
  ));
}

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$ToolToCall {

 ResolvedTool get tool; String get id; String get argumentsRaw;
/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolToCallCopyWith<ToolToCall> get copyWith => _$ToolToCallCopyWithImpl<ToolToCall>(this as ToolToCall, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolToCall&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.id, id) || other.id == id)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw));
}


@override
int get hashCode => Object.hash(runtimeType,tool,id,argumentsRaw);

@override
String toString() {
  return 'ToolToCall(tool: $tool, id: $id, argumentsRaw: $argumentsRaw)';
}


}

/// @nodoc
abstract mixin class $ToolToCallCopyWith<$Res>  {
  factory $ToolToCallCopyWith(ToolToCall value, $Res Function(ToolToCall) _then) = _$ToolToCallCopyWithImpl;
@useResult
$Res call({
 ResolvedTool tool, String id, String argumentsRaw
});




}
/// @nodoc
class _$ToolToCallCopyWithImpl<$Res>
    implements $ToolToCallCopyWith<$Res> {
  _$ToolToCallCopyWithImpl(this._self, this._then);

  final ToolToCall _self;
  final $Res Function(ToolToCall) _then;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? id = null,Object? argumentsRaw = null,}) {
  return _then(_self.copyWith(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ResolvedTool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolToCall].
extension ToolToCallPatterns on ToolToCall {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolToCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolToCall value)  $default,){
final _that = this;
switch (_that) {
case _ToolToCall():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolToCall value)?  $default,){
final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTool tool,  String id,  String argumentsRaw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTool tool,  String id,  String argumentsRaw)  $default,) {final _that = this;
switch (_that) {
case _ToolToCall():
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTool tool,  String id,  String argumentsRaw)?  $default,) {final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
  return null;

}
}

}

/// @nodoc


class _ToolToCall extends ToolToCall {
  const _ToolToCall({required this.tool, required this.id, required this.argumentsRaw}): super._();
  

@override final  ResolvedTool tool;
@override final  String id;
@override final  String argumentsRaw;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolToCallCopyWith<_ToolToCall> get copyWith => __$ToolToCallCopyWithImpl<_ToolToCall>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolToCall&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.id, id) || other.id == id)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw));
}


@override
int get hashCode => Object.hash(runtimeType,tool,id,argumentsRaw);

@override
String toString() {
  return 'ToolToCall(tool: $tool, id: $id, argumentsRaw: $argumentsRaw)';
}


}

/// @nodoc
abstract mixin class _$ToolToCallCopyWith<$Res> implements $ToolToCallCopyWith<$Res> {
  factory _$ToolToCallCopyWith(_ToolToCall value, $Res Function(_ToolToCall) _then) = __$ToolToCallCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTool tool, String id, String argumentsRaw
});




}
/// @nodoc
class __$ToolToCallCopyWithImpl<$Res>
    implements _$ToolToCallCopyWith<$Res> {
  __$ToolToCallCopyWithImpl(this._self, this._then);

  final _ToolToCall _self;
  final $Res Function(_ToolToCall) _then;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? id = null,Object? argumentsRaw = null,}) {
  return _then(_ToolToCall(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ResolvedTool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
