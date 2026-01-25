// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credentials_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CredentialsEntity {

 String get id; String get name; String get key; String get modelId; DateTime get createdAt; DateTime get updatedAt; String get workspaceId; String? get url; String? get keySuffix;
/// Create a copy of CredentialsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialsEntityCopyWith<CredentialsEntity> get copyWith => _$CredentialsEntityCopyWithImpl<CredentialsEntity>(this as CredentialsEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialsEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,url,keySuffix);

@override
String toString() {
  return 'CredentialsEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $CredentialsEntityCopyWith<$Res>  {
  factory $CredentialsEntityCopyWith(CredentialsEntity value, $Res Function(CredentialsEntity) _then) = _$CredentialsEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, String? url, String? keySuffix
});




}
/// @nodoc
class _$CredentialsEntityCopyWithImpl<$Res>
    implements $CredentialsEntityCopyWith<$Res> {
  _$CredentialsEntityCopyWithImpl(this._self, this._then);

  final CredentialsEntity _self;
  final $Res Function(CredentialsEntity) _then;

/// Create a copy of CredentialsEntity
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


/// Adds pattern-matching-related methods to [CredentialsEntity].
extension CredentialsEntityPatterns on CredentialsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialsEntity value)  $default,){
final _that = this;
switch (_that) {
case _CredentialsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialsEntity() when $default != null:
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
case _CredentialsEntity() when $default != null:
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
case _CredentialsEntity():
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
case _CredentialsEntity() when $default != null:
return $default(_that.id,_that.name,_that.key,_that.modelId,_that.createdAt,_that.updatedAt,_that.workspaceId,_that.url,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _CredentialsEntity implements CredentialsEntity {
  const _CredentialsEntity({required this.id, required this.name, required this.key, required this.modelId, required this.createdAt, required this.updatedAt, required this.workspaceId, this.url, this.keySuffix});
  

@override final  String id;
@override final  String name;
@override final  String key;
@override final  String modelId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String workspaceId;
@override final  String? url;
@override final  String? keySuffix;

/// Create a copy of CredentialsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialsEntityCopyWith<_CredentialsEntity> get copyWith => __$CredentialsEntityCopyWithImpl<_CredentialsEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialsEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.url, url) || other.url == url)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,key,modelId,createdAt,updatedAt,workspaceId,url,keySuffix);

@override
String toString() {
  return 'CredentialsEntity(id: $id, name: $name, key: $key, modelId: $modelId, createdAt: $createdAt, updatedAt: $updatedAt, workspaceId: $workspaceId, url: $url, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$CredentialsEntityCopyWith<$Res> implements $CredentialsEntityCopyWith<$Res> {
  factory _$CredentialsEntityCopyWith(_CredentialsEntity value, $Res Function(_CredentialsEntity) _then) = __$CredentialsEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String key, String modelId, DateTime createdAt, DateTime updatedAt, String workspaceId, String? url, String? keySuffix
});




}
/// @nodoc
class __$CredentialsEntityCopyWithImpl<$Res>
    implements _$CredentialsEntityCopyWith<$Res> {
  __$CredentialsEntityCopyWithImpl(this._self, this._then);

  final _CredentialsEntity _self;
  final $Res Function(_CredentialsEntity) _then;

/// Create a copy of CredentialsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? key = null,Object? modelId = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceId = null,Object? url = freezed,Object? keySuffix = freezed,}) {
  return _then(_CredentialsEntity(
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
mixin _$CredentialsToCreate {

 String get name; String get key; String get workspaceId; String get modelId; String? get url;
/// Create a copy of CredentialsToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialsToCreateCopyWith<CredentialsToCreate> get copyWith => _$CredentialsToCreateCopyWithImpl<CredentialsToCreate>(this as CredentialsToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialsToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,workspaceId,modelId,url);

@override
String toString() {
  return 'CredentialsToCreate(name: $name, key: $key, workspaceId: $workspaceId, modelId: $modelId, url: $url)';
}


}

/// @nodoc
abstract mixin class $CredentialsToCreateCopyWith<$Res>  {
  factory $CredentialsToCreateCopyWith(CredentialsToCreate value, $Res Function(CredentialsToCreate) _then) = _$CredentialsToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String key, String workspaceId, String modelId, String? url
});




}
/// @nodoc
class _$CredentialsToCreateCopyWithImpl<$Res>
    implements $CredentialsToCreateCopyWith<$Res> {
  _$CredentialsToCreateCopyWithImpl(this._self, this._then);

  final CredentialsToCreate _self;
  final $Res Function(CredentialsToCreate) _then;

/// Create a copy of CredentialsToCreate
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


/// Adds pattern-matching-related methods to [CredentialsToCreate].
extension CredentialsToCreatePatterns on CredentialsToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialsToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialsToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialsToCreate value)  $default,){
final _that = this;
switch (_that) {
case _CredentialsToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialsToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialsToCreate() when $default != null:
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
case _CredentialsToCreate() when $default != null:
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
case _CredentialsToCreate():
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
case _CredentialsToCreate() when $default != null:
return $default(_that.name,_that.key,_that.workspaceId,_that.modelId,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _CredentialsToCreate implements CredentialsToCreate {
  const _CredentialsToCreate({required this.name, required this.key, required this.workspaceId, required this.modelId, this.url});
  

@override final  String name;
@override final  String key;
@override final  String workspaceId;
@override final  String modelId;
@override final  String? url;

/// Create a copy of CredentialsToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialsToCreateCopyWith<_CredentialsToCreate> get copyWith => __$CredentialsToCreateCopyWithImpl<_CredentialsToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialsToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.key, key) || other.key == key)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,key,workspaceId,modelId,url);

@override
String toString() {
  return 'CredentialsToCreate(name: $name, key: $key, workspaceId: $workspaceId, modelId: $modelId, url: $url)';
}


}

/// @nodoc
abstract mixin class _$CredentialsToCreateCopyWith<$Res> implements $CredentialsToCreateCopyWith<$Res> {
  factory _$CredentialsToCreateCopyWith(_CredentialsToCreate value, $Res Function(_CredentialsToCreate) _then) = __$CredentialsToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String key, String workspaceId, String modelId, String? url
});




}
/// @nodoc
class __$CredentialsToCreateCopyWithImpl<$Res>
    implements _$CredentialsToCreateCopyWith<$Res> {
  __$CredentialsToCreateCopyWithImpl(this._self, this._then);

  final _CredentialsToCreate _self;
  final $Res Function(_CredentialsToCreate) _then;

/// Create a copy of CredentialsToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? key = null,Object? workspaceId = null,Object? modelId = null,Object? url = freezed,}) {
  return _then(_CredentialsToCreate(
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
mixin _$ModelProviderFilter {

 List<String>? get workspaces; List<CredentialsModelType>? get types;
/// Create a copy of ModelProviderFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProviderFilterCopyWith<ModelProviderFilter> get copyWith => _$ModelProviderFilterCopyWithImpl<ModelProviderFilter>(this as ModelProviderFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProviderFilter&&const DeepCollectionEquality().equals(other.workspaces, workspaces)&&const DeepCollectionEquality().equals(other.types, types));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workspaces),const DeepCollectionEquality().hash(types));

@override
String toString() {
  return 'ModelProviderFilter(workspaces: $workspaces, types: $types)';
}


}

/// @nodoc
abstract mixin class $ModelProviderFilterCopyWith<$Res>  {
  factory $ModelProviderFilterCopyWith(ModelProviderFilter value, $Res Function(ModelProviderFilter) _then) = _$ModelProviderFilterCopyWithImpl;
@useResult
$Res call({
 List<String>? workspaces, List<CredentialsModelType>? types
});




}
/// @nodoc
class _$ModelProviderFilterCopyWithImpl<$Res>
    implements $ModelProviderFilterCopyWith<$Res> {
  _$ModelProviderFilterCopyWithImpl(this._self, this._then);

  final ModelProviderFilter _self;
  final $Res Function(ModelProviderFilter) _then;

/// Create a copy of ModelProviderFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workspaces = freezed,Object? types = freezed,}) {
  return _then(_self.copyWith(
workspaces: freezed == workspaces ? _self.workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>?,types: freezed == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as List<CredentialsModelType>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelProviderFilter].
extension ModelProviderFilterPatterns on ModelProviderFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelProviderFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelProviderFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelProviderFilter value)  $default,){
final _that = this;
switch (_that) {
case _ModelProviderFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelProviderFilter value)?  $default,){
final _that = this;
switch (_that) {
case _ModelProviderFilter() when $default != null:
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
case _ModelProviderFilter() when $default != null:
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
case _ModelProviderFilter():
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
case _ModelProviderFilter() when $default != null:
return $default(_that.workspaces,_that.types);case _:
  return null;

}
}

}

/// @nodoc


class _ModelProviderFilter implements ModelProviderFilter {
  const _ModelProviderFilter({final  List<String>? workspaces, final  List<CredentialsModelType>? types}): _workspaces = workspaces,_types = types;
  

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


/// Create a copy of ModelProviderFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelProviderFilterCopyWith<_ModelProviderFilter> get copyWith => __$ModelProviderFilterCopyWithImpl<_ModelProviderFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelProviderFilter&&const DeepCollectionEquality().equals(other._workspaces, _workspaces)&&const DeepCollectionEquality().equals(other._types, _types));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workspaces),const DeepCollectionEquality().hash(_types));

@override
String toString() {
  return 'ModelProviderFilter(workspaces: $workspaces, types: $types)';
}


}

/// @nodoc
abstract mixin class _$ModelProviderFilterCopyWith<$Res> implements $ModelProviderFilterCopyWith<$Res> {
  factory _$ModelProviderFilterCopyWith(_ModelProviderFilter value, $Res Function(_ModelProviderFilter) _then) = __$ModelProviderFilterCopyWithImpl;
@override @useResult
$Res call({
 List<String>? workspaces, List<CredentialsModelType>? types
});




}
/// @nodoc
class __$ModelProviderFilterCopyWithImpl<$Res>
    implements _$ModelProviderFilterCopyWith<$Res> {
  __$ModelProviderFilterCopyWithImpl(this._self, this._then);

  final _ModelProviderFilter _self;
  final $Res Function(_ModelProviderFilter) _then;

/// Create a copy of ModelProviderFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workspaces = freezed,Object? types = freezed,}) {
  return _then(_ModelProviderFilter(
workspaces: freezed == workspaces ? _self._workspaces : workspaces // ignore: cast_nullable_to_non_nullable
as List<String>?,types: freezed == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as List<CredentialsModelType>?,
  ));
}


}

// dart format on
