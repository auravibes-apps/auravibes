// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_model_selection_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceModelSelectionEntity {

 String get id; String get modelId; DateTime get createdAt; DateTime get updatedAt; String get modelConnectionId; String? get modelName; bool get supportsReasoning; bool get supportsToolCalls;
/// Create a copy of WorkspaceModelSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionEntityCopyWith<WorkspaceModelSelectionEntity> get copyWith => _$WorkspaceModelSelectionEntityCopyWithImpl<WorkspaceModelSelectionEntity>(this as WorkspaceModelSelectionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceModelSelectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.modelConnectionId, modelConnectionId) || other.modelConnectionId == modelConnectionId)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.supportsReasoning, supportsReasoning) || other.supportsReasoning == supportsReasoning)&&(identical(other.supportsToolCalls, supportsToolCalls) || other.supportsToolCalls == supportsToolCalls));
}


@override
int get hashCode => Object.hash(runtimeType,id,modelId,createdAt,updatedAt,modelConnectionId,modelName,supportsReasoning,supportsToolCalls);

@override
String toString() {
  return 'WorkspaceModelSelectionEntity(id: $id, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, modelConnectionId: $modelConnectionId, modelName: $modelName, supportsReasoning: $supportsReasoning, supportsToolCalls: $supportsToolCalls)';
}


}

/// @nodoc
abstract mixin class $WorkspaceModelSelectionEntityCopyWith<$Res>  {
  factory $WorkspaceModelSelectionEntityCopyWith(WorkspaceModelSelectionEntity value, $Res Function(WorkspaceModelSelectionEntity) _then) = _$WorkspaceModelSelectionEntityCopyWithImpl;
@useResult
$Res call({
 String id, String modelId, DateTime createdAt, DateTime updatedAt, String modelConnectionId, String? modelName, bool supportsReasoning, bool supportsToolCalls
});




}
/// @nodoc
class _$WorkspaceModelSelectionEntityCopyWithImpl<$Res>
    implements $WorkspaceModelSelectionEntityCopyWith<$Res> {
  _$WorkspaceModelSelectionEntityCopyWithImpl(this._self, this._then);

  final WorkspaceModelSelectionEntity _self;
  final $Res Function(WorkspaceModelSelectionEntity) _then;

/// Create a copy of WorkspaceModelSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? modelConnectionId = null,Object? modelName = freezed,Object? supportsReasoning = null,Object? supportsToolCalls = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelConnectionId: null == modelConnectionId ? _self.modelConnectionId : modelConnectionId // ignore: cast_nullable_to_non_nullable
as String,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,supportsReasoning: null == supportsReasoning ? _self.supportsReasoning : supportsReasoning // ignore: cast_nullable_to_non_nullable
as bool,supportsToolCalls: null == supportsToolCalls ? _self.supportsToolCalls : supportsToolCalls // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceModelSelectionEntity].
extension WorkspaceModelSelectionEntityPatterns on WorkspaceModelSelectionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceModelSelectionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String modelConnectionId,  String? modelName,  bool supportsReasoning,  bool supportsToolCalls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity() when $default != null:
return $default(_that.id,_that.modelId,_that.createdAt,_that.updatedAt,_that.modelConnectionId,_that.modelName,_that.supportsReasoning,_that.supportsToolCalls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String modelConnectionId,  String? modelName,  bool supportsReasoning,  bool supportsToolCalls)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity():
return $default(_that.id,_that.modelId,_that.createdAt,_that.updatedAt,_that.modelConnectionId,_that.modelName,_that.supportsReasoning,_that.supportsToolCalls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String modelConnectionId,  String? modelName,  bool supportsReasoning,  bool supportsToolCalls)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionEntity() when $default != null:
return $default(_that.id,_that.modelId,_that.createdAt,_that.updatedAt,_that.modelConnectionId,_that.modelName,_that.supportsReasoning,_that.supportsToolCalls);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceModelSelectionEntity implements WorkspaceModelSelectionEntity {
  const _WorkspaceModelSelectionEntity({required this.id, required this.modelId, required this.createdAt, required this.updatedAt, required this.modelConnectionId, this.modelName, this.supportsReasoning = false, this.supportsToolCalls = true});
  

@override final  String id;
@override final  String modelId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String modelConnectionId;
@override final  String? modelName;
@override@JsonKey() final  bool supportsReasoning;
@override@JsonKey() final  bool supportsToolCalls;

/// Create a copy of WorkspaceModelSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceModelSelectionEntityCopyWith<_WorkspaceModelSelectionEntity> get copyWith => __$WorkspaceModelSelectionEntityCopyWithImpl<_WorkspaceModelSelectionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceModelSelectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.modelConnectionId, modelConnectionId) || other.modelConnectionId == modelConnectionId)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.supportsReasoning, supportsReasoning) || other.supportsReasoning == supportsReasoning)&&(identical(other.supportsToolCalls, supportsToolCalls) || other.supportsToolCalls == supportsToolCalls));
}


@override
int get hashCode => Object.hash(runtimeType,id,modelId,createdAt,updatedAt,modelConnectionId,modelName,supportsReasoning,supportsToolCalls);

@override
String toString() {
  return 'WorkspaceModelSelectionEntity(id: $id, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, modelConnectionId: $modelConnectionId, modelName: $modelName, supportsReasoning: $supportsReasoning, supportsToolCalls: $supportsToolCalls)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceModelSelectionEntityCopyWith<$Res> implements $WorkspaceModelSelectionEntityCopyWith<$Res> {
  factory _$WorkspaceModelSelectionEntityCopyWith(_WorkspaceModelSelectionEntity value, $Res Function(_WorkspaceModelSelectionEntity) _then) = __$WorkspaceModelSelectionEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String modelId, DateTime createdAt, DateTime updatedAt, String modelConnectionId, String? modelName, bool supportsReasoning, bool supportsToolCalls
});




}
/// @nodoc
class __$WorkspaceModelSelectionEntityCopyWithImpl<$Res>
    implements _$WorkspaceModelSelectionEntityCopyWith<$Res> {
  __$WorkspaceModelSelectionEntityCopyWithImpl(this._self, this._then);

  final _WorkspaceModelSelectionEntity _self;
  final $Res Function(_WorkspaceModelSelectionEntity) _then;

/// Create a copy of WorkspaceModelSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? modelConnectionId = null,Object? modelName = freezed,Object? supportsReasoning = null,Object? supportsToolCalls = null,}) {
  return _then(_WorkspaceModelSelectionEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelConnectionId: null == modelConnectionId ? _self.modelConnectionId : modelConnectionId // ignore: cast_nullable_to_non_nullable
as String,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,supportsReasoning: null == supportsReasoning ? _self.supportsReasoning : supportsReasoning // ignore: cast_nullable_to_non_nullable
as bool,supportsToolCalls: null == supportsToolCalls ? _self.supportsToolCalls : supportsToolCalls // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$WorkspaceModelSelectionWithConnectionEntity {

 WorkspaceModelSelectionEntity get workspaceModelSelection; ModelConnectionEntity get modelConnection; ApiModelProviderEntity get modelsProvider;
/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionWithConnectionEntityCopyWith<WorkspaceModelSelectionWithConnectionEntity> get copyWith => _$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl<WorkspaceModelSelectionWithConnectionEntity>(this as WorkspaceModelSelectionWithConnectionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceModelSelectionWithConnectionEntity&&(identical(other.workspaceModelSelection, workspaceModelSelection) || other.workspaceModelSelection == workspaceModelSelection)&&(identical(other.modelConnection, modelConnection) || other.modelConnection == modelConnection)&&(identical(other.modelsProvider, modelsProvider) || other.modelsProvider == modelsProvider));
}


@override
int get hashCode => Object.hash(runtimeType,workspaceModelSelection,modelConnection,modelsProvider);

@override
String toString() {
  return 'WorkspaceModelSelectionWithConnectionEntity(workspaceModelSelection: $workspaceModelSelection, modelConnection: $modelConnection, modelsProvider: $modelsProvider)';
}


}

/// @nodoc
abstract mixin class $WorkspaceModelSelectionWithConnectionEntityCopyWith<$Res>  {
  factory $WorkspaceModelSelectionWithConnectionEntityCopyWith(WorkspaceModelSelectionWithConnectionEntity value, $Res Function(WorkspaceModelSelectionWithConnectionEntity) _then) = _$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl;
@useResult
$Res call({
 WorkspaceModelSelectionEntity workspaceModelSelection, ModelConnectionEntity modelConnection, ApiModelProviderEntity modelsProvider
});


$WorkspaceModelSelectionEntityCopyWith<$Res> get workspaceModelSelection;$ModelConnectionEntityCopyWith<$Res> get modelConnection;$ApiModelProviderEntityCopyWith<$Res> get modelsProvider;

}
/// @nodoc
class _$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl<$Res>
    implements $WorkspaceModelSelectionWithConnectionEntityCopyWith<$Res> {
  _$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl(this._self, this._then);

  final WorkspaceModelSelectionWithConnectionEntity _self;
  final $Res Function(WorkspaceModelSelectionWithConnectionEntity) _then;

/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaceModelSelection = null,Object? modelConnection = null,Object? modelsProvider = null,}) {
  return _then(_self.copyWith(
workspaceModelSelection: null == workspaceModelSelection ? _self.workspaceModelSelection : workspaceModelSelection // ignore: cast_nullable_to_non_nullable
as WorkspaceModelSelectionEntity,modelConnection: null == modelConnection ? _self.modelConnection : modelConnection // ignore: cast_nullable_to_non_nullable
as ModelConnectionEntity,modelsProvider: null == modelsProvider ? _self.modelsProvider : modelsProvider // ignore: cast_nullable_to_non_nullable
as ApiModelProviderEntity,
  ));
}
/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionEntityCopyWith<$Res> get workspaceModelSelection {
  
  return $WorkspaceModelSelectionEntityCopyWith<$Res>(_self.workspaceModelSelection, (value) {
    return _then(_self.copyWith(workspaceModelSelection: value));
  });
}/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelConnectionEntityCopyWith<$Res> get modelConnection {
  
  return $ModelConnectionEntityCopyWith<$Res>(_self.modelConnection, (value) {
    return _then(_self.copyWith(modelConnection: value));
  });
}/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiModelProviderEntityCopyWith<$Res> get modelsProvider {
  
  return $ApiModelProviderEntityCopyWith<$Res>(_self.modelsProvider, (value) {
    return _then(_self.copyWith(modelsProvider: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceModelSelectionWithConnectionEntity].
extension WorkspaceModelSelectionWithConnectionEntityPatterns on WorkspaceModelSelectionWithConnectionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionWithConnectionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionWithConnectionEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceModelSelectionWithConnectionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceModelSelectionEntity workspaceModelSelection,  ModelConnectionEntity modelConnection,  ApiModelProviderEntity modelsProvider)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity() when $default != null:
return $default(_that.workspaceModelSelection,_that.modelConnection,_that.modelsProvider);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceModelSelectionEntity workspaceModelSelection,  ModelConnectionEntity modelConnection,  ApiModelProviderEntity modelsProvider)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity():
return $default(_that.workspaceModelSelection,_that.modelConnection,_that.modelsProvider);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceModelSelectionEntity workspaceModelSelection,  ModelConnectionEntity modelConnection,  ApiModelProviderEntity modelsProvider)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionWithConnectionEntity() when $default != null:
return $default(_that.workspaceModelSelection,_that.modelConnection,_that.modelsProvider);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceModelSelectionWithConnectionEntity implements WorkspaceModelSelectionWithConnectionEntity {
  const _WorkspaceModelSelectionWithConnectionEntity({required this.workspaceModelSelection, required this.modelConnection, required this.modelsProvider});
  

@override final  WorkspaceModelSelectionEntity workspaceModelSelection;
@override final  ModelConnectionEntity modelConnection;
@override final  ApiModelProviderEntity modelsProvider;

/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceModelSelectionWithConnectionEntityCopyWith<_WorkspaceModelSelectionWithConnectionEntity> get copyWith => __$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl<_WorkspaceModelSelectionWithConnectionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceModelSelectionWithConnectionEntity&&(identical(other.workspaceModelSelection, workspaceModelSelection) || other.workspaceModelSelection == workspaceModelSelection)&&(identical(other.modelConnection, modelConnection) || other.modelConnection == modelConnection)&&(identical(other.modelsProvider, modelsProvider) || other.modelsProvider == modelsProvider));
}


@override
int get hashCode => Object.hash(runtimeType,workspaceModelSelection,modelConnection,modelsProvider);

@override
String toString() {
  return 'WorkspaceModelSelectionWithConnectionEntity(workspaceModelSelection: $workspaceModelSelection, modelConnection: $modelConnection, modelsProvider: $modelsProvider)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceModelSelectionWithConnectionEntityCopyWith<$Res> implements $WorkspaceModelSelectionWithConnectionEntityCopyWith<$Res> {
  factory _$WorkspaceModelSelectionWithConnectionEntityCopyWith(_WorkspaceModelSelectionWithConnectionEntity value, $Res Function(_WorkspaceModelSelectionWithConnectionEntity) _then) = __$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceModelSelectionEntity workspaceModelSelection, ModelConnectionEntity modelConnection, ApiModelProviderEntity modelsProvider
});


@override $WorkspaceModelSelectionEntityCopyWith<$Res> get workspaceModelSelection;@override $ModelConnectionEntityCopyWith<$Res> get modelConnection;@override $ApiModelProviderEntityCopyWith<$Res> get modelsProvider;

}
/// @nodoc
class __$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl<$Res>
    implements _$WorkspaceModelSelectionWithConnectionEntityCopyWith<$Res> {
  __$WorkspaceModelSelectionWithConnectionEntityCopyWithImpl(this._self, this._then);

  final _WorkspaceModelSelectionWithConnectionEntity _self;
  final $Res Function(_WorkspaceModelSelectionWithConnectionEntity) _then;

/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaceModelSelection = null,Object? modelConnection = null,Object? modelsProvider = null,}) {
  return _then(_WorkspaceModelSelectionWithConnectionEntity(
workspaceModelSelection: null == workspaceModelSelection ? _self.workspaceModelSelection : workspaceModelSelection // ignore: cast_nullable_to_non_nullable
as WorkspaceModelSelectionEntity,modelConnection: null == modelConnection ? _self.modelConnection : modelConnection // ignore: cast_nullable_to_non_nullable
as ModelConnectionEntity,modelsProvider: null == modelsProvider ? _self.modelsProvider : modelsProvider // ignore: cast_nullable_to_non_nullable
as ApiModelProviderEntity,
  ));
}

/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionEntityCopyWith<$Res> get workspaceModelSelection {
  
  return $WorkspaceModelSelectionEntityCopyWith<$Res>(_self.workspaceModelSelection, (value) {
    return _then(_self.copyWith(workspaceModelSelection: value));
  });
}/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelConnectionEntityCopyWith<$Res> get modelConnection {
  
  return $ModelConnectionEntityCopyWith<$Res>(_self.modelConnection, (value) {
    return _then(_self.copyWith(modelConnection: value));
  });
}/// Create a copy of WorkspaceModelSelectionWithConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiModelProviderEntityCopyWith<$Res> get modelsProvider {
  
  return $ApiModelProviderEntityCopyWith<$Res>(_self.modelsProvider, (value) {
    return _then(_self.copyWith(modelsProvider: value));
  });
}
}

/// @nodoc
mixin _$WorkspaceModelSelectionFilter {

 List<String> get workspaces;
/// Create a copy of WorkspaceModelSelectionFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionFilterCopyWith<WorkspaceModelSelectionFilter> get copyWith => _$WorkspaceModelSelectionFilterCopyWithImpl<WorkspaceModelSelectionFilter>(this as WorkspaceModelSelectionFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceModelSelectionFilter&&const DeepCollectionEquality().equals(other.workspaces, workspaces));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workspaces));

@override
String toString() {
  return 'WorkspaceModelSelectionFilter(workspaces: $workspaces)';
}


}

/// @nodoc
abstract mixin class $WorkspaceModelSelectionFilterCopyWith<$Res>  {
  factory $WorkspaceModelSelectionFilterCopyWith(WorkspaceModelSelectionFilter value, $Res Function(WorkspaceModelSelectionFilter) _then) = _$WorkspaceModelSelectionFilterCopyWithImpl;
@useResult
$Res call({
 List<String> workspaces
});




}
/// @nodoc
class _$WorkspaceModelSelectionFilterCopyWithImpl<$Res>
    implements $WorkspaceModelSelectionFilterCopyWith<$Res> {
  _$WorkspaceModelSelectionFilterCopyWithImpl(this._self, this._then);

  final WorkspaceModelSelectionFilter _self;
  final $Res Function(WorkspaceModelSelectionFilter) _then;

/// Create a copy of WorkspaceModelSelectionFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = null,}) {
  return _then(_self.copyWith(
workspaces: null == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceModelSelectionFilter].
extension WorkspaceModelSelectionFilterPatterns on WorkspaceModelSelectionFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionFilter value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceModelSelectionFilter value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> workspaces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter() when $default != null:
return $default(_that.workspaces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> workspaces)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter():
return $default(_that.workspaces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> workspaces)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionFilter() when $default != null:
return $default(_that.workspaces);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceModelSelectionFilter implements WorkspaceModelSelectionFilter {
  const _WorkspaceModelSelectionFilter({final  List<String> workspaces = const []}): _workspaces = workspaces;
  

 final  List<String> _workspaces;
@override@JsonKey() List<String> get workspaces {
  if (_workspaces is EqualUnmodifiableListView) return _workspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workspaces);
}


/// Create a copy of WorkspaceModelSelectionFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceModelSelectionFilterCopyWith<_WorkspaceModelSelectionFilter> get copyWith => __$WorkspaceModelSelectionFilterCopyWithImpl<_WorkspaceModelSelectionFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceModelSelectionFilter&&const DeepCollectionEquality().equals(other._workspaces, _workspaces));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workspaces));

@override
String toString() {
  return 'WorkspaceModelSelectionFilter(workspaces: $workspaces)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceModelSelectionFilterCopyWith<$Res> implements $WorkspaceModelSelectionFilterCopyWith<$Res> {
  factory _$WorkspaceModelSelectionFilterCopyWith(_WorkspaceModelSelectionFilter value, $Res Function(_WorkspaceModelSelectionFilter) _then) = __$WorkspaceModelSelectionFilterCopyWithImpl;
@override @useResult
$Res call({
 List<String> workspaces
});




}
/// @nodoc
class __$WorkspaceModelSelectionFilterCopyWithImpl<$Res>
    implements _$WorkspaceModelSelectionFilterCopyWith<$Res> {
  __$WorkspaceModelSelectionFilterCopyWithImpl(this._self, this._then);

  final _WorkspaceModelSelectionFilter _self;
  final $Res Function(_WorkspaceModelSelectionFilter) _then;

/// Create a copy of WorkspaceModelSelectionFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = null,}) {
  return _then(_WorkspaceModelSelectionFilter(
workspaces: null == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$WorkspaceModelSelectionToCreate {

 String get modelId; String get modelConnectionId;
/// Create a copy of WorkspaceModelSelectionToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceModelSelectionToCreateCopyWith<WorkspaceModelSelectionToCreate> get copyWith => _$WorkspaceModelSelectionToCreateCopyWithImpl<WorkspaceModelSelectionToCreate>(this as WorkspaceModelSelectionToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceModelSelectionToCreate&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelConnectionId, modelConnectionId) || other.modelConnectionId == modelConnectionId));
}


@override
int get hashCode => Object.hash(runtimeType,modelId,modelConnectionId);

@override
String toString() {
  return 'WorkspaceModelSelectionToCreate(modelId: $modelId, modelConnectionId: $modelConnectionId)';
}


}

/// @nodoc
abstract mixin class $WorkspaceModelSelectionToCreateCopyWith<$Res>  {
  factory $WorkspaceModelSelectionToCreateCopyWith(WorkspaceModelSelectionToCreate value, $Res Function(WorkspaceModelSelectionToCreate) _then) = _$WorkspaceModelSelectionToCreateCopyWithImpl;
@useResult
$Res call({
 String modelId, String modelConnectionId
});




}
/// @nodoc
class _$WorkspaceModelSelectionToCreateCopyWithImpl<$Res>
    implements $WorkspaceModelSelectionToCreateCopyWith<$Res> {
  _$WorkspaceModelSelectionToCreateCopyWithImpl(this._self, this._then);

  final WorkspaceModelSelectionToCreate _self;
  final $Res Function(WorkspaceModelSelectionToCreate) _then;

/// Create a copy of WorkspaceModelSelectionToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelId = null,Object? modelConnectionId = null,}) {
  return _then(_self.copyWith(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelConnectionId: null == modelConnectionId ? _self.modelConnectionId : modelConnectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceModelSelectionToCreate].
extension WorkspaceModelSelectionToCreatePatterns on WorkspaceModelSelectionToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceModelSelectionToCreate value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceModelSelectionToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelId,  String modelConnectionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate() when $default != null:
return $default(_that.modelId,_that.modelConnectionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelId,  String modelConnectionId)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate():
return $default(_that.modelId,_that.modelConnectionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelId,  String modelConnectionId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceModelSelectionToCreate() when $default != null:
return $default(_that.modelId,_that.modelConnectionId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceModelSelectionToCreate implements WorkspaceModelSelectionToCreate {
  const _WorkspaceModelSelectionToCreate({required this.modelId, required this.modelConnectionId});
  

@override final  String modelId;
@override final  String modelConnectionId;

/// Create a copy of WorkspaceModelSelectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceModelSelectionToCreateCopyWith<_WorkspaceModelSelectionToCreate> get copyWith => __$WorkspaceModelSelectionToCreateCopyWithImpl<_WorkspaceModelSelectionToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceModelSelectionToCreate&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelConnectionId, modelConnectionId) || other.modelConnectionId == modelConnectionId));
}


@override
int get hashCode => Object.hash(runtimeType,modelId,modelConnectionId);

@override
String toString() {
  return 'WorkspaceModelSelectionToCreate(modelId: $modelId, modelConnectionId: $modelConnectionId)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceModelSelectionToCreateCopyWith<$Res> implements $WorkspaceModelSelectionToCreateCopyWith<$Res> {
  factory _$WorkspaceModelSelectionToCreateCopyWith(_WorkspaceModelSelectionToCreate value, $Res Function(_WorkspaceModelSelectionToCreate) _then) = __$WorkspaceModelSelectionToCreateCopyWithImpl;
@override @useResult
$Res call({
 String modelId, String modelConnectionId
});




}
/// @nodoc
class __$WorkspaceModelSelectionToCreateCopyWithImpl<$Res>
    implements _$WorkspaceModelSelectionToCreateCopyWith<$Res> {
  __$WorkspaceModelSelectionToCreateCopyWithImpl(this._self, this._then);

  final _WorkspaceModelSelectionToCreate _self;
  final $Res Function(_WorkspaceModelSelectionToCreate) _then;

/// Create a copy of WorkspaceModelSelectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelId = null,Object? modelConnectionId = null,}) {
  return _then(_WorkspaceModelSelectionToCreate(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelConnectionId: null == modelConnectionId ? _self.modelConnectionId : modelConnectionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
