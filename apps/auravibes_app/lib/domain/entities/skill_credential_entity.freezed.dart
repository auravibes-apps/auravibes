// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_credential_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillCredentialEntity {

 String get id; String get workspaceId; String get credentialDefinitionId; String get name; Map<String, String> get attributes; bool get isEnabled; DateTime get createdAt; DateTime get updatedAt; String? get keySuffix;
/// Create a copy of SkillCredentialEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialEntityCopyWith<SkillCredentialEntity> get copyWith => _$SkillCredentialEntityCopyWithImpl<SkillCredentialEntity>(this as SkillCredentialEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.attributes, attributes)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,credentialDefinitionId,name,const DeepCollectionEquality().hash(attributes),isEnabled,createdAt,updatedAt,keySuffix);

@override
String toString() {
  return 'SkillCredentialEntity(id: $id, workspaceId: $workspaceId, credentialDefinitionId: $credentialDefinitionId, name: $name, attributes: $attributes, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialEntityCopyWith<$Res>  {
  factory $SkillCredentialEntityCopyWith(SkillCredentialEntity value, $Res Function(SkillCredentialEntity) _then) = _$SkillCredentialEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String credentialDefinitionId, String name, Map<String, String> attributes, bool isEnabled, DateTime createdAt, DateTime updatedAt, String? keySuffix
});




}
/// @nodoc
class _$SkillCredentialEntityCopyWithImpl<$Res>
    implements $SkillCredentialEntityCopyWith<$Res> {
  _$SkillCredentialEntityCopyWithImpl(this._self, this._then);

  final SkillCredentialEntity _self;
  final $Res Function(SkillCredentialEntity) _then;

/// Create a copy of SkillCredentialEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? credentialDefinitionId = null,Object? name = null,Object? attributes = null,Object? isEnabled = null,Object? createdAt = null,Object? updatedAt = null,Object? keySuffix = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialEntity].
extension SkillCredentialEntityPatterns on SkillCredentialEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> attributes,  bool isEnabled,  DateTime createdAt,  DateTime updatedAt,  String? keySuffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.attributes,_that.isEnabled,_that.createdAt,_that.updatedAt,_that.keySuffix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> attributes,  bool isEnabled,  DateTime createdAt,  DateTime updatedAt,  String? keySuffix)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialEntity():
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.attributes,_that.isEnabled,_that.createdAt,_that.updatedAt,_that.keySuffix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> attributes,  bool isEnabled,  DateTime createdAt,  DateTime updatedAt,  String? keySuffix)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.attributes,_that.isEnabled,_that.createdAt,_that.updatedAt,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialEntity extends SkillCredentialEntity {
  const _SkillCredentialEntity({required this.id, required this.workspaceId, required this.credentialDefinitionId, required this.name, required final  Map<String, String> attributes, required this.isEnabled, required this.createdAt, required this.updatedAt, this.keySuffix}): _attributes = attributes,super._();
  

@override final  String id;
@override final  String workspaceId;
@override final  String credentialDefinitionId;
@override final  String name;
 final  Map<String, String> _attributes;
@override Map<String, String> get attributes {
  if (_attributes is EqualUnmodifiableMapView) return _attributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attributes);
}

@override final  bool isEnabled;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? keySuffix;

/// Create a copy of SkillCredentialEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialEntityCopyWith<_SkillCredentialEntity> get copyWith => __$SkillCredentialEntityCopyWithImpl<_SkillCredentialEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._attributes, _attributes)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,credentialDefinitionId,name,const DeepCollectionEquality().hash(_attributes),isEnabled,createdAt,updatedAt,keySuffix);

@override
String toString() {
  return 'SkillCredentialEntity(id: $id, workspaceId: $workspaceId, credentialDefinitionId: $credentialDefinitionId, name: $name, attributes: $attributes, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialEntityCopyWith<$Res> implements $SkillCredentialEntityCopyWith<$Res> {
  factory _$SkillCredentialEntityCopyWith(_SkillCredentialEntity value, $Res Function(_SkillCredentialEntity) _then) = __$SkillCredentialEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String credentialDefinitionId, String name, Map<String, String> attributes, bool isEnabled, DateTime createdAt, DateTime updatedAt, String? keySuffix
});




}
/// @nodoc
class __$SkillCredentialEntityCopyWithImpl<$Res>
    implements _$SkillCredentialEntityCopyWith<$Res> {
  __$SkillCredentialEntityCopyWithImpl(this._self, this._then);

  final _SkillCredentialEntity _self;
  final $Res Function(_SkillCredentialEntity) _then;

/// Create a copy of SkillCredentialEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? credentialDefinitionId = null,Object? name = null,Object? attributes = null,Object? isEnabled = null,Object? createdAt = null,Object? updatedAt = null,Object? keySuffix = freezed,}) {
  return _then(_SkillCredentialEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self._attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialToCreate {

 String get credentialDefinitionId; String get name; Map<String, String> get attributes;
/// Create a copy of SkillCredentialToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialToCreateCopyWith<SkillCredentialToCreate> get copyWith => _$SkillCredentialToCreateCopyWithImpl<SkillCredentialToCreate>(this as SkillCredentialToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialToCreate&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.attributes, attributes));
}


@override
int get hashCode => Object.hash(runtimeType,credentialDefinitionId,name,const DeepCollectionEquality().hash(attributes));

@override
String toString() {
  return 'SkillCredentialToCreate(credentialDefinitionId: $credentialDefinitionId, name: $name, attributes: $attributes)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialToCreateCopyWith<$Res>  {
  factory $SkillCredentialToCreateCopyWith(SkillCredentialToCreate value, $Res Function(SkillCredentialToCreate) _then) = _$SkillCredentialToCreateCopyWithImpl;
@useResult
$Res call({
 String credentialDefinitionId, String name, Map<String, String> attributes
});




}
/// @nodoc
class _$SkillCredentialToCreateCopyWithImpl<$Res>
    implements $SkillCredentialToCreateCopyWith<$Res> {
  _$SkillCredentialToCreateCopyWithImpl(this._self, this._then);

  final SkillCredentialToCreate _self;
  final $Res Function(SkillCredentialToCreate) _then;

/// Create a copy of SkillCredentialToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? credentialDefinitionId = null,Object? name = null,Object? attributes = null,}) {
  return _then(_self.copyWith(
credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialToCreate].
extension SkillCredentialToCreatePatterns on SkillCredentialToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialToCreate value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String credentialDefinitionId,  String name,  Map<String, String> attributes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialToCreate() when $default != null:
return $default(_that.credentialDefinitionId,_that.name,_that.attributes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String credentialDefinitionId,  String name,  Map<String, String> attributes)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialToCreate():
return $default(_that.credentialDefinitionId,_that.name,_that.attributes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String credentialDefinitionId,  String name,  Map<String, String> attributes)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialToCreate() when $default != null:
return $default(_that.credentialDefinitionId,_that.name,_that.attributes);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialToCreate extends SkillCredentialToCreate {
  const _SkillCredentialToCreate({required this.credentialDefinitionId, required this.name, required final  Map<String, String> attributes}): _attributes = attributes,super._();
  

@override final  String credentialDefinitionId;
@override final  String name;
 final  Map<String, String> _attributes;
@override Map<String, String> get attributes {
  if (_attributes is EqualUnmodifiableMapView) return _attributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attributes);
}


/// Create a copy of SkillCredentialToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialToCreateCopyWith<_SkillCredentialToCreate> get copyWith => __$SkillCredentialToCreateCopyWithImpl<_SkillCredentialToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialToCreate&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._attributes, _attributes));
}


@override
int get hashCode => Object.hash(runtimeType,credentialDefinitionId,name,const DeepCollectionEquality().hash(_attributes));

@override
String toString() {
  return 'SkillCredentialToCreate(credentialDefinitionId: $credentialDefinitionId, name: $name, attributes: $attributes)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialToCreateCopyWith<$Res> implements $SkillCredentialToCreateCopyWith<$Res> {
  factory _$SkillCredentialToCreateCopyWith(_SkillCredentialToCreate value, $Res Function(_SkillCredentialToCreate) _then) = __$SkillCredentialToCreateCopyWithImpl;
@override @useResult
$Res call({
 String credentialDefinitionId, String name, Map<String, String> attributes
});




}
/// @nodoc
class __$SkillCredentialToCreateCopyWithImpl<$Res>
    implements _$SkillCredentialToCreateCopyWith<$Res> {
  __$SkillCredentialToCreateCopyWithImpl(this._self, this._then);

  final _SkillCredentialToCreate _self;
  final $Res Function(_SkillCredentialToCreate) _then;

/// Create a copy of SkillCredentialToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? credentialDefinitionId = null,Object? name = null,Object? attributes = null,}) {
  return _then(_SkillCredentialToCreate(
credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self._attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialSecretState {

 bool get hasValue; String? get keySuffix;
/// Create a copy of SkillCredentialSecretState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialSecretStateCopyWith<SkillCredentialSecretState> get copyWith => _$SkillCredentialSecretStateCopyWithImpl<SkillCredentialSecretState>(this as SkillCredentialSecretState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialSecretState&&(identical(other.hasValue, hasValue) || other.hasValue == hasValue)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,hasValue,keySuffix);

@override
String toString() {
  return 'SkillCredentialSecretState(hasValue: $hasValue, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialSecretStateCopyWith<$Res>  {
  factory $SkillCredentialSecretStateCopyWith(SkillCredentialSecretState value, $Res Function(SkillCredentialSecretState) _then) = _$SkillCredentialSecretStateCopyWithImpl;
@useResult
$Res call({
 bool hasValue, String? keySuffix
});




}
/// @nodoc
class _$SkillCredentialSecretStateCopyWithImpl<$Res>
    implements $SkillCredentialSecretStateCopyWith<$Res> {
  _$SkillCredentialSecretStateCopyWithImpl(this._self, this._then);

  final SkillCredentialSecretState _self;
  final $Res Function(SkillCredentialSecretState) _then;

/// Create a copy of SkillCredentialSecretState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasValue = null,Object? keySuffix = freezed,}) {
  return _then(_self.copyWith(
hasValue: null == hasValue ? _self.hasValue : hasValue // ignore: cast_nullable_to_non_nullable
as bool,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialSecretState].
extension SkillCredentialSecretStatePatterns on SkillCredentialSecretState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialSecretState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialSecretState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialSecretState value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialSecretState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialSecretState value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialSecretState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasValue,  String? keySuffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialSecretState() when $default != null:
return $default(_that.hasValue,_that.keySuffix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasValue,  String? keySuffix)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialSecretState():
return $default(_that.hasValue,_that.keySuffix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasValue,  String? keySuffix)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialSecretState() when $default != null:
return $default(_that.hasValue,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialSecretState extends SkillCredentialSecretState {
  const _SkillCredentialSecretState({required this.hasValue, this.keySuffix}): super._();
  

@override final  bool hasValue;
@override final  String? keySuffix;

/// Create a copy of SkillCredentialSecretState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialSecretStateCopyWith<_SkillCredentialSecretState> get copyWith => __$SkillCredentialSecretStateCopyWithImpl<_SkillCredentialSecretState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialSecretState&&(identical(other.hasValue, hasValue) || other.hasValue == hasValue)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,hasValue,keySuffix);

@override
String toString() {
  return 'SkillCredentialSecretState(hasValue: $hasValue, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialSecretStateCopyWith<$Res> implements $SkillCredentialSecretStateCopyWith<$Res> {
  factory _$SkillCredentialSecretStateCopyWith(_SkillCredentialSecretState value, $Res Function(_SkillCredentialSecretState) _then) = __$SkillCredentialSecretStateCopyWithImpl;
@override @useResult
$Res call({
 bool hasValue, String? keySuffix
});




}
/// @nodoc
class __$SkillCredentialSecretStateCopyWithImpl<$Res>
    implements _$SkillCredentialSecretStateCopyWith<$Res> {
  __$SkillCredentialSecretStateCopyWithImpl(this._self, this._then);

  final _SkillCredentialSecretState _self;
  final $Res Function(_SkillCredentialSecretState) _then;

/// Create a copy of SkillCredentialSecretState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasValue = null,Object? keySuffix = freezed,}) {
  return _then(_SkillCredentialSecretState(
hasValue: null == hasValue ? _self.hasValue : hasValue // ignore: cast_nullable_to_non_nullable
as bool,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialForEdit {

 String get id; String get workspaceId; String get credentialDefinitionId; String get name; Map<String, String> get nonSecretAttributes; Map<String, SkillCredentialSecretState> get secretAttributes; bool get isEnabled; String? get keySuffix;
/// Create a copy of SkillCredentialForEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialForEditCopyWith<SkillCredentialForEdit> get copyWith => _$SkillCredentialForEditCopyWithImpl<SkillCredentialForEdit>(this as SkillCredentialForEdit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialForEdit&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.nonSecretAttributes, nonSecretAttributes)&&const DeepCollectionEquality().equals(other.secretAttributes, secretAttributes)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,credentialDefinitionId,name,const DeepCollectionEquality().hash(nonSecretAttributes),const DeepCollectionEquality().hash(secretAttributes),isEnabled,keySuffix);

@override
String toString() {
  return 'SkillCredentialForEdit(id: $id, workspaceId: $workspaceId, credentialDefinitionId: $credentialDefinitionId, name: $name, nonSecretAttributes: $nonSecretAttributes, secretAttributes: $secretAttributes, isEnabled: $isEnabled, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialForEditCopyWith<$Res>  {
  factory $SkillCredentialForEditCopyWith(SkillCredentialForEdit value, $Res Function(SkillCredentialForEdit) _then) = _$SkillCredentialForEditCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String credentialDefinitionId, String name, Map<String, String> nonSecretAttributes, Map<String, SkillCredentialSecretState> secretAttributes, bool isEnabled, String? keySuffix
});




}
/// @nodoc
class _$SkillCredentialForEditCopyWithImpl<$Res>
    implements $SkillCredentialForEditCopyWith<$Res> {
  _$SkillCredentialForEditCopyWithImpl(this._self, this._then);

  final SkillCredentialForEdit _self;
  final $Res Function(SkillCredentialForEdit) _then;

/// Create a copy of SkillCredentialForEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? credentialDefinitionId = null,Object? name = null,Object? nonSecretAttributes = null,Object? secretAttributes = null,Object? isEnabled = null,Object? keySuffix = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nonSecretAttributes: null == nonSecretAttributes ? _self.nonSecretAttributes : nonSecretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,secretAttributes: null == secretAttributes ? _self.secretAttributes : secretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, SkillCredentialSecretState>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialForEdit].
extension SkillCredentialForEditPatterns on SkillCredentialForEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialForEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialForEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialForEdit value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialForEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialForEdit value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialForEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> nonSecretAttributes,  Map<String, SkillCredentialSecretState> secretAttributes,  bool isEnabled,  String? keySuffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialForEdit() when $default != null:
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.isEnabled,_that.keySuffix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> nonSecretAttributes,  Map<String, SkillCredentialSecretState> secretAttributes,  bool isEnabled,  String? keySuffix)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialForEdit():
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.isEnabled,_that.keySuffix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String credentialDefinitionId,  String name,  Map<String, String> nonSecretAttributes,  Map<String, SkillCredentialSecretState> secretAttributes,  bool isEnabled,  String? keySuffix)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialForEdit() when $default != null:
return $default(_that.id,_that.workspaceId,_that.credentialDefinitionId,_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.isEnabled,_that.keySuffix);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialForEdit extends SkillCredentialForEdit {
  const _SkillCredentialForEdit({required this.id, required this.workspaceId, required this.credentialDefinitionId, required this.name, required final  Map<String, String> nonSecretAttributes, required final  Map<String, SkillCredentialSecretState> secretAttributes, required this.isEnabled, this.keySuffix}): _nonSecretAttributes = nonSecretAttributes,_secretAttributes = secretAttributes,super._();
  

@override final  String id;
@override final  String workspaceId;
@override final  String credentialDefinitionId;
@override final  String name;
 final  Map<String, String> _nonSecretAttributes;
@override Map<String, String> get nonSecretAttributes {
  if (_nonSecretAttributes is EqualUnmodifiableMapView) return _nonSecretAttributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nonSecretAttributes);
}

 final  Map<String, SkillCredentialSecretState> _secretAttributes;
@override Map<String, SkillCredentialSecretState> get secretAttributes {
  if (_secretAttributes is EqualUnmodifiableMapView) return _secretAttributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_secretAttributes);
}

@override final  bool isEnabled;
@override final  String? keySuffix;

/// Create a copy of SkillCredentialForEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialForEditCopyWith<_SkillCredentialForEdit> get copyWith => __$SkillCredentialForEditCopyWithImpl<_SkillCredentialForEdit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialForEdit&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.credentialDefinitionId, credentialDefinitionId) || other.credentialDefinitionId == credentialDefinitionId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._nonSecretAttributes, _nonSecretAttributes)&&const DeepCollectionEquality().equals(other._secretAttributes, _secretAttributes)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.keySuffix, keySuffix) || other.keySuffix == keySuffix));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,credentialDefinitionId,name,const DeepCollectionEquality().hash(_nonSecretAttributes),const DeepCollectionEquality().hash(_secretAttributes),isEnabled,keySuffix);

@override
String toString() {
  return 'SkillCredentialForEdit(id: $id, workspaceId: $workspaceId, credentialDefinitionId: $credentialDefinitionId, name: $name, nonSecretAttributes: $nonSecretAttributes, secretAttributes: $secretAttributes, isEnabled: $isEnabled, keySuffix: $keySuffix)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialForEditCopyWith<$Res> implements $SkillCredentialForEditCopyWith<$Res> {
  factory _$SkillCredentialForEditCopyWith(_SkillCredentialForEdit value, $Res Function(_SkillCredentialForEdit) _then) = __$SkillCredentialForEditCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String credentialDefinitionId, String name, Map<String, String> nonSecretAttributes, Map<String, SkillCredentialSecretState> secretAttributes, bool isEnabled, String? keySuffix
});




}
/// @nodoc
class __$SkillCredentialForEditCopyWithImpl<$Res>
    implements _$SkillCredentialForEditCopyWith<$Res> {
  __$SkillCredentialForEditCopyWithImpl(this._self, this._then);

  final _SkillCredentialForEdit _self;
  final $Res Function(_SkillCredentialForEdit) _then;

/// Create a copy of SkillCredentialForEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? credentialDefinitionId = null,Object? name = null,Object? nonSecretAttributes = null,Object? secretAttributes = null,Object? isEnabled = null,Object? keySuffix = freezed,}) {
  return _then(_SkillCredentialForEdit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,credentialDefinitionId: null == credentialDefinitionId ? _self.credentialDefinitionId : credentialDefinitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nonSecretAttributes: null == nonSecretAttributes ? _self._nonSecretAttributes : nonSecretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,secretAttributes: null == secretAttributes ? _self._secretAttributes : secretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, SkillCredentialSecretState>,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,keySuffix: freezed == keySuffix ? _self.keySuffix : keySuffix // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SkillCredentialToUpdate {

 String? get name; Map<String, String> get nonSecretAttributes; Map<String, String> get secretAttributes; Set<String> get clearSecretAttributeNames;
/// Create a copy of SkillCredentialToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCredentialToUpdateCopyWith<SkillCredentialToUpdate> get copyWith => _$SkillCredentialToUpdateCopyWithImpl<SkillCredentialToUpdate>(this as SkillCredentialToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCredentialToUpdate&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.nonSecretAttributes, nonSecretAttributes)&&const DeepCollectionEquality().equals(other.secretAttributes, secretAttributes)&&const DeepCollectionEquality().equals(other.clearSecretAttributeNames, clearSecretAttributeNames));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(nonSecretAttributes),const DeepCollectionEquality().hash(secretAttributes),const DeepCollectionEquality().hash(clearSecretAttributeNames));

@override
String toString() {
  return 'SkillCredentialToUpdate(name: $name, nonSecretAttributes: $nonSecretAttributes, secretAttributes: $secretAttributes, clearSecretAttributeNames: $clearSecretAttributeNames)';
}


}

/// @nodoc
abstract mixin class $SkillCredentialToUpdateCopyWith<$Res>  {
  factory $SkillCredentialToUpdateCopyWith(SkillCredentialToUpdate value, $Res Function(SkillCredentialToUpdate) _then) = _$SkillCredentialToUpdateCopyWithImpl;
@useResult
$Res call({
 String? name, Map<String, String> nonSecretAttributes, Map<String, String> secretAttributes, Set<String> clearSecretAttributeNames
});




}
/// @nodoc
class _$SkillCredentialToUpdateCopyWithImpl<$Res>
    implements $SkillCredentialToUpdateCopyWith<$Res> {
  _$SkillCredentialToUpdateCopyWithImpl(this._self, this._then);

  final SkillCredentialToUpdate _self;
  final $Res Function(SkillCredentialToUpdate) _then;

/// Create a copy of SkillCredentialToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? nonSecretAttributes = null,Object? secretAttributes = null,Object? clearSecretAttributeNames = null,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nonSecretAttributes: null == nonSecretAttributes ? _self.nonSecretAttributes : nonSecretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,secretAttributes: null == secretAttributes ? _self.secretAttributes : secretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,clearSecretAttributeNames: null == clearSecretAttributeNames ? _self.clearSecretAttributeNames : clearSecretAttributeNames // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCredentialToUpdate].
extension SkillCredentialToUpdatePatterns on SkillCredentialToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCredentialToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCredentialToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCredentialToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCredentialToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCredentialToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  Map<String, String> nonSecretAttributes,  Map<String, String> secretAttributes,  Set<String> clearSecretAttributeNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCredentialToUpdate() when $default != null:
return $default(_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.clearSecretAttributeNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  Map<String, String> nonSecretAttributes,  Map<String, String> secretAttributes,  Set<String> clearSecretAttributeNames)  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialToUpdate():
return $default(_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.clearSecretAttributeNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  Map<String, String> nonSecretAttributes,  Map<String, String> secretAttributes,  Set<String> clearSecretAttributeNames)?  $default,) {final _that = this;
switch (_that) {
case _SkillCredentialToUpdate() when $default != null:
return $default(_that.name,_that.nonSecretAttributes,_that.secretAttributes,_that.clearSecretAttributeNames);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCredentialToUpdate extends SkillCredentialToUpdate {
  const _SkillCredentialToUpdate({this.name, final  Map<String, String> nonSecretAttributes = const {}, final  Map<String, String> secretAttributes = const {}, final  Set<String> clearSecretAttributeNames = const {}}): _nonSecretAttributes = nonSecretAttributes,_secretAttributes = secretAttributes,_clearSecretAttributeNames = clearSecretAttributeNames,super._();
  

@override final  String? name;
 final  Map<String, String> _nonSecretAttributes;
@override@JsonKey() Map<String, String> get nonSecretAttributes {
  if (_nonSecretAttributes is EqualUnmodifiableMapView) return _nonSecretAttributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nonSecretAttributes);
}

 final  Map<String, String> _secretAttributes;
@override@JsonKey() Map<String, String> get secretAttributes {
  if (_secretAttributes is EqualUnmodifiableMapView) return _secretAttributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_secretAttributes);
}

 final  Set<String> _clearSecretAttributeNames;
@override@JsonKey() Set<String> get clearSecretAttributeNames {
  if (_clearSecretAttributeNames is EqualUnmodifiableSetView) return _clearSecretAttributeNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_clearSecretAttributeNames);
}


/// Create a copy of SkillCredentialToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCredentialToUpdateCopyWith<_SkillCredentialToUpdate> get copyWith => __$SkillCredentialToUpdateCopyWithImpl<_SkillCredentialToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCredentialToUpdate&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._nonSecretAttributes, _nonSecretAttributes)&&const DeepCollectionEquality().equals(other._secretAttributes, _secretAttributes)&&const DeepCollectionEquality().equals(other._clearSecretAttributeNames, _clearSecretAttributeNames));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_nonSecretAttributes),const DeepCollectionEquality().hash(_secretAttributes),const DeepCollectionEquality().hash(_clearSecretAttributeNames));

@override
String toString() {
  return 'SkillCredentialToUpdate(name: $name, nonSecretAttributes: $nonSecretAttributes, secretAttributes: $secretAttributes, clearSecretAttributeNames: $clearSecretAttributeNames)';
}


}

/// @nodoc
abstract mixin class _$SkillCredentialToUpdateCopyWith<$Res> implements $SkillCredentialToUpdateCopyWith<$Res> {
  factory _$SkillCredentialToUpdateCopyWith(_SkillCredentialToUpdate value, $Res Function(_SkillCredentialToUpdate) _then) = __$SkillCredentialToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? name, Map<String, String> nonSecretAttributes, Map<String, String> secretAttributes, Set<String> clearSecretAttributeNames
});




}
/// @nodoc
class __$SkillCredentialToUpdateCopyWithImpl<$Res>
    implements _$SkillCredentialToUpdateCopyWith<$Res> {
  __$SkillCredentialToUpdateCopyWithImpl(this._self, this._then);

  final _SkillCredentialToUpdate _self;
  final $Res Function(_SkillCredentialToUpdate) _then;

/// Create a copy of SkillCredentialToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? nonSecretAttributes = null,Object? secretAttributes = null,Object? clearSecretAttributeNames = null,}) {
  return _then(_SkillCredentialToUpdate(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nonSecretAttributes: null == nonSecretAttributes ? _self._nonSecretAttributes : nonSecretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,secretAttributes: null == secretAttributes ? _self._secretAttributes : secretAttributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,clearSecretAttributeNames: null == clearSecretAttributeNames ? _self._clearSecretAttributeNames : clearSecretAttributeNames // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
