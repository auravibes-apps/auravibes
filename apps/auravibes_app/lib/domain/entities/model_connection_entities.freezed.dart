// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_connection_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelConnectionEntity {

 String get id; String get name; String get key; String get modelId; DateTime get createdAt; DateTime get updatedAt; String get workspaceId; String? get url; String? get keySuffix;
/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionEntityCopyWith<ModelConnectionEntity> get copyWith => _$ModelConnectionEntityCopyWithImpl<ModelConnectionEntity>(this as ModelConnectionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,url,keySuffix);

@override
String toString() {
  return 'ModelConnectionEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionEntityCopyWith<$Res>  {
  factory $ModelConnectionEntityCopyWith(ModelConnectionEntity value, $Res Function(ModelConnectionEntity) _then) = _$ModelConnectionEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, String? url, String? keySuffix
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? key = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceId = null,Object? url = freezed,Object? keySuffix = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  String? url,  String? keySuffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.url,_that.keySuffix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  String? url,  String? keySuffix)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionEntity():
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.url,_that.keySuffix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String key,  String modelId,  DateTime createdAt,  DateTime updatedAt,  String workspaceId,  String? url,  String? keySuffix)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionEntity() when $default != null:
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.url,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionEntity implements ModelConnectionEntity {
  const _ModelConnectionEntity({required this.id, required this.name, required this.key, required this.modelId, required this.createdAt, required this.updatedAt, required this.workspaceId, this.url, this.keySuffix});
  

@override final  String id;
@override final  String name;
@override final  String key;
@override final  String modelId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String workspaceId;
@override final  String? url;
@override final  String? keySuffix;

/// Create a copy of ModelConnectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionEntityCopyWith<_ModelConnectionEntity> get copyWith => __$ModelConnectionEntityCopyWithImpl<_ModelConnectionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,url,keySuffix);

@override
String toString() {
  return 'ModelConnectionEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionEntityCopyWith<$Res> implements $ModelConnectionEntityCopyWith<$Res> {
  factory _$ModelConnectionEntityCopyWith(_ModelConnectionEntity value, $Res Function(_ModelConnectionEntity) _then) = __$ModelConnectionEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, String? url, String? keySuffix
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? key = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceId = null,Object? url = freezed,Object? keySuffix = freezed,}) {
  return _then(_ModelConnectionEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ModelConnectionToCreate {

 String get name; String get key; String get workspaceId; String get modelId; String? get url;
/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConnectionToCreateCopyWith<ModelConnectionToCreate> get copyWith => _$ModelConnectionToCreateCopyWithImpl<ModelConnectionToCreate>(this as ModelConnectionToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConnectionToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,workspaceId,modelId,url);

@override
String toString() {
  return 'ModelConnectionToCreate(name: $name, key: $key, workspaceId: $workspaceId, modelId: $modelId, url: $url)';
}


}

/// @nodoc
abstract mixin class $ModelConnectionToCreateCopyWith<$Res>  {
  factory $ModelConnectionToCreateCopyWith(ModelConnectionToCreate value, $Res Function(ModelConnectionToCreate) _then) = _$ModelConnectionToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String key, String workspaceId, String modelId, String? url
});




}
/// @nodoc
class _$ModelConnectionToCreateCopyWithImpl<$Res>
    implements $ModelConnectionToCreateCopyWith<$Res> {
  _$ModelConnectionToCreateCopyWithImpl(this._self, this._then);

  final ModelConnectionToCreate _self;
  final $Res Function(ModelConnectionToCreate) _then;

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? key = null,Object? workspaceId = null,Object? modelId = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String key,  String workspaceId,  String modelId,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
return $default(_that.name,_that.key,_that.workspaceId,_that.modelId,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String key,  String workspaceId,  String modelId,  String? url)  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate():
return $default(_that.name,_that.key,_that.workspaceId,_that.modelId,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String key,  String workspaceId,  String modelId,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionToCreate() when $default != null:
return $default(_that.name,_that.key,_that.workspaceId,_that.modelId,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionToCreate implements ModelConnectionToCreate {
  const _ModelConnectionToCreate({required this.name, required this.key, required this.workspaceId, required this.modelId, this.url});
  

@override final  String name;
@override final  String key;
@override final  String workspaceId;
@override final  String modelId;
@override final  String? url;

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConnectionToCreateCopyWith<_ModelConnectionToCreate> get copyWith => __$ModelConnectionToCreateCopyWithImpl<_ModelConnectionToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConnectionToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,workspaceId,modelId,url);

@override
String toString() {
  return 'ModelConnectionToCreate(name: $name, key: $key, workspaceId: $workspaceId, modelId: $modelId, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ModelConnectionToCreateCopyWith<$Res> implements $ModelConnectionToCreateCopyWith<$Res> {
  factory _$ModelConnectionToCreateCopyWith(_ModelConnectionToCreate value, $Res Function(_ModelConnectionToCreate) _then) = __$ModelConnectionToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String key, String workspaceId, String modelId, String? url
});




}
/// @nodoc
class __$ModelConnectionToCreateCopyWithImpl<$Res>
    implements _$ModelConnectionToCreateCopyWith<$Res> {
  __$ModelConnectionToCreateCopyWithImpl(this._self, this._then);

  final _ModelConnectionToCreate _self;
  final $Res Function(_ModelConnectionToCreate) _then;

/// Create a copy of ModelConnectionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? key = null,Object? workspaceId = null,Object? modelId = null,Object? url = freezed,}) {
  return _then(_ModelConnectionToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ModelConnectionFilter {

 List<String>? get workspaces; List<CredentialsModelType>? get types;
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
 List<String>? workspaces, List<CredentialsModelType>? types
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
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = freezed,Object? types = freezed,}) {
  return _then(_self.copyWith(
workspaces: freezed == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>?,types: freezed == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String>? workspaces,  List<CredentialsModelType>? types)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String>? workspaces,  List<CredentialsModelType>? types)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String>? workspaces,  List<CredentialsModelType>? types)?  $default,) {final _that = this;
switch (_that) {
case _ModelConnectionFilter() when $default != null:
return $default(_that.workspaces,_that.types);case _:
  return null;

}
}

}

/// @nodoc


class _ModelConnectionFilter implements ModelConnectionFilter {
  const _ModelConnectionFilter({final  List<String>? workspaces, final  List<CredentialsModelType>? types}): _workspaces = workspaces,_types = types;
  

 final  List<String>? _workspaces;
@override List<String>? get workspaces {
  final value = _workspaces;
  if (value == null) return null;
  if (_workspaces is EqualUnmodifiableListView) return _workspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
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
 List<String>? workspaces, List<CredentialsModelType>? types
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
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = freezed,Object? types = freezed,}) {
  return _then(_ModelConnectionFilter(
workspaces: freezed == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>?,types: freezed == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as List<CredentialsModelType>?,
  ));
}


}

// dart format on
