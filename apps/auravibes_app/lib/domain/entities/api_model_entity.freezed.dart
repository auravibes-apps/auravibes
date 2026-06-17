// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_model_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiModelEntity {

/// ID of the provider that offers this model.
 String get modelProvider;/// Unique identifier for the model.
 String get id;/// Human-readable name of the model.
 String get name;/// Maximum context window size.
 int get limitContext;/// Maximum output tokens.
 int get limitOutput; List<String> get modalitiesInput; List<String> get modalitiesOuput;/// models.dev model family identifier.
 String? get family;/// Cost per 1M input tokens.
 double? get costInput;/// Cost per 1M cache read tokens.
 double? get costCacheRead;/// Cost per 1M output tokens.
 double? get costOutput;/// Whether the model is open source.
 bool? get openWeights;/// Whether the provider reports reasoning/thinking support for this model.
 bool get supportsReasoning;/// Whether this row maps to a canonical models.dev model.
 bool get isCanonical;/// Whether models.dev reports a priority backend mode for this model.
 bool get supportsPriorityMode;/// Whether models.dev reports tool-call support for this model.
 bool get supportsToolCalls;
/// Create a copy of ApiModelEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiModelEntityCopyWith<ApiModelEntity> get copyWith => _$ApiModelEntityCopyWithImpl<ApiModelEntity>(this as ApiModelEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiModelEntity&&(identical(other.modelProvider, modelProvider) || other.modelProvider == modelProvider)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.limitContext, limitContext) || other.limitContext == limitContext)&&(identical(other.limitOutput, limitOutput) || other.limitOutput == limitOutput)&&const DeepCollectionEquality().equals(other.modalitiesInput, modalitiesInput)&&const DeepCollectionEquality().equals(other.modalitiesOuput, modalitiesOuput)&&(identical(other.family, family) || other.family == family)&&(identical(other.costInput, costInput) || other.costInput == costInput)&&(identical(other.costCacheRead, costCacheRead) || other.costCacheRead == costCacheRead)&&(identical(other.costOutput, costOutput) || other.costOutput == costOutput)&&(identical(other.openWeights, openWeights) || other.openWeights == openWeights)&&(identical(other.supportsReasoning, supportsReasoning) || other.supportsReasoning == supportsReasoning)&&(identical(other.isCanonical, isCanonical) || other.isCanonical == isCanonical)&&(identical(other.supportsPriorityMode, supportsPriorityMode) || other.supportsPriorityMode == supportsPriorityMode)&&(identical(other.supportsToolCalls, supportsToolCalls) || other.supportsToolCalls == supportsToolCalls));
}


@override
int get hashCode => Object.hash(runtimeType,modelProvider,id,name,limitContext,limitOutput,const DeepCollectionEquality().hash(modalitiesInput),const DeepCollectionEquality().hash(modalitiesOuput),family,costInput,costCacheRead,costOutput,openWeights,supportsReasoning,isCanonical,supportsPriorityMode,supportsToolCalls);

@override
String toString() {
  return 'ApiModelEntity(modelProvider: $modelProvider, id: $id, name: $name, limitContext: $limitContext, limitOutput: $limitOutput, modalitiesInput: $modalitiesInput, modalitiesOuput: $modalitiesOuput, family: $family, costInput: $costInput, costCacheRead: $costCacheRead, costOutput: $costOutput, openWeights: $openWeights, supportsReasoning: $supportsReasoning, isCanonical: $isCanonical, supportsPriorityMode: $supportsPriorityMode, supportsToolCalls: $supportsToolCalls)';
}


}

/// @nodoc
abstract mixin class $ApiModelEntityCopyWith<$Res>  {
  factory $ApiModelEntityCopyWith(ApiModelEntity value, $Res Function(ApiModelEntity) _then) = _$ApiModelEntityCopyWithImpl;
@useResult
$Res call({
 String modelProvider, String id, String name, int limitContext, int limitOutput, List<String> modalitiesInput, List<String> modalitiesOuput, String? family, double? costInput, double? costCacheRead, double? costOutput, bool? openWeights, bool supportsReasoning, bool isCanonical, bool supportsPriorityMode, bool supportsToolCalls
});




}
/// @nodoc
class _$ApiModelEntityCopyWithImpl<$Res>
    implements $ApiModelEntityCopyWith<$Res> {
  _$ApiModelEntityCopyWithImpl(this._self, this._then);

  final ApiModelEntity _self;
  final $Res Function(ApiModelEntity) _then;

/// Create a copy of ApiModelEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelProvider = null,Object? id = null,Object? name = null,Object? limitContext = null,Object? limitOutput = null,Object? modalitiesInput = null,Object? modalitiesOuput = null,Object? family = freezed,Object? costInput = freezed,Object? costCacheRead = freezed,Object? costOutput = freezed,Object? openWeights = freezed,Object? supportsReasoning = null,Object? isCanonical = null,Object? supportsPriorityMode = null,Object? supportsToolCalls = null,}) {
  return _then(_self.copyWith(
modelProvider: null == modelProvider ? _self.modelProvider : modelProvider // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,limitContext: null == limitContext ? _self.limitContext : limitContext // ignore: cast_nullable_to_non_nullable
as int,limitOutput: null == limitOutput ? _self.limitOutput : limitOutput // ignore: cast_nullable_to_non_nullable
as int,modalitiesInput: null == modalitiesInput ? _self.modalitiesInput : modalitiesInput // ignore: cast_nullable_to_non_nullable
as List<String>,modalitiesOuput: null == modalitiesOuput ? _self.modalitiesOuput : modalitiesOuput // ignore: cast_nullable_to_non_nullable
as List<String>,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,costInput: freezed == costInput ? _self.costInput : costInput // ignore: cast_nullable_to_non_nullable
as double?,costCacheRead: freezed == costCacheRead ? _self.costCacheRead : costCacheRead // ignore: cast_nullable_to_non_nullable
as double?,costOutput: freezed == costOutput ? _self.costOutput : costOutput // ignore: cast_nullable_to_non_nullable
as double?,openWeights: freezed == openWeights ? _self.openWeights : openWeights // ignore: cast_nullable_to_non_nullable
as bool?,supportsReasoning: null == supportsReasoning ? _self.supportsReasoning : supportsReasoning // ignore: cast_nullable_to_non_nullable
as bool,isCanonical: null == isCanonical ? _self.isCanonical : isCanonical // ignore: cast_nullable_to_non_nullable
as bool,supportsPriorityMode: null == supportsPriorityMode ? _self.supportsPriorityMode : supportsPriorityMode // ignore: cast_nullable_to_non_nullable
as bool,supportsToolCalls: null == supportsToolCalls ? _self.supportsToolCalls : supportsToolCalls // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiModelEntity].
extension ApiModelEntityPatterns on ApiModelEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiModelEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiModelEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiModelEntity value)  $default,){
final _that = this;
switch (_that) {
case _ApiModelEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiModelEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ApiModelEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelProvider,  String id,  String name,  int limitContext,  int limitOutput,  List<String> modalitiesInput,  List<String> modalitiesOuput,  String? family,  double? costInput,  double? costCacheRead,  double? costOutput,  bool? openWeights,  bool supportsReasoning,  bool isCanonical,  bool supportsPriorityMode,  bool supportsToolCalls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiModelEntity() when $default != null:
return $default(_that.modelProvider,_that.id,_that.name,_that.limitContext,_that.limitOutput,_that.modalitiesInput,_that.modalitiesOuput,_that.family,_that.costInput,_that.costCacheRead,_that.costOutput,_that.openWeights,_that.supportsReasoning,_that.isCanonical,_that.supportsPriorityMode,_that.supportsToolCalls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelProvider,  String id,  String name,  int limitContext,  int limitOutput,  List<String> modalitiesInput,  List<String> modalitiesOuput,  String? family,  double? costInput,  double? costCacheRead,  double? costOutput,  bool? openWeights,  bool supportsReasoning,  bool isCanonical,  bool supportsPriorityMode,  bool supportsToolCalls)  $default,) {final _that = this;
switch (_that) {
case _ApiModelEntity():
return $default(_that.modelProvider,_that.id,_that.name,_that.limitContext,_that.limitOutput,_that.modalitiesInput,_that.modalitiesOuput,_that.family,_that.costInput,_that.costCacheRead,_that.costOutput,_that.openWeights,_that.supportsReasoning,_that.isCanonical,_that.supportsPriorityMode,_that.supportsToolCalls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelProvider,  String id,  String name,  int limitContext,  int limitOutput,  List<String> modalitiesInput,  List<String> modalitiesOuput,  String? family,  double? costInput,  double? costCacheRead,  double? costOutput,  bool? openWeights,  bool supportsReasoning,  bool isCanonical,  bool supportsPriorityMode,  bool supportsToolCalls)?  $default,) {final _that = this;
switch (_that) {
case _ApiModelEntity() when $default != null:
return $default(_that.modelProvider,_that.id,_that.name,_that.limitContext,_that.limitOutput,_that.modalitiesInput,_that.modalitiesOuput,_that.family,_that.costInput,_that.costCacheRead,_that.costOutput,_that.openWeights,_that.supportsReasoning,_that.isCanonical,_that.supportsPriorityMode,_that.supportsToolCalls);case _:
  return null;

}
}

}

/// @nodoc


class _ApiModelEntity extends ApiModelEntity {
  const _ApiModelEntity({required this.modelProvider, required this.id, required this.name, required this.limitContext, required this.limitOutput, required final  List<String> modalitiesInput, required final  List<String> modalitiesOuput, this.family, this.costInput, this.costCacheRead, this.costOutput, this.openWeights, this.supportsReasoning = false, this.isCanonical = true, this.supportsPriorityMode = false, this.supportsToolCalls = false}): _modalitiesInput = modalitiesInput,_modalitiesOuput = modalitiesOuput,super._();
  

/// ID of the provider that offers this model.
@override final  String modelProvider;
/// Unique identifier for the model.
@override final  String id;
/// Human-readable name of the model.
@override final  String name;
/// Maximum context window size.
@override final  int limitContext;
/// Maximum output tokens.
@override final  int limitOutput;
 final  List<String> _modalitiesInput;
@override List<String> get modalitiesInput {
  if (_modalitiesInput is EqualUnmodifiableListView) return _modalitiesInput;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modalitiesInput);
}

 final  List<String> _modalitiesOuput;
@override List<String> get modalitiesOuput {
  if (_modalitiesOuput is EqualUnmodifiableListView) return _modalitiesOuput;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modalitiesOuput);
}

/// models.dev model family identifier.
@override final  String? family;
/// Cost per 1M input tokens.
@override final  double? costInput;
/// Cost per 1M cache read tokens.
@override final  double? costCacheRead;
/// Cost per 1M output tokens.
@override final  double? costOutput;
/// Whether the model is open source.
@override final  bool? openWeights;
/// Whether the provider reports reasoning/thinking support for this model.
@override@JsonKey() final  bool supportsReasoning;
/// Whether this row maps to a canonical models.dev model.
@override@JsonKey() final  bool isCanonical;
/// Whether models.dev reports a priority backend mode for this model.
@override@JsonKey() final  bool supportsPriorityMode;
/// Whether models.dev reports tool-call support for this model.
@override@JsonKey() final  bool supportsToolCalls;

/// Create a copy of ApiModelEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiModelEntityCopyWith<_ApiModelEntity> get copyWith => __$ApiModelEntityCopyWithImpl<_ApiModelEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiModelEntity&&(identical(other.modelProvider, modelProvider) || other.modelProvider == modelProvider)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.limitContext, limitContext) || other.limitContext == limitContext)&&(identical(other.limitOutput, limitOutput) || other.limitOutput == limitOutput)&&const DeepCollectionEquality().equals(other._modalitiesInput, _modalitiesInput)&&const DeepCollectionEquality().equals(other._modalitiesOuput, _modalitiesOuput)&&(identical(other.family, family) || other.family == family)&&(identical(other.costInput, costInput) || other.costInput == costInput)&&(identical(other.costCacheRead, costCacheRead) || other.costCacheRead == costCacheRead)&&(identical(other.costOutput, costOutput) || other.costOutput == costOutput)&&(identical(other.openWeights, openWeights) || other.openWeights == openWeights)&&(identical(other.supportsReasoning, supportsReasoning) || other.supportsReasoning == supportsReasoning)&&(identical(other.isCanonical, isCanonical) || other.isCanonical == isCanonical)&&(identical(other.supportsPriorityMode, supportsPriorityMode) || other.supportsPriorityMode == supportsPriorityMode)&&(identical(other.supportsToolCalls, supportsToolCalls) || other.supportsToolCalls == supportsToolCalls));
}


@override
int get hashCode => Object.hash(runtimeType,modelProvider,id,name,limitContext,limitOutput,const DeepCollectionEquality().hash(_modalitiesInput),const DeepCollectionEquality().hash(_modalitiesOuput),family,costInput,costCacheRead,costOutput,openWeights,supportsReasoning,isCanonical,supportsPriorityMode,supportsToolCalls);

@override
String toString() {
  return 'ApiModelEntity(modelProvider: $modelProvider, id: $id, name: $name, limitContext: $limitContext, limitOutput: $limitOutput, modalitiesInput: $modalitiesInput, modalitiesOuput: $modalitiesOuput, family: $family, costInput: $costInput, costCacheRead: $costCacheRead, costOutput: $costOutput, openWeights: $openWeights, supportsReasoning: $supportsReasoning, isCanonical: $isCanonical, supportsPriorityMode: $supportsPriorityMode, supportsToolCalls: $supportsToolCalls)';
}


}

/// @nodoc
abstract mixin class _$ApiModelEntityCopyWith<$Res> implements $ApiModelEntityCopyWith<$Res> {
  factory _$ApiModelEntityCopyWith(_ApiModelEntity value, $Res Function(_ApiModelEntity) _then) = __$ApiModelEntityCopyWithImpl;
@override @useResult
$Res call({
 String modelProvider, String id, String name, int limitContext, int limitOutput, List<String> modalitiesInput, List<String> modalitiesOuput, String? family, double? costInput, double? costCacheRead, double? costOutput, bool? openWeights, bool supportsReasoning, bool isCanonical, bool supportsPriorityMode, bool supportsToolCalls
});




}
/// @nodoc
class __$ApiModelEntityCopyWithImpl<$Res>
    implements _$ApiModelEntityCopyWith<$Res> {
  __$ApiModelEntityCopyWithImpl(this._self, this._then);

  final _ApiModelEntity _self;
  final $Res Function(_ApiModelEntity) _then;

/// Create a copy of ApiModelEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelProvider = null,Object? id = null,Object? name = null,Object? limitContext = null,Object? limitOutput = null,Object? modalitiesInput = null,Object? modalitiesOuput = null,Object? family = freezed,Object? costInput = freezed,Object? costCacheRead = freezed,Object? costOutput = freezed,Object? openWeights = freezed,Object? supportsReasoning = null,Object? isCanonical = null,Object? supportsPriorityMode = null,Object? supportsToolCalls = null,}) {
  return _then(_ApiModelEntity(
modelProvider: null == modelProvider ? _self.modelProvider : modelProvider // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,limitContext: null == limitContext ? _self.limitContext : limitContext // ignore: cast_nullable_to_non_nullable
as int,limitOutput: null == limitOutput ? _self.limitOutput : limitOutput // ignore: cast_nullable_to_non_nullable
as int,modalitiesInput: null == modalitiesInput ? _self._modalitiesInput : modalitiesInput // ignore: cast_nullable_to_non_nullable
as List<String>,modalitiesOuput: null == modalitiesOuput ? _self._modalitiesOuput : modalitiesOuput // ignore: cast_nullable_to_non_nullable
as List<String>,family: freezed == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as String?,costInput: freezed == costInput ? _self.costInput : costInput // ignore: cast_nullable_to_non_nullable
as double?,costCacheRead: freezed == costCacheRead ? _self.costCacheRead : costCacheRead // ignore: cast_nullable_to_non_nullable
as double?,costOutput: freezed == costOutput ? _self.costOutput : costOutput // ignore: cast_nullable_to_non_nullable
as double?,openWeights: freezed == openWeights ? _self.openWeights : openWeights // ignore: cast_nullable_to_non_nullable
as bool?,supportsReasoning: null == supportsReasoning ? _self.supportsReasoning : supportsReasoning // ignore: cast_nullable_to_non_nullable
as bool,isCanonical: null == isCanonical ? _self.isCanonical : isCanonical // ignore: cast_nullable_to_non_nullable
as bool,supportsPriorityMode: null == supportsPriorityMode ? _self.supportsPriorityMode : supportsPriorityMode // ignore: cast_nullable_to_non_nullable
as bool,supportsToolCalls: null == supportsToolCalls ? _self.supportsToolCalls : supportsToolCalls // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
