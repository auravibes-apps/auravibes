// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillEntity {

 String get id; String get workspaceId; SkillSource get source; SkillKind get kind; String get title; String get slug; String get description; String get content; bool get isEnabled; bool get isCredentialOptional; DateTime get createdAt; DateTime get updatedAt; String? get credentialDefinitionId;
/// Create a copy of SkillEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillEntityCopyWith<SkillEntity> get copyWith => _$SkillEntityCopyWithImpl<SkillEntity>(this as SkillEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.source, source) || other.source == source)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,source,kind,title,slug,description,content,isEnabled,isCredentialOptional,createdAt,updatedAt,credentialDefinitionId);

@override
String toString() {
  return 'SkillEntity(id: $id, workspaceId: $workspaceId, source: $source, kind: $kind, title: $title, slug: $slug, description: $description, content: $content, isEnabled: $isEnabled, isCredentialOptional: $isCredentialOptional, createdAt: $createdAt, updatedAt: $updatedAt, credentialDefinitionId: $credentialDefinitionId)';
}


}

/// @nodoc
abstract mixin class $SkillEntityCopyWith<$Res>  {
  factory $SkillEntityCopyWith(SkillEntity value, $Res Function(SkillEntity) _then) = _$SkillEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, SkillSource source, SkillKind kind, String title, String slug, String description, String content, bool isEnabled, bool isCredentialOptional, DateTime createdAt, DateTime updatedAt, String? credentialDefinitionId
});




}
/// @nodoc
class _$SkillEntityCopyWithImpl<$Res>
    implements $SkillEntityCopyWith<$Res> {
  _$SkillEntityCopyWithImpl(this._self, this._then);

  final SkillEntity _self;
  final $Res Function(SkillEntity) _then;

/// Create a copy of SkillEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? source = null,Object? kind = null,Object? title = null,Object? slug = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? isCredentialOptional = null,Object? createdAt = null,Object? updatedAt = null,Object? credentialDefinitionId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SkillSource,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SkillKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isCredentialOptional: null == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillEntity].
extension SkillEntityPatterns on SkillEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  SkillSource source,  SkillKind kind,  String title,  String slug,  String description,  String content,  bool isEnabled,  bool isCredentialOptional,  DateTime createdAt,  DateTime updatedAt,  String? credentialDefinitionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.source,_that.kind,_that.title,_that.slug,_that.description,_that.content,_that.isEnabled,_that.isCredentialOptional,_that.createdAt,_that.updatedAt,_that.credentialDefinitionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  SkillSource source,  SkillKind kind,  String title,  String slug,  String description,  String content,  bool isEnabled,  bool isCredentialOptional,  DateTime createdAt,  DateTime updatedAt,  String? credentialDefinitionId)  $default,) {final _that = this;
switch (_that) {
case _SkillEntity():
return $default(_that.id,_that.workspaceId,_that.source,_that.kind,_that.title,_that.slug,_that.description,_that.content,_that.isEnabled,_that.isCredentialOptional,_that.createdAt,_that.updatedAt,_that.credentialDefinitionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  SkillSource source,  SkillKind kind,  String title,  String slug,  String description,  String content,  bool isEnabled,  bool isCredentialOptional,  DateTime createdAt,  DateTime updatedAt,  String? credentialDefinitionId)?  $default,) {final _that = this;
switch (_that) {
case _SkillEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.source,_that.kind,_that.title,_that.slug,_that.description,_that.content,_that.isEnabled,_that.isCredentialOptional,_that.createdAt,_that.updatedAt,_that.credentialDefinitionId);case _:
  return null;

}
}

}

/// @nodoc


class _SkillEntity extends SkillEntity {
  const _SkillEntity({required this.id, required this.workspaceId, required this.source, required this.kind, required this.title, required this.slug, required this.description, required this.content, required this.isEnabled, required this.isCredentialOptional, required this.createdAt, required this.updatedAt, this.credentialDefinitionId}): super._();
  

@override final  String id;
@override final  String workspaceId;
@override final  SkillSource source;
@override final  SkillKind kind;
@override final  String title;
@override final  String slug;
@override final  String description;
@override final  String content;
@override final  bool isEnabled;
@override final  bool isCredentialOptional;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? credentialDefinitionId;

/// Create a copy of SkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillEntityCopyWith<_SkillEntity> get copyWith => __$SkillEntityCopyWithImpl<_SkillEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.source, source) || other.source == source)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,source,kind,title,slug,description,content,isEnabled,isCredentialOptional,createdAt,updatedAt,credentialDefinitionId);

@override
String toString() {
  return 'SkillEntity(id: $id, workspaceId: $workspaceId, source: $source, kind: $kind, title: $title, slug: $slug, description: $description, content: $content, isEnabled: $isEnabled, isCredentialOptional: $isCredentialOptional, createdAt: $createdAt, updatedAt: $updatedAt, credentialDefinitionId: $credentialDefinitionId)';
}


}

/// @nodoc
abstract mixin class _$SkillEntityCopyWith<$Res> implements $SkillEntityCopyWith<$Res> {
  factory _$SkillEntityCopyWith(_SkillEntity value, $Res Function(_SkillEntity) _then) = __$SkillEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, SkillSource source, SkillKind kind, String title, String slug, String description, String content, bool isEnabled, bool isCredentialOptional, DateTime createdAt, DateTime updatedAt, String? credentialDefinitionId
});




}
/// @nodoc
class __$SkillEntityCopyWithImpl<$Res>
    implements _$SkillEntityCopyWith<$Res> {
  __$SkillEntityCopyWithImpl(this._self, this._then);

  final _SkillEntity _self;
  final $Res Function(_SkillEntity) _then;

/// Create a copy of SkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? source = null,Object? kind = null,Object? title = null,Object? slug = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? isCredentialOptional = null,Object? createdAt = null,Object? updatedAt = null,Object? credentialDefinitionId = freezed,}) {
  return _then(_SkillEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SkillSource,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SkillKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isCredentialOptional: null == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SkillToCreate {

 SkillKind get kind; String get title; String get description; String get content; String? get credentialDefinitionId; bool get isCredentialOptional; bool get isEnabled;
/// Create a copy of SkillToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillToCreateCopyWith<SkillToCreate> get copyWith => _$SkillToCreateCopyWithImpl<SkillToCreate>(this as SkillToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillToCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,kind,title,description,content,credentialDefinitionId,isCredentialOptional,isEnabled);

@override
String toString() {
  return 'SkillToCreate(kind: $kind, title: $title, description: $description, content: $content, credentialDefinitionId: $credentialDefinitionId, isCredentialOptional: $isCredentialOptional, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $SkillToCreateCopyWith<$Res>  {
  factory $SkillToCreateCopyWith(SkillToCreate value, $Res Function(SkillToCreate) _then) = _$SkillToCreateCopyWithImpl;
@useResult
$Res call({
 SkillKind kind, String title, String description, String content, String? credentialDefinitionId, bool isCredentialOptional, bool isEnabled
});




}
/// @nodoc
class _$SkillToCreateCopyWithImpl<$Res>
    implements $SkillToCreateCopyWith<$Res> {
  _$SkillToCreateCopyWithImpl(this._self, this._then);

  final SkillToCreate _self;
  final $Res Function(SkillToCreate) _then;

/// Create a copy of SkillToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? title = null,Object? description = null,Object? content = null,Object? credentialDefinitionId = freezed,Object? isCredentialOptional = null,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SkillKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,isCredentialOptional: null == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillToCreate].
extension SkillToCreatePatterns on SkillToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillToCreate value)  $default,){
final _that = this;
switch (_that) {
case _SkillToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SkillKind kind,  String title,  String description,  String content,  String? credentialDefinitionId,  bool isCredentialOptional,  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillToCreate() when $default != null:
return $default(_that.kind,_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.isCredentialOptional,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SkillKind kind,  String title,  String description,  String content,  String? credentialDefinitionId,  bool isCredentialOptional,  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _SkillToCreate():
return $default(_that.kind,_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.isCredentialOptional,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SkillKind kind,  String title,  String description,  String content,  String? credentialDefinitionId,  bool isCredentialOptional,  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SkillToCreate() when $default != null:
return $default(_that.kind,_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.isCredentialOptional,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SkillToCreate extends SkillToCreate {
  const _SkillToCreate({required this.kind, required this.title, required this.description, required this.content, this.credentialDefinitionId, this.isCredentialOptional = false, this.isEnabled = true}): super._();
  

@override final  SkillKind kind;
@override final  String title;
@override final  String description;
@override final  String content;
@override final  String? credentialDefinitionId;
@override@JsonKey() final  bool isCredentialOptional;
@override@JsonKey() final  bool isEnabled;

/// Create a copy of SkillToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillToCreateCopyWith<_SkillToCreate> get copyWith => __$SkillToCreateCopyWithImpl<_SkillToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillToCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,kind,title,description,content,credentialDefinitionId,isCredentialOptional,isEnabled);

@override
String toString() {
  return 'SkillToCreate(kind: $kind, title: $title, description: $description, content: $content, credentialDefinitionId: $credentialDefinitionId, isCredentialOptional: $isCredentialOptional, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$SkillToCreateCopyWith<$Res> implements $SkillToCreateCopyWith<$Res> {
  factory _$SkillToCreateCopyWith(_SkillToCreate value, $Res Function(_SkillToCreate) _then) = __$SkillToCreateCopyWithImpl;
@override @useResult
$Res call({
 SkillKind kind, String title, String description, String content, String? credentialDefinitionId, bool isCredentialOptional, bool isEnabled
});




}
/// @nodoc
class __$SkillToCreateCopyWithImpl<$Res>
    implements _$SkillToCreateCopyWith<$Res> {
  __$SkillToCreateCopyWithImpl(this._self, this._then);

  final _SkillToCreate _self;
  final $Res Function(_SkillToCreate) _then;

/// Create a copy of SkillToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? title = null,Object? description = null,Object? content = null,Object? credentialDefinitionId = freezed,Object? isCredentialOptional = null,Object? isEnabled = null,}) {
  return _then(_SkillToCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SkillKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,isCredentialOptional: null == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SkillToUpdate {

 String? get title; String? get description; String? get content; String? get credentialDefinitionId; bool get clearCredentialDefinition; bool? get isCredentialOptional; bool? get isEnabled;
/// Create a copy of SkillToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillToUpdateCopyWith<SkillToUpdate> get copyWith => _$SkillToUpdateCopyWithImpl<SkillToUpdate>(this as SkillToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.clearCredentialDefinition, clearCredentialDefinition) || other.clearCredentialDefinition == clearCredentialDefinition)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,content,credentialDefinitionId,clearCredentialDefinition,isCredentialOptional,isEnabled);

@override
String toString() {
  return 'SkillToUpdate(title: $title, description: $description, content: $content, credentialDefinitionId: $credentialDefinitionId, clearCredentialDefinition: $clearCredentialDefinition, isCredentialOptional: $isCredentialOptional, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $SkillToUpdateCopyWith<$Res>  {
  factory $SkillToUpdateCopyWith(SkillToUpdate value, $Res Function(SkillToUpdate) _then) = _$SkillToUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? content, String? credentialDefinitionId, bool clearCredentialDefinition, bool? isCredentialOptional, bool? isEnabled
});




}
/// @nodoc
class _$SkillToUpdateCopyWithImpl<$Res>
    implements $SkillToUpdateCopyWith<$Res> {
  _$SkillToUpdateCopyWithImpl(this._self, this._then);

  final SkillToUpdate _self;
  final $Res Function(SkillToUpdate) _then;

/// Create a copy of SkillToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? credentialDefinitionId = freezed,Object? clearCredentialDefinition = null,Object? isCredentialOptional = freezed,Object? isEnabled = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,clearCredentialDefinition: null == clearCredentialDefinition ? _self.clearCredentialDefinition : clearCredentialDefinition // ignore: cast_nullable_to_non_nullable
as bool,isCredentialOptional: freezed == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool?,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillToUpdate].
extension SkillToUpdatePatterns on SkillToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _SkillToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? content,  String? credentialDefinitionId,  bool clearCredentialDefinition,  bool? isCredentialOptional,  bool? isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.clearCredentialDefinition,_that.isCredentialOptional,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? content,  String? credentialDefinitionId,  bool clearCredentialDefinition,  bool? isCredentialOptional,  bool? isEnabled)  $default,) {final _that = this;
switch (_that) {
case _SkillToUpdate():
return $default(_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.clearCredentialDefinition,_that.isCredentialOptional,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? content,  String? credentialDefinitionId,  bool clearCredentialDefinition,  bool? isCredentialOptional,  bool? isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SkillToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.content,_that.credentialDefinitionId,_that.clearCredentialDefinition,_that.isCredentialOptional,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SkillToUpdate extends SkillToUpdate {
  const _SkillToUpdate({this.title, this.description, this.content, this.credentialDefinitionId, this.clearCredentialDefinition = false, this.isCredentialOptional, this.isEnabled}): super._();
  

@override final  String? title;
@override final  String? description;
@override final  String? content;
@override final  String? credentialDefinitionId;
@override@JsonKey() final  bool clearCredentialDefinition;
@override final  bool? isCredentialOptional;
@override final  bool? isEnabled;

/// Create a copy of SkillToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillToUpdateCopyWith<_SkillToUpdate> get copyWith => __$SkillToUpdateCopyWithImpl<_SkillToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.clearCredentialDefinition, clearCredentialDefinition) || other.clearCredentialDefinition == clearCredentialDefinition)&&(identical(other.isCredentialOptional, isCredentialOptional) || other.isCredentialOptional == isCredentialOptional)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,content,credentialDefinitionId,clearCredentialDefinition,isCredentialOptional,isEnabled);

@override
String toString() {
  return 'SkillToUpdate(title: $title, description: $description, content: $content, credentialDefinitionId: $credentialDefinitionId, clearCredentialDefinition: $clearCredentialDefinition, isCredentialOptional: $isCredentialOptional, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$SkillToUpdateCopyWith<$Res> implements $SkillToUpdateCopyWith<$Res> {
  factory _$SkillToUpdateCopyWith(_SkillToUpdate value, $Res Function(_SkillToUpdate) _then) = __$SkillToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? content, String? credentialDefinitionId, bool clearCredentialDefinition, bool? isCredentialOptional, bool? isEnabled
});




}
/// @nodoc
class __$SkillToUpdateCopyWithImpl<$Res>
    implements _$SkillToUpdateCopyWith<$Res> {
  __$SkillToUpdateCopyWithImpl(this._self, this._then);

  final _SkillToUpdate _self;
  final $Res Function(_SkillToUpdate) _then;

/// Create a copy of SkillToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? credentialDefinitionId = freezed,Object? clearCredentialDefinition = null,Object? isCredentialOptional = freezed,Object? isEnabled = freezed,}) {
  return _then(_SkillToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,credentialDefinitionId: freezed == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String?,clearCredentialDefinition: null == clearCredentialDefinition ? _self.clearCredentialDefinition : clearCredentialDefinition // ignore: cast_nullable_to_non_nullable
as bool,isCredentialOptional: freezed == isCredentialOptional ? _self.isCredentialOptional : isCredentialOptional // ignore: cast_nullable_to_non_nullable
as bool?,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
