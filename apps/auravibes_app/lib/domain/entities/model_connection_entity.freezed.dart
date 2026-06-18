// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_connection_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelConnectionEntity {

 String get id; String get name; String get key; String get modelId; DateTime get createdAt; DateTime get updatedAt; String get workspaceId; ModelProviderAuthMode get authMode; String? get url; String? get keySuffix; ServiceConnectionMetadata? get oauthMetadata;
/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionEntityCopyWith<ModelConnectionEntity> get copyWith => _$ModelConnectionEntityCopyWithImpl<ModelConnectionEntity>(this as ModelConnectionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix)&&(identical(other.oauthMetadata, oauthMetadata) || other.oauthMetadata == oauthMetadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,authMode,url,keySuffix,oauthMetadata);

@override
String toString() {
  return 'ModelConnectionEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, authMode: $authMode, url: $url, keySuffix: $keySuffix, oauthMetadata: $oauthMetadata)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionEntityCopyWith<$Res>  {
  factory $ModelConnectionEntityCopyWith(ModelConnectionEntity value, $Res Function(ModelConnectionEntity) _then) = _$ModelConnectionEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, ModelProviderAuthMode authMode, String? url, String? keySuffix, ServiceConnectionMetadata? oauthMetadata
});




}
/// @nodoc
class _$ModelConnectionEntityCopyWithImpl<$Res>
    implements $ModelConnectionEntityCopyWith<$Res> {
  _$ModelConnectionEntityCopyWithImpl(this._self, this._then);

  final ModelConnectionEntity _self;
  final $Res Function(ModelConnectionEntity) _then;

/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? key = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceId = null,Object? authMode = null,Object? url = freezed,Object? keySuffix = freezed,Object? oauthMetadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,oauthMetadata: freezed == oauthMetadata ? _self.oauthMetadata : oauthMetadata // ignore: cast_nullable_to_non_nullable
as ServiceConnectionMetadata?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelConnectionEntity].
extension ModelConnectionEntityPatterns on ModelConnectionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConnectionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConnectionEntity value)  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConnectionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix,  ServiceConnectionMetadata? oauthMetadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.authMode,_that.url,_that.keySuffix,_that.oauthMetadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix,  ServiceConnectionMetadata? oauthMetadata)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionEntity():
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.authMode,_that.url,_that.keySuffix,_that.oauthMetadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix,  ServiceConnectionMetadata? oauthMetadata)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.authMode,_that.url,_that.keySuffix,_that.oauthMetadata);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionEntity implements ModelConnectionEntity {
  const _ModelConnectionEntity({required this.id, required this.name, required this.key, required this.modelId, required this.createdAt, required this.updatedAt, required this.workspaceId, this.authMode = ModelProviderAuthMode.apiKey, this.url, this.keySuffix, this.oauthMetadata});
  

@override final  String id;
@override final  String name;
@override final  String key;
@override final  String modelId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String workspaceId;
@override@JsonKey() final  ModelProviderAuthMode authMode;
@override final  String? url;
@override final  String? keySuffix;
@override final  ServiceConnectionMetadata? oauthMetadata;

/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionEntityCopyWith<_ModelConnectionEntity> get copyWith => __$ModelConnectionEntityCopyWithImpl<_ModelConnectionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix)&&(identical(other.oauthMetadata, oauthMetadata) || other.oauthMetadata == oauthMetadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,authMode,url,keySuffix,oauthMetadata);

@override
String toString() {
  return 'ModelConnectionEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, authMode: $authMode, url: $url, keySuffix: $keySuffix, oauthMetadata: $oauthMetadata)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionEntityCopyWith<$Res> implements $ModelConnectionEntityCopyWith<$Res> {
  factory _$ModelConnectionEntityCopyWith(_ModelConnectionEntity value, $Res Function(_ModelConnectionEntity) _then) = __$ModelConnectionEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, ModelProviderAuthMode authMode, String? url, String? keySuffix, ServiceConnectionMetadata? oauthMetadata
});




}
/// @nodoc
class __$ModelConnectionEntityCopyWithImpl<$Res>
    implements _$ModelConnectionEntityCopyWith<$Res> {
  __$ModelConnectionEntityCopyWithImpl(this._self, this._then);

  final _ModelConnectionEntity _self;
  final $Res Function(_ModelConnectionEntity) _then;

/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? key = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceId = null,Object? authMode = null,Object? url = freezed,Object? keySuffix = freezed,Object? oauthMetadata = freezed,}) {
  return _then(_ModelConnectionEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,oauthMetadata: freezed == oauthMetadata ? _self.oauthMetadata : oauthMetadata // ignore: cast_nullable_to_non_nullable
as ServiceConnectionMetadata?,
  ));
}


}

/// @nodoc
mixin _$ModelConnectionToCreate {

 String get name; String get workspaceId; String get modelId; ModelProviderAuthMode get authMode; String get key; String? get url; OAuthTokenEntity? get oauthToken; ServiceConnectionMetadata? get oauthMetadata; List<String> get modelIds;
/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionToCreateCopyWith<ModelConnectionToCreate> get copyWith => _$ModelConnectionToCreateCopyWithImpl<ModelConnectionToCreate>(this as ModelConnectionToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url)&&(identical(other.oauthToken, oauthToken) || other.oauthToken == oauthToken)&&(identical(other.oauthMetadata, oauthMetadata) || other.oauthMetadata == oauthMetadata)&&const DeepCollectionEquality().equals(other.modelIds, modelIds));
}


@override
int get hashCode => Object.hash(runtimeType,name,workspaceId,modelId,authMode,key,url,oauthToken,oauthMetadata,const DeepCollectionEquality().hash(modelIds));

@override
String toString() {
  return 'ModelConnectionToCreate(name: $name, workspaceId: $workspaceId, modelId: $modelId, authMode: $authMode, key: $key, url: $url, oauthToken: $oauthToken, oauthMetadata: $oauthMetadata, modelIds: $modelIds)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionToCreateCopyWith<$Res>  {
  factory $ModelConnectionToCreateCopyWith(ModelConnectionToCreate value, $Res Function(ModelConnectionToCreate) _then) = _$ModelConnectionToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String workspaceId, String modelId, ModelProviderAuthMode authMode, String key, String? url, OAuthTokenEntity? oauthToken, ServiceConnectionMetadata? oauthMetadata, List<String> modelIds
});


$OAuthTokenEntityCopyWith<$Res>? get oauthToken;

}
/// @nodoc
class _$ModelConnectionToCreateCopyWithImpl<$Res>
    implements $ModelConnectionToCreateCopyWith<$Res> {
  _$ModelConnectionToCreateCopyWithImpl(this._self, this._then);

  final ModelConnectionToCreate _self;
  final $Res Function(ModelConnectionToCreate) _then;

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? workspaceId = null,Object? modelId = null,Object? authMode = null,Object? key = null,Object? url = freezed,Object? oauthToken = freezed,Object? oauthMetadata = freezed,Object? modelIds = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,oauthToken: freezed == oauthToken ? _self.oauthToken : oauthToken // ignore: cast_nullable_to_non_nullable
as OAuthTokenEntity?,oauthMetadata: freezed == oauthMetadata ? _self.oauthMetadata : oauthMetadata // ignore: cast_nullable_to_non_nullable
as ServiceConnectionMetadata?,modelIds: null == modelIds ? _self.modelIds : modelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthTokenEntityCopyWith<$Res>? get oauthToken {
    if (_self.oauthToken == null) {
    return null;
  }

  return $OAuthTokenEntityCopyWith<$Res>(_self.oauthToken!, (value) {
    return _then(_self.copyWith(oauthToken: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModelConnectionToCreate].
extension ModelConnectionToCreatePatterns on ModelConnectionToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConnectionToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConnectionToCreate value)  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConnectionToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String workspaceId,  String modelId,  ModelProviderAuthMode authMode,  String key,  String? url,  OAuthTokenEntity? oauthToken,  ServiceConnectionMetadata? oauthMetadata,  List<String> modelIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
return $default(_that.name,_that.workspaceId,_that.modelId,_that.authMode,_that.key,_that.url,_that.oauthToken,_that.oauthMetadata,_that.modelIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String workspaceId,  String modelId,  ModelProviderAuthMode authMode,  String key,  String? url,  OAuthTokenEntity? oauthToken,  ServiceConnectionMetadata? oauthMetadata,  List<String> modelIds)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate():
return $default(_that.name,_that.workspaceId,_that.modelId,_that.authMode,_that.key,_that.url,_that.oauthToken,_that.oauthMetadata,_that.modelIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String workspaceId,  String modelId,  ModelProviderAuthMode authMode,  String key,  String? url,  OAuthTokenEntity? oauthToken,  ServiceConnectionMetadata? oauthMetadata,  List<String> modelIds)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
return $default(_that.name,_that.workspaceId,_that.modelId,_that.authMode,_that.key,_that.url,_that.oauthToken,_that.oauthMetadata,_that.modelIds);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionToCreate implements ModelConnectionToCreate {
  const _ModelConnectionToCreate({required this.name, required this.workspaceId, required this.modelId, this.authMode = ModelProviderAuthMode.apiKey, this.key = '', this.url, this.oauthToken, this.oauthMetadata, final  List<String> modelIds = const []}): assert(authMode == ModelProviderAuthMode.oauth2 || key != "", 'API-key connections require a non-empty key.'),_modelIds = modelIds;
  

@override final  String name;
@override final  String workspaceId;
@override final  String modelId;
@override@JsonKey() final  ModelProviderAuthMode authMode;
@override@JsonKey() final  String key;
@override final  String? url;
@override final  OAuthTokenEntity? oauthToken;
@override final  ServiceConnectionMetadata? oauthMetadata;
 final  List<String> _modelIds;
@override@JsonKey() List<String> get modelIds {
  if (_modelIds is EqualUnmodifiableListView) return _modelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modelIds);
}


/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionToCreateCopyWith<_ModelConnectionToCreate> get copyWith => __$ModelConnectionToCreateCopyWithImpl<_ModelConnectionToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url)&&(identical(other.oauthToken, oauthToken) || other.oauthToken == oauthToken)&&(identical(other.oauthMetadata, oauthMetadata) || other.oauthMetadata == oauthMetadata)&&const DeepCollectionEquality().equals(other._modelIds, _modelIds));
}


@override
int get hashCode => Object.hash(runtimeType,name,workspaceId,modelId,authMode,key,url,oauthToken,oauthMetadata,const DeepCollectionEquality().hash(_modelIds));

@override
String toString() {
  return 'ModelConnectionToCreate(name: $name, workspaceId: $workspaceId, modelId: $modelId, authMode: $authMode, key: $key, url: $url, oauthToken: $oauthToken, oauthMetadata: $oauthMetadata, modelIds: $modelIds)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionToCreateCopyWith<$Res> implements $ModelConnectionToCreateCopyWith<$Res> {
  factory _$ModelConnectionToCreateCopyWith(_ModelConnectionToCreate value, $Res Function(_ModelConnectionToCreate) _then) = __$ModelConnectionToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String workspaceId, String modelId, ModelProviderAuthMode authMode, String key, String? url, OAuthTokenEntity? oauthToken, ServiceConnectionMetadata? oauthMetadata, List<String> modelIds
});


@override $OAuthTokenEntityCopyWith<$Res>? get oauthToken;

}
/// @nodoc
class __$ModelConnectionToCreateCopyWithImpl<$Res>
    implements _$ModelConnectionToCreateCopyWith<$Res> {
  __$ModelConnectionToCreateCopyWithImpl(this._self, this._then);

  final _ModelConnectionToCreate _self;
  final $Res Function(_ModelConnectionToCreate) _then;

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? workspaceId = null,Object? modelId = null,Object? authMode = null,Object? key = null,Object? url = freezed,Object? oauthToken = freezed,Object? oauthMetadata = freezed,Object? modelIds = null,}) {
  return _then(_ModelConnectionToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,oauthToken: freezed == oauthToken ? _self.oauthToken : oauthToken // ignore: cast_nullable_to_non_nullable
as OAuthTokenEntity?,oauthMetadata: freezed == oauthMetadata ? _self.oauthMetadata : oauthMetadata // ignore: cast_nullable_to_non_nullable
as ServiceConnectionMetadata?,modelIds: null == modelIds ? _self._modelIds : modelIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthTokenEntityCopyWith<$Res>? get oauthToken {
    if (_self.oauthToken == null) {
    return null;
  }

  return $OAuthTokenEntityCopyWith<$Res>(_self.oauthToken!, (value) {
    return _then(_self.copyWith(oauthToken: value));
  });
}
}

/// @nodoc
mixin _$ModelConnectionForEdit {

 String get id; String get name; String get modelId; String get workspaceId; bool get hasKey; ModelProviderAuthMode get authMode; String? get url; String? get keySuffix;
/// Create a copy of ModelConnectionForEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionForEditCopyWith<ModelConnectionForEdit> get copyWith => _$ModelConnectionForEditCopyWithImpl<ModelConnectionForEdit>(this as ModelConnectionForEdit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionForEdit&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.hasKey, hasKey) || other.hasKey == hasKey)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,modelId,workspaceId,hasKey,authMode,url,keySuffix);

@override
String toString() {
  return 'ModelConnectionForEdit(id: $id, name: $name, modelId: $modelId, workspaceId: $workspaceId, hasKey: $hasKey, authMode: $authMode, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionForEditCopyWith<$Res>  {
  factory $ModelConnectionForEditCopyWith(ModelConnectionForEdit value, $Res Function(ModelConnectionForEdit) _then) = _$ModelConnectionForEditCopyWithImpl;
@useResult
$Res call({
 String id, String name, String modelId, String workspaceId, bool hasKey, ModelProviderAuthMode authMode, String? url, String? keySuffix
});




}
/// @nodoc
class _$ModelConnectionForEditCopyWithImpl<$Res>
    implements $ModelConnectionForEditCopyWith<$Res> {
  _$ModelConnectionForEditCopyWithImpl(this._self, this._then);

  final ModelConnectionForEdit _self;
  final $Res Function(ModelConnectionForEdit) _then;

/// Create a copy of ModelConnectionForEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? modelId = null,Object? workspaceId = null,Object? hasKey = null,Object? authMode = null,Object? url = freezed,Object? keySuffix = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,hasKey: null == hasKey ? _self.hasKey : hasKey // ignore: cast_nullable_to_non_nullable
as bool,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelConnectionForEdit].
extension ModelConnectionForEditPatterns on ModelConnectionForEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConnectionForEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConnectionForEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConnectionForEdit value)  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionForEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConnectionForEdit value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionForEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String modelId,  String workspaceId,  bool hasKey,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionForEdit() when $default != null:
return $default(_that.id,_that.name,_that.modelId,_that.workspaceId,_that.hasKey,_that.authMode,_that.url,_that.keySuffix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String modelId,  String workspaceId,  bool hasKey,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionForEdit():
return $default(_that.id,_that.name,_that.modelId,_that.workspaceId,_that.hasKey,_that.authMode,_that.url,_that.keySuffix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String modelId,  String workspaceId,  bool hasKey,  ModelProviderAuthMode authMode,  String? url,  String? keySuffix)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionForEdit() when $default != null:
return $default(_that.id,_that.name,_that.modelId,_that.workspaceId,_that.hasKey,_that.authMode,_that.url,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionForEdit implements ModelConnectionForEdit {
  const _ModelConnectionForEdit({required this.id, required this.name, required this.modelId, required this.workspaceId, required this.hasKey, this.authMode = ModelProviderAuthMode.apiKey, this.url, this.keySuffix});
  

@override final  String id;
@override final  String name;
@override final  String modelId;
@override final  String workspaceId;
@override final  bool hasKey;
@override@JsonKey() final  ModelProviderAuthMode authMode;
@override final  String? url;
@override final  String? keySuffix;

/// Create a copy of ModelConnectionForEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionForEditCopyWith<_ModelConnectionForEdit> get copyWith => __$ModelConnectionForEditCopyWithImpl<_ModelConnectionForEdit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionForEdit&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.hasKey, hasKey) || other.hasKey == hasKey)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,modelId,workspaceId,hasKey,authMode,url,keySuffix);

@override
String toString() {
  return 'ModelConnectionForEdit(id: $id, name: $name, modelId: $modelId, workspaceId: $workspaceId, hasKey: $hasKey, authMode: $authMode, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionForEditCopyWith<$Res> implements $ModelConnectionForEditCopyWith<$Res> {
  factory _$ModelConnectionForEditCopyWith(_ModelConnectionForEdit value, $Res Function(_ModelConnectionForEdit) _then) = __$ModelConnectionForEditCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String modelId, String workspaceId, bool hasKey, ModelProviderAuthMode authMode, String? url, String? keySuffix
});




}
/// @nodoc
class __$ModelConnectionForEditCopyWithImpl<$Res>
    implements _$ModelConnectionForEditCopyWith<$Res> {
  __$ModelConnectionForEditCopyWithImpl(this._self, this._then);

  final _ModelConnectionForEdit _self;
  final $Res Function(_ModelConnectionForEdit) _then;

/// Create a copy of ModelConnectionForEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? modelId = null,Object? workspaceId = null,Object? hasKey = null,Object? authMode = null,Object? url = freezed,Object? keySuffix = freezed,}) {
  return _then(_ModelConnectionForEdit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,hasKey: null == hasKey ? _self.hasKey : hasKey // ignore: cast_nullable_to_non_nullable
as bool,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as ModelProviderAuthMode,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ModelConnectionToUpdate {

 String? get name; String? get key; String? get url;
/// Create a copy of ModelConnectionToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionToUpdateCopyWith<ModelConnectionToUpdate> get copyWith => _$ModelConnectionToUpdateCopyWithImpl<ModelConnectionToUpdate>(this as ModelConnectionToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionToUpdate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,url);

@override
String toString() {
  return 'ModelConnectionToUpdate(name: $name, key: $key, url: $url)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionToUpdateCopyWith<$Res>  {
  factory $ModelConnectionToUpdateCopyWith(ModelConnectionToUpdate value, $Res Function(ModelConnectionToUpdate) _then) = _$ModelConnectionToUpdateCopyWithImpl;
@useResult
$Res call({
 String? name, String? key, String? url
});




}
/// @nodoc
class _$ModelConnectionToUpdateCopyWithImpl<$Res>
    implements $ModelConnectionToUpdateCopyWith<$Res> {
  _$ModelConnectionToUpdateCopyWithImpl(this._self, this._then);

  final ModelConnectionToUpdate _self;
  final $Res Function(ModelConnectionToUpdate) _then;

/// Create a copy of ModelConnectionToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? key = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelConnectionToUpdate].
extension ModelConnectionToUpdatePatterns on ModelConnectionToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConnectionToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConnectionToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConnectionToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConnectionToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? key,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionToUpdate() when $default != null:
return $default(_that.name,_that.key,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? key,  String? url)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToUpdate():
return $default(_that.name,_that.key,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? key,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToUpdate() when $default != null:
return $default(_that.name,_that.key,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionToUpdate implements ModelConnectionToUpdate {
  const _ModelConnectionToUpdate({this.name, this.key, this.url});
  

@override final  String? name;
@override final  String? key;
@override final  String? url;

/// Create a copy of ModelConnectionToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionToUpdateCopyWith<_ModelConnectionToUpdate> get copyWith => __$ModelConnectionToUpdateCopyWithImpl<_ModelConnectionToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionToUpdate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,url);

@override
String toString() {
  return 'ModelConnectionToUpdate(name: $name, key: $key, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionToUpdateCopyWith<$Res> implements $ModelConnectionToUpdateCopyWith<$Res> {
  factory _$ModelConnectionToUpdateCopyWith(_ModelConnectionToUpdate value, $Res Function(_ModelConnectionToUpdate) _then) = __$ModelConnectionToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? key, String? url
});




}
/// @nodoc
class __$ModelConnectionToUpdateCopyWithImpl<$Res>
    implements _$ModelConnectionToUpdateCopyWith<$Res> {
  __$ModelConnectionToUpdateCopyWithImpl(this._self, this._then);

  final _ModelConnectionToUpdate _self;
  final $Res Function(_ModelConnectionToUpdate) _then;

/// Create a copy of ModelConnectionToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? key = freezed,Object? url = freezed,}) {
  return _then(_ModelConnectionToUpdate(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ModelConnectionFilter {

 List<String> get workspaces; List<CredentialsModelType>? get types;
/// Create a copy of ModelConnectionFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionFilterCopyWith<ModelConnectionFilter> get copyWith => _$ModelConnectionFilterCopyWithImpl<ModelConnectionFilter>(this as ModelConnectionFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionFilter&&const DeepCollectionEquality().equals(other.workspaces, workspaces)&&const DeepCollectionEquality().equals(other.types, types));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workspaces),const DeepCollectionEquality().hash(types));

@override
String toString() {
  return 'ModelConnectionFilter(workspaces: $workspaces, types: $types)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionFilterCopyWith<$Res>  {
  factory $ModelConnectionFilterCopyWith(ModelConnectionFilter value, $Res Function(ModelConnectionFilter) _then) = _$ModelConnectionFilterCopyWithImpl;
@useResult
$Res call({
 List<String> workspaces, List<CredentialsModelType>? types
});




}
/// @nodoc
class _$ModelConnectionFilterCopyWithImpl<$Res>
    implements $ModelConnectionFilterCopyWith<$Res> {
  _$ModelConnectionFilterCopyWithImpl(this._self, this._then);

  final ModelConnectionFilter _self;
  final $Res Function(ModelConnectionFilter) _then;

/// Create a copy of ModelConnectionFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = null,Object? types = freezed,}) {
  return _then(_self.copyWith(
workspaces: null == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>,types: freezed == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as List<CredentialsModelType>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelConnectionFilter].
extension ModelConnectionFilterPatterns on ModelConnectionFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConnectionFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConnectionFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConnectionFilter value)  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConnectionFilter value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConnectionFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> workspaces,  List<CredentialsModelType>? types)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionFilter() when $default != null:
return $default(_that.workspaces,_that.types);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> workspaces,  List<CredentialsModelType>? types)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionFilter():
return $default(_that.workspaces,_that.types);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> workspaces,  List<CredentialsModelType>? types)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionFilter() when $default != null:
return $default(_that.workspaces,_that.types);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionFilter implements ModelConnectionFilter {
  const _ModelConnectionFilter({final  List<String> workspaces = const [], final  List<CredentialsModelType>? types}): _workspaces = workspaces,_types = types;
  

 final  List<String> _workspaces;
@override@JsonKey() List<String> get workspaces {
  if (_workspaces is EqualUnmodifiableListView) return _workspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workspaces);
}

 final  List<CredentialsModelType>? _types;
@override List<CredentialsModelType>? get types {
  final value = _types;
  if (value == null) return null;
  if (_types is EqualUnmodifiableListView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ModelConnectionFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionFilterCopyWith<_ModelConnectionFilter> get copyWith => __$ModelConnectionFilterCopyWithImpl<_ModelConnectionFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionFilter&&const DeepCollectionEquality().equals(other._workspaces, _workspaces)&&const DeepCollectionEquality().equals(other._types, _types));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workspaces),const DeepCollectionEquality().hash(_types));

@override
String toString() {
  return 'ModelConnectionFilter(workspaces: $workspaces, types: $types)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionFilterCopyWith<$Res> implements $ModelConnectionFilterCopyWith<$Res> {
  factory _$ModelConnectionFilterCopyWith(_ModelConnectionFilter value, $Res Function(_ModelConnectionFilter) _then) = __$ModelConnectionFilterCopyWithImpl;
@override @useResult
$Res call({
 List<String> workspaces, List<CredentialsModelType>? types
});




}
/// @nodoc
class __$ModelConnectionFilterCopyWithImpl<$Res>
    implements _$ModelConnectionFilterCopyWith<$Res> {
  __$ModelConnectionFilterCopyWithImpl(this._self, this._then);

  final _ModelConnectionFilter _self;
  final $Res Function(_ModelConnectionFilter) _then;

/// Create a copy of ModelConnectionFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = null,Object? types = freezed,}) {
  return _then(_ModelConnectionFilter(
workspaces: null == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>,types: freezed == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as List<CredentialsModelType>?,
  ));
}


}

// dart format on
