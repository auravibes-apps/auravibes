// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_resource_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillResourceEntity {

 String get id; String get skillId; String get title; String get slug; String get description; String get content; DateTime get createdAt; DateTime get updatedAt; int get revision;
/// Create a copy of SkillResourceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillResourceEntityCopyWith<SkillResourceEntity> get copyWith => _$SkillResourceEntityCopyWithImpl<SkillResourceEntity>(this as SkillResourceEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SkillResourceEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillResourceEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.skillId, _this.skillId) || other.skillId == _this.skillId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as SkillResourceEntity;
  return Object.hash(runtimeType,_this.id,_this.skillId,_this.title,_this.slug,_this.description,_this.content,_this.createdAt,_this.updatedAt,_this.revision);
}

@override
String toString() {
  final _this = this as SkillResourceEntity;
  return 'SkillResourceEntity(id: ${_this.id}, skillId: ${_this.skillId}, title: ${_this.title}, slug: ${_this.slug}, description: ${_this.description}, content: ${_this.content}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $SkillResourceEntityCopyWith<$Res>  {
  factory $SkillResourceEntityCopyWith(SkillResourceEntity value, $Res Function(SkillResourceEntity) _then) = _$SkillResourceEntityCopyWithImpl;
@useResult
$Res call({
 String id, String skillId, String title, String slug, String description, String content, DateTime createdAt, DateTime updatedAt, int revision
});




}
/// @nodoc
class _$SkillResourceEntityCopyWithImpl<$Res>
    implements $SkillResourceEntityCopyWith<$Res> {
  _$SkillResourceEntityCopyWithImpl(this._self, this._then);

  final SkillResourceEntity _self;
  final $Res Function(SkillResourceEntity) _then;

/// Create a copy of SkillResourceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? skillId = null,Object? title = null,Object? slug = null,Object? description = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? revision = null,}) {
  return _then(SkillResourceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillResourceEntity].
extension SkillResourceEntityPatterns on SkillResourceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillResourceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillResourceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillResourceEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillResourceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillResourceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillResourceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String skillId,  String title,  String slug,  String description,  String content,  DateTime createdAt,  DateTime updatedAt,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillResourceEntity() when $default != null:
return $default(_that.id,_that.skillId,_that.title,_that.slug,_that.description,_that.content,_that.createdAt,_that.updatedAt,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String skillId,  String title,  String slug,  String description,  String content,  DateTime createdAt,  DateTime updatedAt,  int revision)  $default,) {final _that = this;
switch (_that) {
case _SkillResourceEntity():
return $default(_that.id,_that.skillId,_that.title,_that.slug,_that.description,_that.content,_that.createdAt,_that.updatedAt,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String skillId,  String title,  String slug,  String description,  String content,  DateTime createdAt,  DateTime updatedAt,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _SkillResourceEntity() when $default != null:
return $default(_that.id,_that.skillId,_that.title,_that.slug,_that.description,_that.content,_that.createdAt,_that.updatedAt,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _SkillResourceEntity extends SkillResourceEntity {
  const _SkillResourceEntity({required this.id, required this.skillId, required this.title, required this.slug, required this.description, required this.content, required this.createdAt, required this.updatedAt, this.revision = 1}): super._();
  

@override final  String id;
@override final  String skillId;
@override final  String title;
@override final  String slug;
@override final  String description;
@override final  String content;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  int revision;

/// Create a copy of SkillResourceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillResourceEntityCopyWith<_SkillResourceEntity> get copyWith => __$SkillResourceEntityCopyWithImpl<_SkillResourceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillResourceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,skillId,title,slug,description,content,createdAt,updatedAt,revision);
}

@override
String toString() {
    return 'SkillResourceEntity(id: $id, skillId: $skillId, title: $title, slug: $slug, description: $description, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$SkillResourceEntityCopyWith<$Res> implements $SkillResourceEntityCopyWith<$Res> {
  factory _$SkillResourceEntityCopyWith(_SkillResourceEntity value, $Res Function(_SkillResourceEntity) _then) = __$SkillResourceEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String skillId, String title, String slug, String description, String content, DateTime createdAt, DateTime updatedAt, int revision
});




}
/// @nodoc
class __$SkillResourceEntityCopyWithImpl<$Res>
    implements _$SkillResourceEntityCopyWith<$Res> {
  __$SkillResourceEntityCopyWithImpl(this._self, this._then);

  final _SkillResourceEntity _self;
  final $Res Function(_SkillResourceEntity) _then;

/// Create a copy of SkillResourceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? skillId = null,Object? title = null,Object? slug = null,Object? description = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? revision = null,}) {
  return _then(_SkillResourceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SkillResourceToCreate {

 String get title; String get description; String get content;
/// Create a copy of SkillResourceToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillResourceToCreateCopyWith<SkillResourceToCreate> get copyWith => _$SkillResourceToCreateCopyWithImpl<SkillResourceToCreate>(this as SkillResourceToCreate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SkillResourceToCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillResourceToCreate&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.content, _this.content) || other.content == _this.content));
}


@override
int get hashCode {
  final _this = this as SkillResourceToCreate;
  return Object.hash(runtimeType,_this.title,_this.description,_this.content);
}

@override
String toString() {
  final _this = this as SkillResourceToCreate;
  return 'SkillResourceToCreate(title: ${_this.title}, description: ${_this.description}, content: ${_this.content})';
}


}

/// @nodoc
abstract mixin class $SkillResourceToCreateCopyWith<$Res>  {
  factory $SkillResourceToCreateCopyWith(SkillResourceToCreate value, $Res Function(SkillResourceToCreate) _then) = _$SkillResourceToCreateCopyWithImpl;
@useResult
$Res call({
 String title, String description, String content
});




}
/// @nodoc
class _$SkillResourceToCreateCopyWithImpl<$Res>
    implements $SkillResourceToCreateCopyWith<$Res> {
  _$SkillResourceToCreateCopyWithImpl(this._self, this._then);

  final SkillResourceToCreate _self;
  final $Res Function(SkillResourceToCreate) _then;

/// Create a copy of SkillResourceToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? content = null,}) {
  return _then(SkillResourceToCreate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillResourceToCreate].
extension SkillResourceToCreatePatterns on SkillResourceToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillResourceToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillResourceToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillResourceToCreate value)  $default,){
final _that = this;
switch (_that) {
case _SkillResourceToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillResourceToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillResourceToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillResourceToCreate() when $default != null:
return $default(_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String content)  $default,) {final _that = this;
switch (_that) {
case _SkillResourceToCreate():
return $default(_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String content)?  $default,) {final _that = this;
switch (_that) {
case _SkillResourceToCreate() when $default != null:
return $default(_that.title,_that.description,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _SkillResourceToCreate extends SkillResourceToCreate {
  const _SkillResourceToCreate({required this.title, required this.description, required this.content}): super._();
  

@override final  String title;
@override final  String description;
@override final  String content;

/// Create a copy of SkillResourceToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillResourceToCreateCopyWith<_SkillResourceToCreate> get copyWith => __$SkillResourceToCreateCopyWithImpl<_SkillResourceToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillResourceToCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,description,content);
}

@override
String toString() {
    return 'SkillResourceToCreate(title: $title, description: $description, content: $content)';
}


}

/// @nodoc
abstract mixin class _$SkillResourceToCreateCopyWith<$Res> implements $SkillResourceToCreateCopyWith<$Res> {
  factory _$SkillResourceToCreateCopyWith(_SkillResourceToCreate value, $Res Function(_SkillResourceToCreate) _then) = __$SkillResourceToCreateCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String content
});




}
/// @nodoc
class __$SkillResourceToCreateCopyWithImpl<$Res>
    implements _$SkillResourceToCreateCopyWith<$Res> {
  __$SkillResourceToCreateCopyWithImpl(this._self, this._then);

  final _SkillResourceToCreate _self;
  final $Res Function(_SkillResourceToCreate) _then;

/// Create a copy of SkillResourceToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? content = null,}) {
  return _then(_SkillResourceToCreate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SkillResourceToUpdate {

 String? get title; String? get description; String? get content;
/// Create a copy of SkillResourceToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillResourceToUpdateCopyWith<SkillResourceToUpdate> get copyWith => _$SkillResourceToUpdateCopyWithImpl<SkillResourceToUpdate>(this as SkillResourceToUpdate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SkillResourceToUpdate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillResourceToUpdate&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.content, _this.content) || other.content == _this.content));
}


@override
int get hashCode {
  final _this = this as SkillResourceToUpdate;
  return Object.hash(runtimeType,_this.title,_this.description,_this.content);
}

@override
String toString() {
  final _this = this as SkillResourceToUpdate;
  return 'SkillResourceToUpdate(title: ${_this.title}, description: ${_this.description}, content: ${_this.content})';
}


}

/// @nodoc
abstract mixin class $SkillResourceToUpdateCopyWith<$Res>  {
  factory $SkillResourceToUpdateCopyWith(SkillResourceToUpdate value, $Res Function(SkillResourceToUpdate) _then) = _$SkillResourceToUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? content
});




}
/// @nodoc
class _$SkillResourceToUpdateCopyWithImpl<$Res>
    implements $SkillResourceToUpdateCopyWith<$Res> {
  _$SkillResourceToUpdateCopyWithImpl(this._self, this._then);

  final SkillResourceToUpdate _self;
  final $Res Function(SkillResourceToUpdate) _then;

/// Create a copy of SkillResourceToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? content = freezed,}) {
  return _then(SkillResourceToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillResourceToUpdate].
extension SkillResourceToUpdatePatterns on SkillResourceToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillResourceToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillResourceToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillResourceToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _SkillResourceToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillResourceToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillResourceToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillResourceToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? content)  $default,) {final _that = this;
switch (_that) {
case _SkillResourceToUpdate():
return $default(_that.title,_that.description,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? content)?  $default,) {final _that = this;
switch (_that) {
case _SkillResourceToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _SkillResourceToUpdate extends SkillResourceToUpdate {
  const _SkillResourceToUpdate({this.title, this.description, this.content}): super._();
  

@override final  String? title;
@override final  String? description;
@override final  String? content;

/// Create a copy of SkillResourceToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillResourceToUpdateCopyWith<_SkillResourceToUpdate> get copyWith => __$SkillResourceToUpdateCopyWithImpl<_SkillResourceToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillResourceToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,description,content);
}

@override
String toString() {
    return 'SkillResourceToUpdate(title: $title, description: $description, content: $content)';
}


}

/// @nodoc
abstract mixin class _$SkillResourceToUpdateCopyWith<$Res> implements $SkillResourceToUpdateCopyWith<$Res> {
  factory _$SkillResourceToUpdateCopyWith(_SkillResourceToUpdate value, $Res Function(_SkillResourceToUpdate) _then) = __$SkillResourceToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? content
});




}
/// @nodoc
class __$SkillResourceToUpdateCopyWithImpl<$Res>
    implements _$SkillResourceToUpdateCopyWith<$Res> {
  __$SkillResourceToUpdateCopyWithImpl(this._self, this._then);

  final _SkillResourceToUpdate _self;
  final $Res Function(_SkillResourceToUpdate) _then;

/// Create a copy of SkillResourceToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? content = freezed,}) {
  return _then(_SkillResourceToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
