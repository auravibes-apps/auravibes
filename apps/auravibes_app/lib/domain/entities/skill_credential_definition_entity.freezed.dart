// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_credential_definition_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillCredentialDefinitionEntity {

 String get id; String get workspaceId; String get title; String get slug; String get attributesJson; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SkillCredentialDefinitionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialDefinitionEntityCopyWith<SkillCredentialDefinitionEntity> get copyWith => _$SkillCredentialDefinitionEntityCopyWithImpl<SkillCredentialDefinitionEntity>(this as SkillCredentialDefinitionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialDefinitionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,slug,attributesJson,createdAt,updatedAt);

@override
String toString() {
  return 'SkillCredentialDefinitionEntity(id: $id, workspaceId: $workspaceId, title: $title, slug: $slug, attributesJson: $attributesJson, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialDefinitionEntityCopyWith<$Res>  {
  factory $SkillCredentialDefinitionEntityCopyWith(SkillCredentialDefinitionEntity value, $Res Function(SkillCredentialDefinitionEntity) _then) = _$SkillCredentialDefinitionEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String title, String slug, String attributesJson, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SkillCredentialDefinitionEntityCopyWithImpl<$Res>
    implements $SkillCredentialDefinitionEntityCopyWith<$Res> {
  _$SkillCredentialDefinitionEntityCopyWithImpl(this._self, this._then);

  final SkillCredentialDefinitionEntity _self;
  final $Res Function(SkillCredentialDefinitionEntity) _then;

/// Create a copy of SkillCredentialDefinitionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? slug = null,Object? attributesJson = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,attributesJson: null == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialDefinitionEntity].
extension SkillCredentialDefinitionEntityPatterns on SkillCredentialDefinitionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialDefinitionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String slug,  String attributesJson,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.slug,_that.attributesJson,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String title,  String slug,  String attributesJson,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity():
return $default(_that.id,_that.workspaceId,_that.title,_that.slug,_that.attributesJson,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String title,  String slug,  String attributesJson,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.title,_that.slug,_that.attributesJson,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialDefinitionEntity extends SkillCredentialDefinitionEntity {
  const _SkillCredentialDefinitionEntity({required this.id, required this.workspaceId, required this.title, required this.slug, required this.attributesJson, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  String workspaceId;
@override final  String title;
@override final  String slug;
@override final  String attributesJson;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SkillCredentialDefinitionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialDefinitionEntityCopyWith<_SkillCredentialDefinitionEntity> get copyWith => __$SkillCredentialDefinitionEntityCopyWithImpl<_SkillCredentialDefinitionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialDefinitionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,title,slug,attributesJson,createdAt,updatedAt);

@override
String toString() {
  return 'SkillCredentialDefinitionEntity(id: $id, workspaceId: $workspaceId, title: $title, slug: $slug, attributesJson: $attributesJson, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialDefinitionEntityCopyWith<$Res> implements $SkillCredentialDefinitionEntityCopyWith<$Res> {
  factory _$SkillCredentialDefinitionEntityCopyWith(_SkillCredentialDefinitionEntity value, $Res Function(_SkillCredentialDefinitionEntity) _then) = __$SkillCredentialDefinitionEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String title, String slug, String attributesJson, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SkillCredentialDefinitionEntityCopyWithImpl<$Res>
    implements _$SkillCredentialDefinitionEntityCopyWith<$Res> {
  __$SkillCredentialDefinitionEntityCopyWithImpl(this._self, this._then);

  final _SkillCredentialDefinitionEntity _self;
  final $Res Function(_SkillCredentialDefinitionEntity) _then;

/// Create a copy of SkillCredentialDefinitionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? title = null,Object? slug = null,Object? attributesJson = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SkillCredentialDefinitionEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,attributesJson: null == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialDefinitionToCreate {

 String get title; String get attributesJson;
/// Create a copy of SkillCredentialDefinitionToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialDefinitionToCreateCopyWith<SkillCredentialDefinitionToCreate> get copyWith => _$SkillCredentialDefinitionToCreateCopyWithImpl<SkillCredentialDefinitionToCreate>(this as SkillCredentialDefinitionToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialDefinitionToCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson));
}


@override
int get hashCode => Object.hash(runtimeType,title,attributesJson);

@override
String toString() {
  return 'SkillCredentialDefinitionToCreate(title: $title, attributesJson: $attributesJson)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialDefinitionToCreateCopyWith<$Res>  {
  factory $SkillCredentialDefinitionToCreateCopyWith(SkillCredentialDefinitionToCreate value, $Res Function(SkillCredentialDefinitionToCreate) _then) = _$SkillCredentialDefinitionToCreateCopyWithImpl;
@useResult
$Res call({
 String title, String attributesJson
});




}
/// @nodoc
class _$SkillCredentialDefinitionToCreateCopyWithImpl<$Res>
    implements $SkillCredentialDefinitionToCreateCopyWith<$Res> {
  _$SkillCredentialDefinitionToCreateCopyWithImpl(this._self, this._then);

  final SkillCredentialDefinitionToCreate _self;
  final $Res Function(SkillCredentialDefinitionToCreate) _then;

/// Create a copy of SkillCredentialDefinitionToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? attributesJson = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attributesJson: null == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialDefinitionToCreate].
extension SkillCredentialDefinitionToCreatePatterns on SkillCredentialDefinitionToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionToCreate value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialDefinitionToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String attributesJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate() when $default != null:
return $default(_that.title,_that.attributesJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String attributesJson)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate():
return $default(_that.title,_that.attributesJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String attributesJson)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToCreate() when $default != null:
return $default(_that.title,_that.attributesJson);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialDefinitionToCreate extends SkillCredentialDefinitionToCreate {
  const _SkillCredentialDefinitionToCreate({required this.title, required this.attributesJson}): super._();
  

@override final  String title;
@override final  String attributesJson;

/// Create a copy of SkillCredentialDefinitionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialDefinitionToCreateCopyWith<_SkillCredentialDefinitionToCreate> get copyWith => __$SkillCredentialDefinitionToCreateCopyWithImpl<_SkillCredentialDefinitionToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialDefinitionToCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson));
}


@override
int get hashCode => Object.hash(runtimeType,title,attributesJson);

@override
String toString() {
  return 'SkillCredentialDefinitionToCreate(title: $title, attributesJson: $attributesJson)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialDefinitionToCreateCopyWith<$Res> implements $SkillCredentialDefinitionToCreateCopyWith<$Res> {
  factory _$SkillCredentialDefinitionToCreateCopyWith(_SkillCredentialDefinitionToCreate value, $Res Function(_SkillCredentialDefinitionToCreate) _then) = __$SkillCredentialDefinitionToCreateCopyWithImpl;
@override @useResult
$Res call({
 String title, String attributesJson
});




}
/// @nodoc
class __$SkillCredentialDefinitionToCreateCopyWithImpl<$Res>
    implements _$SkillCredentialDefinitionToCreateCopyWith<$Res> {
  __$SkillCredentialDefinitionToCreateCopyWithImpl(this._self, this._then);

  final _SkillCredentialDefinitionToCreate _self;
  final $Res Function(_SkillCredentialDefinitionToCreate) _then;

/// Create a copy of SkillCredentialDefinitionToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? attributesJson = null,}) {
  return _then(_SkillCredentialDefinitionToCreate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attributesJson: null == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialDefinitionToUpdate {

 String? get title; String? get attributesJson;
/// Create a copy of SkillCredentialDefinitionToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialDefinitionToUpdateCopyWith<SkillCredentialDefinitionToUpdate> get copyWith => _$SkillCredentialDefinitionToUpdateCopyWithImpl<SkillCredentialDefinitionToUpdate>(this as SkillCredentialDefinitionToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialDefinitionToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson));
}


@override
int get hashCode => Object.hash(runtimeType,title,attributesJson);

@override
String toString() {
  return 'SkillCredentialDefinitionToUpdate(title: $title, attributesJson: $attributesJson)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialDefinitionToUpdateCopyWith<$Res>  {
  factory $SkillCredentialDefinitionToUpdateCopyWith(SkillCredentialDefinitionToUpdate value, $Res Function(SkillCredentialDefinitionToUpdate) _then) = _$SkillCredentialDefinitionToUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? attributesJson
});




}
/// @nodoc
class _$SkillCredentialDefinitionToUpdateCopyWithImpl<$Res>
    implements $SkillCredentialDefinitionToUpdateCopyWith<$Res> {
  _$SkillCredentialDefinitionToUpdateCopyWithImpl(this._self, this._then);

  final SkillCredentialDefinitionToUpdate _self;
  final $Res Function(SkillCredentialDefinitionToUpdate) _then;

/// Create a copy of SkillCredentialDefinitionToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? attributesJson = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,attributesJson: freezed == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialDefinitionToUpdate].
extension SkillCredentialDefinitionToUpdatePatterns on SkillCredentialDefinitionToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialDefinitionToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialDefinitionToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? attributesJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate() when $default != null:
return $default(_that.title,_that.attributesJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? attributesJson)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate():
return $default(_that.title,_that.attributesJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? attributesJson)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialDefinitionToUpdate() when $default != null:
return $default(_that.title,_that.attributesJson);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialDefinitionToUpdate extends SkillCredentialDefinitionToUpdate {
  const _SkillCredentialDefinitionToUpdate({this.title, this.attributesJson}): super._();
  

@override final  String? title;
@override final  String? attributesJson;

/// Create a copy of SkillCredentialDefinitionToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialDefinitionToUpdateCopyWith<_SkillCredentialDefinitionToUpdate> get copyWith => __$SkillCredentialDefinitionToUpdateCopyWithImpl<_SkillCredentialDefinitionToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialDefinitionToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.attributesJson, attributesJson) || other.attributesJson == attributesJson));
}


@override
int get hashCode => Object.hash(runtimeType,title,attributesJson);

@override
String toString() {
  return 'SkillCredentialDefinitionToUpdate(title: $title, attributesJson: $attributesJson)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialDefinitionToUpdateCopyWith<$Res> implements $SkillCredentialDefinitionToUpdateCopyWith<$Res> {
  factory _$SkillCredentialDefinitionToUpdateCopyWith(_SkillCredentialDefinitionToUpdate value, $Res Function(_SkillCredentialDefinitionToUpdate) _then) = __$SkillCredentialDefinitionToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? attributesJson
});




}
/// @nodoc
class __$SkillCredentialDefinitionToUpdateCopyWithImpl<$Res>
    implements _$SkillCredentialDefinitionToUpdateCopyWith<$Res> {
  __$SkillCredentialDefinitionToUpdateCopyWithImpl(this._self, this._then);

  final _SkillCredentialDefinitionToUpdate _self;
  final $Res Function(_SkillCredentialDefinitionToUpdate) _then;

/// Create a copy of SkillCredentialDefinitionToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? attributesJson = freezed,}) {
  return _then(_SkillCredentialDefinitionToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,attributesJson: freezed == attributesJson ? _self.attributesJson : attributesJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
