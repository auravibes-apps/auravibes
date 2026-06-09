// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_template_tool_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillTemplateToolEntity {

 String get id; String get skillId; SkillTemplateToolType get templateType; String get title; String get description; String get slug; String get templateJson; String get inputsJson; bool get isEnabled; bool get requiresCredential; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SkillTemplateToolEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillTemplateToolEntityCopyWith<SkillTemplateToolEntity> get copyWith => _$SkillTemplateToolEntityCopyWithImpl<SkillTemplateToolEntity>(this as SkillTemplateToolEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillTemplateToolEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&(identical(other.templateType, templateType) || other.templateType == templateType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,skillId,templateType,title,description,slug,templateJson,inputsJson,isEnabled,requiresCredential,createdAt,updatedAt);

@override
String toString() {
  return 'SkillTemplateToolEntity(id: $id, skillId: $skillId, templateType: $templateType, title: $title, description: $description, slug: $slug, templateJson: $templateJson, inputsJson: $inputsJson, isEnabled: $isEnabled, requiresCredential: $requiresCredential, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SkillTemplateToolEntityCopyWith<$Res>  {
  factory $SkillTemplateToolEntityCopyWith(SkillTemplateToolEntity value, $Res Function(SkillTemplateToolEntity) _then) = _$SkillTemplateToolEntityCopyWithImpl;
@useResult
$Res call({
 String id, String skillId, SkillTemplateToolType templateType, String title, String description, String slug, String templateJson, String inputsJson, bool isEnabled, bool requiresCredential, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SkillTemplateToolEntityCopyWithImpl<$Res>
    implements $SkillTemplateToolEntityCopyWith<$Res> {
  _$SkillTemplateToolEntityCopyWithImpl(this._self, this._then);

  final SkillTemplateToolEntity _self;
  final $Res Function(SkillTemplateToolEntity) _then;

/// Create a copy of SkillTemplateToolEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? skillId = null,Object? templateType = null,Object? title = null,Object? description = null,Object? slug = null,Object? templateJson = null,Object? inputsJson = null,Object? isEnabled = null,Object? requiresCredential = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,templateType: null == templateType ? _self.templateType : templateType // ignore: cast_nullable_to_non_nullable
as SkillTemplateToolType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,templateJson: null == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String,inputsJson: null == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,requiresCredential: null == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillTemplateToolEntity].
extension SkillTemplateToolEntityPatterns on SkillTemplateToolEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillTemplateToolEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillTemplateToolEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillTemplateToolEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillTemplateToolEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String skillId,  SkillTemplateToolType templateType,  String title,  String description,  String slug,  String templateJson,  String inputsJson,  bool isEnabled,  bool requiresCredential,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillTemplateToolEntity() when $default != null:
return $default(_that.id,_that.skillId,_that.templateType,_that.title,_that.description,_that.slug,_that.templateJson,_that.inputsJson,_that.isEnabled,_that.requiresCredential,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String skillId,  SkillTemplateToolType templateType,  String title,  String description,  String slug,  String templateJson,  String inputsJson,  bool isEnabled,  bool requiresCredential,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolEntity():
return $default(_that.id,_that.skillId,_that.templateType,_that.title,_that.description,_that.slug,_that.templateJson,_that.inputsJson,_that.isEnabled,_that.requiresCredential,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String skillId,  SkillTemplateToolType templateType,  String title,  String description,  String slug,  String templateJson,  String inputsJson,  bool isEnabled,  bool requiresCredential,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolEntity() when $default != null:
return $default(_that.id,_that.skillId,_that.templateType,_that.title,_that.description,_that.slug,_that.templateJson,_that.inputsJson,_that.isEnabled,_that.requiresCredential,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SkillTemplateToolEntity extends SkillTemplateToolEntity {
  const _SkillTemplateToolEntity({required this.id, required this.skillId, required this.templateType, required this.title, required this.description, required this.slug, required this.templateJson, required this.inputsJson, required this.isEnabled, required this.requiresCredential, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  String skillId;
@override final  SkillTemplateToolType templateType;
@override final  String title;
@override final  String description;
@override final  String slug;
@override final  String templateJson;
@override final  String inputsJson;
@override final  bool isEnabled;
@override final  bool requiresCredential;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SkillTemplateToolEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillTemplateToolEntityCopyWith<_SkillTemplateToolEntity> get copyWith => __$SkillTemplateToolEntityCopyWithImpl<_SkillTemplateToolEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillTemplateToolEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&(identical(other.templateType, templateType) || other.templateType == templateType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,skillId,templateType,title,description,slug,templateJson,inputsJson,isEnabled,requiresCredential,createdAt,updatedAt);

@override
String toString() {
  return 'SkillTemplateToolEntity(id: $id, skillId: $skillId, templateType: $templateType, title: $title, description: $description, slug: $slug, templateJson: $templateJson, inputsJson: $inputsJson, isEnabled: $isEnabled, requiresCredential: $requiresCredential, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SkillTemplateToolEntityCopyWith<$Res> implements $SkillTemplateToolEntityCopyWith<$Res> {
  factory _$SkillTemplateToolEntityCopyWith(_SkillTemplateToolEntity value, $Res Function(_SkillTemplateToolEntity) _then) = __$SkillTemplateToolEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String skillId, SkillTemplateToolType templateType, String title, String description, String slug, String templateJson, String inputsJson, bool isEnabled, bool requiresCredential, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SkillTemplateToolEntityCopyWithImpl<$Res>
    implements _$SkillTemplateToolEntityCopyWith<$Res> {
  __$SkillTemplateToolEntityCopyWithImpl(this._self, this._then);

  final _SkillTemplateToolEntity _self;
  final $Res Function(_SkillTemplateToolEntity) _then;

/// Create a copy of SkillTemplateToolEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? skillId = null,Object? templateType = null,Object? title = null,Object? description = null,Object? slug = null,Object? templateJson = null,Object? inputsJson = null,Object? isEnabled = null,Object? requiresCredential = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SkillTemplateToolEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,skillId: null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,templateType: null == templateType ? _self.templateType : templateType // ignore: cast_nullable_to_non_nullable
as SkillTemplateToolType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,templateJson: null == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String,inputsJson: null == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,requiresCredential: null == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$SkillTemplateToolToCreate {

 SkillTemplateToolType get templateType; String get title; String get description; String get templateJson; String get inputsJson; bool get requiresCredential; bool get isEnabled;
/// Create a copy of SkillTemplateToolToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillTemplateToolToCreateCopyWith<SkillTemplateToolToCreate> get copyWith => _$SkillTemplateToolToCreateCopyWithImpl<SkillTemplateToolToCreate>(this as SkillTemplateToolToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillTemplateToolToCreate&&(identical(other.templateType, templateType) || other.templateType == templateType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,templateType,title,description,templateJson,inputsJson,requiresCredential,isEnabled);

@override
String toString() {
  return 'SkillTemplateToolToCreate(templateType: $templateType, title: $title, description: $description, templateJson: $templateJson, inputsJson: $inputsJson, requiresCredential: $requiresCredential, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $SkillTemplateToolToCreateCopyWith<$Res>  {
  factory $SkillTemplateToolToCreateCopyWith(SkillTemplateToolToCreate value, $Res Function(SkillTemplateToolToCreate) _then) = _$SkillTemplateToolToCreateCopyWithImpl;
@useResult
$Res call({
 SkillTemplateToolType templateType, String title, String description, String templateJson, String inputsJson, bool requiresCredential, bool isEnabled
});




}
/// @nodoc
class _$SkillTemplateToolToCreateCopyWithImpl<$Res>
    implements $SkillTemplateToolToCreateCopyWith<$Res> {
  _$SkillTemplateToolToCreateCopyWithImpl(this._self, this._then);

  final SkillTemplateToolToCreate _self;
  final $Res Function(SkillTemplateToolToCreate) _then;

/// Create a copy of SkillTemplateToolToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? templateType = null,Object? title = null,Object? description = null,Object? templateJson = null,Object? inputsJson = null,Object? requiresCredential = null,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
templateType: null == templateType ? _self.templateType : templateType // ignore: cast_nullable_to_non_nullable
as SkillTemplateToolType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,templateJson: null == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String,inputsJson: null == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String,requiresCredential: null == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillTemplateToolToCreate].
extension SkillTemplateToolToCreatePatterns on SkillTemplateToolToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillTemplateToolToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillTemplateToolToCreate value)  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillTemplateToolToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SkillTemplateToolType templateType,  String title,  String description,  String templateJson,  String inputsJson,  bool requiresCredential,  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate() when $default != null:
return $default(_that.templateType,_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SkillTemplateToolType templateType,  String title,  String description,  String templateJson,  String inputsJson,  bool requiresCredential,  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate():
return $default(_that.templateType,_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SkillTemplateToolType templateType,  String title,  String description,  String templateJson,  String inputsJson,  bool requiresCredential,  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolToCreate() when $default != null:
return $default(_that.templateType,_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SkillTemplateToolToCreate extends SkillTemplateToolToCreate {
  const _SkillTemplateToolToCreate({required this.templateType, required this.title, required this.description, required this.templateJson, required this.inputsJson, this.requiresCredential = false, this.isEnabled = true}): super._();
  

@override final  SkillTemplateToolType templateType;
@override final  String title;
@override final  String description;
@override final  String templateJson;
@override final  String inputsJson;
@override@JsonKey() final  bool requiresCredential;
@override@JsonKey() final  bool isEnabled;

/// Create a copy of SkillTemplateToolToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillTemplateToolToCreateCopyWith<_SkillTemplateToolToCreate> get copyWith => __$SkillTemplateToolToCreateCopyWithImpl<_SkillTemplateToolToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillTemplateToolToCreate&&(identical(other.templateType, templateType) || other.templateType == templateType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,templateType,title,description,templateJson,inputsJson,requiresCredential,isEnabled);

@override
String toString() {
  return 'SkillTemplateToolToCreate(templateType: $templateType, title: $title, description: $description, templateJson: $templateJson, inputsJson: $inputsJson, requiresCredential: $requiresCredential, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$SkillTemplateToolToCreateCopyWith<$Res> implements $SkillTemplateToolToCreateCopyWith<$Res> {
  factory _$SkillTemplateToolToCreateCopyWith(_SkillTemplateToolToCreate value, $Res Function(_SkillTemplateToolToCreate) _then) = __$SkillTemplateToolToCreateCopyWithImpl;
@override @useResult
$Res call({
 SkillTemplateToolType templateType, String title, String description, String templateJson, String inputsJson, bool requiresCredential, bool isEnabled
});




}
/// @nodoc
class __$SkillTemplateToolToCreateCopyWithImpl<$Res>
    implements _$SkillTemplateToolToCreateCopyWith<$Res> {
  __$SkillTemplateToolToCreateCopyWithImpl(this._self, this._then);

  final _SkillTemplateToolToCreate _self;
  final $Res Function(_SkillTemplateToolToCreate) _then;

/// Create a copy of SkillTemplateToolToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? templateType = null,Object? title = null,Object? description = null,Object? templateJson = null,Object? inputsJson = null,Object? requiresCredential = null,Object? isEnabled = null,}) {
  return _then(_SkillTemplateToolToCreate(
templateType: null == templateType ? _self.templateType : templateType // ignore: cast_nullable_to_non_nullable
as SkillTemplateToolType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,templateJson: null == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String,inputsJson: null == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String,requiresCredential: null == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SkillTemplateToolToUpdate {

 String? get title; String? get description; String? get templateJson; String? get inputsJson; bool? get requiresCredential; bool? get isEnabled;
/// Create a copy of SkillTemplateToolToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillTemplateToolToUpdateCopyWith<SkillTemplateToolToUpdate> get copyWith => _$SkillTemplateToolToUpdateCopyWithImpl<SkillTemplateToolToUpdate>(this as SkillTemplateToolToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillTemplateToolToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,templateJson,inputsJson,requiresCredential,isEnabled);

@override
String toString() {
  return 'SkillTemplateToolToUpdate(title: $title, description: $description, templateJson: $templateJson, inputsJson: $inputsJson, requiresCredential: $requiresCredential, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $SkillTemplateToolToUpdateCopyWith<$Res>  {
  factory $SkillTemplateToolToUpdateCopyWith(SkillTemplateToolToUpdate value, $Res Function(SkillTemplateToolToUpdate) _then) = _$SkillTemplateToolToUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? templateJson, String? inputsJson, bool? requiresCredential, bool? isEnabled
});




}
/// @nodoc
class _$SkillTemplateToolToUpdateCopyWithImpl<$Res>
    implements $SkillTemplateToolToUpdateCopyWith<$Res> {
  _$SkillTemplateToolToUpdateCopyWithImpl(this._self, this._then);

  final SkillTemplateToolToUpdate _self;
  final $Res Function(SkillTemplateToolToUpdate) _then;

/// Create a copy of SkillTemplateToolToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? templateJson = freezed,Object? inputsJson = freezed,Object? requiresCredential = freezed,Object? isEnabled = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,templateJson: freezed == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String?,inputsJson: freezed == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String?,requiresCredential: freezed == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool?,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillTemplateToolToUpdate].
extension SkillTemplateToolToUpdatePatterns on SkillTemplateToolToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillTemplateToolToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillTemplateToolToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillTemplateToolToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? templateJson,  String? inputsJson,  bool? requiresCredential,  bool? isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? templateJson,  String? inputsJson,  bool? requiresCredential,  bool? isEnabled)  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate():
return $default(_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? templateJson,  String? inputsJson,  bool? requiresCredential,  bool? isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SkillTemplateToolToUpdate() when $default != null:
return $default(_that.title,_that.description,_that.templateJson,_that.inputsJson,_that.requiresCredential,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SkillTemplateToolToUpdate extends SkillTemplateToolToUpdate {
  const _SkillTemplateToolToUpdate({this.title, this.description, this.templateJson, this.inputsJson, this.requiresCredential, this.isEnabled}): super._();
  

@override final  String? title;
@override final  String? description;
@override final  String? templateJson;
@override final  String? inputsJson;
@override final  bool? requiresCredential;
@override final  bool? isEnabled;

/// Create a copy of SkillTemplateToolToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillTemplateToolToUpdateCopyWith<_SkillTemplateToolToUpdate> get copyWith => __$SkillTemplateToolToUpdateCopyWithImpl<_SkillTemplateToolToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillTemplateToolToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.templateJson, templateJson) || other.templateJson == templateJson)&&(identical(other.inputsJson, inputsJson) || other.inputsJson == inputsJson)&&(identical(other.requiresCredential, requiresCredential) || other.requiresCredential == requiresCredential)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,templateJson,inputsJson,requiresCredential,isEnabled);

@override
String toString() {
  return 'SkillTemplateToolToUpdate(title: $title, description: $description, templateJson: $templateJson, inputsJson: $inputsJson, requiresCredential: $requiresCredential, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$SkillTemplateToolToUpdateCopyWith<$Res> implements $SkillTemplateToolToUpdateCopyWith<$Res> {
  factory _$SkillTemplateToolToUpdateCopyWith(_SkillTemplateToolToUpdate value, $Res Function(_SkillTemplateToolToUpdate) _then) = __$SkillTemplateToolToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? templateJson, String? inputsJson, bool? requiresCredential, bool? isEnabled
});




}
/// @nodoc
class __$SkillTemplateToolToUpdateCopyWithImpl<$Res>
    implements _$SkillTemplateToolToUpdateCopyWith<$Res> {
  __$SkillTemplateToolToUpdateCopyWithImpl(this._self, this._then);

  final _SkillTemplateToolToUpdate _self;
  final $Res Function(_SkillTemplateToolToUpdate) _then;

/// Create a copy of SkillTemplateToolToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? templateJson = freezed,Object? inputsJson = freezed,Object? requiresCredential = freezed,Object? isEnabled = freezed,}) {
  return _then(_SkillTemplateToolToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,templateJson: freezed == templateJson ? _self.templateJson : templateJson // ignore: cast_nullable_to_non_nullable
as String?,inputsJson: freezed == inputsJson ? _self.inputsJson : inputsJson // ignore: cast_nullable_to_non_nullable
as String?,requiresCredential: freezed == requiresCredential ? _self.requiresCredential : requiresCredential // ignore: cast_nullable_to_non_nullable
as bool?,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
