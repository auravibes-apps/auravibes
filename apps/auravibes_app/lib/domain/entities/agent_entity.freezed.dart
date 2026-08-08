// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AgentEntity {

 String get id; String get workspaceId; String get name; String get content; List<AgentSkillRef> get skills; DateTime get createdAt; DateTime get updatedAt; String get description; bool get isEnabled; AgentVisibility get visibility;
/// Create a copy of AgentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentEntityCopyWith<AgentEntity> get copyWith => _$AgentEntityCopyWithImpl<AgentEntity>(this as AgentEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.skills, skills)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,content,const DeepCollectionEquality().hash(skills),createdAt,updatedAt,description,isEnabled,visibility);

@override
String toString() {
  return 'AgentEntity(id: $id, workspaceId: $workspaceId, name: $name, content: $content, skills: $skills, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isEnabled: $isEnabled, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class $AgentEntityCopyWith<$Res>  {
  factory $AgentEntityCopyWith(AgentEntity value, $Res Function(AgentEntity) _then) = _$AgentEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, String content, List<AgentSkillRef> skills, DateTime createdAt, DateTime updatedAt, String description, bool isEnabled, AgentVisibility visibility
});




}
/// @nodoc
class _$AgentEntityCopyWithImpl<$Res>
    implements $AgentEntityCopyWith<$Res> {
  _$AgentEntityCopyWithImpl(this._self, this._then);

  final AgentEntity _self;
  final $Res Function(AgentEntity) _then;

/// Create a copy of AgentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? content = null,Object? skills = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isEnabled = null,Object? visibility = null,}) {
  return _then(AgentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentEntity].
extension AgentEntityPatterns on AgentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentEntity value)  $default,){
final _that = this;
switch (_that) {
case _AgentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _AgentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String content,  List<AgentSkillRef> skills,  DateTime createdAt,  DateTime updatedAt,  String description,  bool isEnabled,  AgentVisibility visibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.content,_that.skills,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled,_that.visibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String content,  List<AgentSkillRef> skills,  DateTime createdAt,  DateTime updatedAt,  String description,  bool isEnabled,  AgentVisibility visibility)  $default,) {final _that = this;
switch (_that) {
case _AgentEntity():
return $default(_that.id,_that.workspaceId,_that.name,_that.content,_that.skills,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled,_that.visibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  String content,  List<AgentSkillRef> skills,  DateTime createdAt,  DateTime updatedAt,  String description,  bool isEnabled,  AgentVisibility visibility)?  $default,) {final _that = this;
switch (_that) {
case _AgentEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.content,_that.skills,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled,_that.visibility);case _:
  return null;

}
}

}

/// @nodoc


class _AgentEntity extends AgentEntity {
  const _AgentEntity({required this.id, required this.workspaceId, required this.name, required this.content, required  List<AgentSkillRef> skills, required this.createdAt, required this.updatedAt, this.description = '', this.isEnabled = true, this.visibility = AgentVisibility.both}): _skills = skills,super._();
  

@override final  String id;
@override final  String workspaceId;
@override final  String name;
@override final  String content;
 final  List<AgentSkillRef> _skills;
@override List<AgentSkillRef> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  String description;
@override@JsonKey() final  bool isEnabled;
@override@JsonKey() final  AgentVisibility visibility;

/// Create a copy of AgentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentEntityCopyWith<_AgentEntity> get copyWith => __$AgentEntityCopyWithImpl<_AgentEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._skills, _skills)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,content,const DeepCollectionEquality().hash(_skills),createdAt,updatedAt,description,isEnabled,visibility);

@override
String toString() {
  return 'AgentEntity(id: $id, workspaceId: $workspaceId, name: $name, content: $content, skills: $skills, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isEnabled: $isEnabled, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class _$AgentEntityCopyWith<$Res> implements $AgentEntityCopyWith<$Res> {
  factory _$AgentEntityCopyWith(_AgentEntity value, $Res Function(_AgentEntity) _then) = __$AgentEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, String content, List<AgentSkillRef> skills, DateTime createdAt, DateTime updatedAt, String description, bool isEnabled, AgentVisibility visibility
});




}
/// @nodoc
class __$AgentEntityCopyWithImpl<$Res>
    implements _$AgentEntityCopyWith<$Res> {
  __$AgentEntityCopyWithImpl(this._self, this._then);

  final _AgentEntity _self;
  final $Res Function(_AgentEntity) _then;

/// Create a copy of AgentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? content = null,Object? skills = null,Object? createdAt = null,Object? updatedAt = null,Object? description = null,Object? isEnabled = null,Object? visibility = null,}) {
  return _then(_AgentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,
  ));
}


}

/// @nodoc
mixin _$AgentToCreate {

 String get name; String get description; String get content; bool get isEnabled; AgentVisibility get visibility; List<AgentSkillRef> get skills;
/// Create a copy of AgentToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentToCreateCopyWith<AgentToCreate> get copyWith => _$AgentToCreateCopyWithImpl<AgentToCreate>(this as AgentToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other.skills, skills));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,content,isEnabled,visibility,const DeepCollectionEquality().hash(skills));

@override
String toString() {
  return 'AgentToCreate(name: $name, description: $description, content: $content, isEnabled: $isEnabled, visibility: $visibility, skills: $skills)';
}


}

/// @nodoc
abstract mixin class $AgentToCreateCopyWith<$Res>  {
  factory $AgentToCreateCopyWith(AgentToCreate value, $Res Function(AgentToCreate) _then) = _$AgentToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String description, String content, bool isEnabled, AgentVisibility visibility, List<AgentSkillRef> skills
});




}
/// @nodoc
class _$AgentToCreateCopyWithImpl<$Res>
    implements $AgentToCreateCopyWith<$Res> {
  _$AgentToCreateCopyWithImpl(this._self, this._then);

  final AgentToCreate _self;
  final $Res Function(AgentToCreate) _then;

/// Create a copy of AgentToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? visibility = null,Object? skills = null,}) {
  return _then(AgentToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentToCreate].
extension AgentToCreatePatterns on AgentToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentToCreate value)  $default,){
final _that = this;
switch (_that) {
case _AgentToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _AgentToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentToCreate() when $default != null:
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)  $default,) {final _that = this;
switch (_that) {
case _AgentToCreate():
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)?  $default,) {final _that = this;
switch (_that) {
case _AgentToCreate() when $default != null:
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
  return null;

}
}

}

/// @nodoc


class _AgentToCreate extends AgentToCreate {
  const _AgentToCreate({required this.name, required this.description, required this.content, this.isEnabled = true, this.visibility = AgentVisibility.both,  List<AgentSkillRef> skills = const []}): _skills = skills,super._();
  

@override final  String name;
@override final  String description;
@override final  String content;
@override@JsonKey() final  bool isEnabled;
@override@JsonKey() final  AgentVisibility visibility;
 final  List<AgentSkillRef> _skills;
@override@JsonKey() List<AgentSkillRef> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}


/// Create a copy of AgentToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentToCreateCopyWith<_AgentToCreate> get copyWith => __$AgentToCreateCopyWithImpl<_AgentToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other._skills, _skills));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,content,isEnabled,visibility,const DeepCollectionEquality().hash(_skills));

@override
String toString() {
  return 'AgentToCreate(name: $name, description: $description, content: $content, isEnabled: $isEnabled, visibility: $visibility, skills: $skills)';
}


}

/// @nodoc
abstract mixin class _$AgentToCreateCopyWith<$Res> implements $AgentToCreateCopyWith<$Res> {
  factory _$AgentToCreateCopyWith(_AgentToCreate value, $Res Function(_AgentToCreate) _then) = __$AgentToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String content, bool isEnabled, AgentVisibility visibility, List<AgentSkillRef> skills
});




}
/// @nodoc
class __$AgentToCreateCopyWithImpl<$Res>
    implements _$AgentToCreateCopyWith<$Res> {
  __$AgentToCreateCopyWithImpl(this._self, this._then);

  final _AgentToCreate _self;
  final $Res Function(_AgentToCreate) _then;

/// Create a copy of AgentToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? visibility = null,Object? skills = null,}) {
  return _then(_AgentToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,
  ));
}


}

/// @nodoc
mixin _$AgentToUpdate {

 String get name; String get description; String get content; bool get isEnabled; AgentVisibility get visibility; List<AgentSkillRef> get skills;
/// Create a copy of AgentToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentToUpdateCopyWith<AgentToUpdate> get copyWith => _$AgentToUpdateCopyWithImpl<AgentToUpdate>(this as AgentToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentToUpdate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other.skills, skills));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,content,isEnabled,visibility,const DeepCollectionEquality().hash(skills));

@override
String toString() {
  return 'AgentToUpdate(name: $name, description: $description, content: $content, isEnabled: $isEnabled, visibility: $visibility, skills: $skills)';
}


}

/// @nodoc
abstract mixin class $AgentToUpdateCopyWith<$Res>  {
  factory $AgentToUpdateCopyWith(AgentToUpdate value, $Res Function(AgentToUpdate) _then) = _$AgentToUpdateCopyWithImpl;
@useResult
$Res call({
 String name, String description, String content, bool isEnabled, AgentVisibility visibility, List<AgentSkillRef> skills
});




}
/// @nodoc
class _$AgentToUpdateCopyWithImpl<$Res>
    implements $AgentToUpdateCopyWith<$Res> {
  _$AgentToUpdateCopyWithImpl(this._self, this._then);

  final AgentToUpdate _self;
  final $Res Function(AgentToUpdate) _then;

/// Create a copy of AgentToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? visibility = null,Object? skills = null,}) {
  return _then(AgentToUpdate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentToUpdate].
extension AgentToUpdatePatterns on AgentToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _AgentToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _AgentToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentToUpdate() when $default != null:
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)  $default,) {final _that = this;
switch (_that) {
case _AgentToUpdate():
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String content,  bool isEnabled,  AgentVisibility visibility,  List<AgentSkillRef> skills)?  $default,) {final _that = this;
switch (_that) {
case _AgentToUpdate() when $default != null:
return $default(_that.name,_that.description,_that.content,_that.isEnabled,_that.visibility,_that.skills);case _:
  return null;

}
}

}

/// @nodoc


class _AgentToUpdate extends AgentToUpdate {
  const _AgentToUpdate({required this.name, required this.description, required this.content, this.isEnabled = true, this.visibility = AgentVisibility.both,  List<AgentSkillRef> skills = const []}): _skills = skills,super._();
  

@override final  String name;
@override final  String description;
@override final  String content;
@override@JsonKey() final  bool isEnabled;
@override@JsonKey() final  AgentVisibility visibility;
 final  List<AgentSkillRef> _skills;
@override@JsonKey() List<AgentSkillRef> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}


/// Create a copy of AgentToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentToUpdateCopyWith<_AgentToUpdate> get copyWith => __$AgentToUpdateCopyWithImpl<_AgentToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentToUpdate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other._skills, _skills));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,content,isEnabled,visibility,const DeepCollectionEquality().hash(_skills));

@override
String toString() {
  return 'AgentToUpdate(name: $name, description: $description, content: $content, isEnabled: $isEnabled, visibility: $visibility, skills: $skills)';
}


}

/// @nodoc
abstract mixin class _$AgentToUpdateCopyWith<$Res> implements $AgentToUpdateCopyWith<$Res> {
  factory _$AgentToUpdateCopyWith(_AgentToUpdate value, $Res Function(_AgentToUpdate) _then) = __$AgentToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String content, bool isEnabled, AgentVisibility visibility, List<AgentSkillRef> skills
});




}
/// @nodoc
class __$AgentToUpdateCopyWithImpl<$Res>
    implements _$AgentToUpdateCopyWith<$Res> {
  __$AgentToUpdateCopyWithImpl(this._self, this._then);

  final _AgentToUpdate _self;
  final $Res Function(_AgentToUpdate) _then;

/// Create a copy of AgentToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? content = null,Object? isEnabled = null,Object? visibility = null,Object? skills = null,}) {
  return _then(_AgentToUpdate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as AgentVisibility,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkillRef>,
  ));
}


}

/// @nodoc
mixin _$AgentSkillRef {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentSkillRef);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AgentSkillRef()';
}


}

/// @nodoc
class $AgentSkillRefCopyWith<$Res>  {
$AgentSkillRefCopyWith(AgentSkillRef _, $Res Function(AgentSkillRef) __);
}


/// Adds pattern-matching-related methods to [AgentSkillRef].
extension AgentSkillRefPatterns on AgentSkillRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserAgentSkillRef value)?  user,TResult Function( AppAgentSkillRef value)?  app,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserAgentSkillRef() when user != null:
return user(_that);case AppAgentSkillRef() when app != null:
return app(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserAgentSkillRef value)  user,required TResult Function( AppAgentSkillRef value)  app,}){
final _that = this;
switch (_that) {
case UserAgentSkillRef():
return user(_that);case AppAgentSkillRef():
return app(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserAgentSkillRef value)?  user,TResult? Function( AppAgentSkillRef value)?  app,}){
final _that = this;
switch (_that) {
case UserAgentSkillRef() when user != null:
return user(_that);case AppAgentSkillRef() when app != null:
return app(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String skillId)?  user,TResult Function( String identifier)?  app,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserAgentSkillRef() when user != null:
return user(_that.skillId);case AppAgentSkillRef() when app != null:
return app(_that.identifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String skillId)  user,required TResult Function( String identifier)  app,}) {final _that = this;
switch (_that) {
case UserAgentSkillRef():
return user(_that.skillId);case AppAgentSkillRef():
return app(_that.identifier);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String skillId)?  user,TResult? Function( String identifier)?  app,}) {final _that = this;
switch (_that) {
case UserAgentSkillRef() when user != null:
return user(_that.skillId);case AppAgentSkillRef() when app != null:
return app(_that.identifier);case _:
  return null;

}
}

}

/// @nodoc


class UserAgentSkillRef implements AgentSkillRef {
  const UserAgentSkillRef(this.skillId);
  

 final  String skillId;

/// Create a copy of AgentSkillRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserAgentSkillRefCopyWith<UserAgentSkillRef> get copyWith => _$UserAgentSkillRefCopyWithImpl<UserAgentSkillRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserAgentSkillRef&&(identical(other.skillId, skillId) || other.skillId == skillId));
}


@override
int get hashCode => Object.hash(runtimeType,skillId);

@override
String toString() {
  return 'AgentSkillRef.user(skillId: $skillId)';
}


}

/// @nodoc
abstract mixin class $UserAgentSkillRefCopyWith<$Res> implements $AgentSkillRefCopyWith<$Res> {
  factory $UserAgentSkillRefCopyWith(UserAgentSkillRef value, $Res Function(UserAgentSkillRef) _then) = _$UserAgentSkillRefCopyWithImpl;
@useResult
$Res call({
 String skillId
});




}
/// @nodoc
class _$UserAgentSkillRefCopyWithImpl<$Res>
    implements $UserAgentSkillRefCopyWith<$Res> {
  _$UserAgentSkillRefCopyWithImpl(this._self, this._then);

  final UserAgentSkillRef _self;
  final $Res Function(UserAgentSkillRef) _then;

/// Create a copy of AgentSkillRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skillId = null,}) {
  return _then(UserAgentSkillRef(
null == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppAgentSkillRef implements AgentSkillRef {
  const AppAgentSkillRef(this.identifier);
  

 final  String identifier;

/// Create a copy of AgentSkillRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppAgentSkillRefCopyWith<AppAgentSkillRef> get copyWith => _$AppAgentSkillRefCopyWithImpl<AppAgentSkillRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppAgentSkillRef&&(identical(other.identifier, identifier) || other.identifier == identifier));
}


@override
int get hashCode => Object.hash(runtimeType,identifier);

@override
String toString() {
  return 'AgentSkillRef.app(identifier: $identifier)';
}


}

/// @nodoc
abstract mixin class $AppAgentSkillRefCopyWith<$Res> implements $AgentSkillRefCopyWith<$Res> {
  factory $AppAgentSkillRefCopyWith(AppAgentSkillRef value, $Res Function(AppAgentSkillRef) _then) = _$AppAgentSkillRefCopyWithImpl;
@useResult
$Res call({
 String identifier
});




}
/// @nodoc
class _$AppAgentSkillRefCopyWithImpl<$Res>
    implements $AppAgentSkillRefCopyWith<$Res> {
  _$AppAgentSkillRefCopyWithImpl(this._self, this._then);

  final AppAgentSkillRef _self;
  final $Res Function(AppAgentSkillRef) _then;

/// Create a copy of AgentSkillRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? identifier = null,}) {
  return _then(AppAgentSkillRef(
null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
