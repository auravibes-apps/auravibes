// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_skill_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationSkillEntity {

 String get id; String get conversationId; bool get isLoaded; DateTime get createdAt; DateTime get updatedAt; String? get workspaceSkillId; String? get appSkillIdentifier;
/// Create a copy of ConversationSkillEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationSkillEntityCopyWith<ConversationSkillEntity> get copyWith => _$ConversationSkillEntityCopyWithImpl<ConversationSkillEntity>(this as ConversationSkillEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationSkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.isLoaded, isLoaded) || other.isLoaded == isLoaded)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceSkillId, workspaceSkillId) || other.workspaceSkillId == workspaceSkillId)&&(identical(other.appSkillIdentifier, appSkillIdentifier) || other.appSkillIdentifier == appSkillIdentifier));
}


@override
int get hashCode => Object.hash(runtimeType,id,conversationId,isLoaded,createdAt,updatedAt,workspaceSkillId,appSkillIdentifier);

@override
String toString() {
  return 'ConversationSkillEntity(id: $id, conversationId: $conversationId, isLoaded: $isLoaded, createdAt: $createdAt, updatedAt: $updatedAt, workspaceSkillId: $workspaceSkillId, appSkillIdentifier: $appSkillIdentifier)';
}


}

/// @nodoc
abstract mixin class $ConversationSkillEntityCopyWith<$Res>  {
  factory $ConversationSkillEntityCopyWith(ConversationSkillEntity value, $Res Function(ConversationSkillEntity) _then) = _$ConversationSkillEntityCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, bool isLoaded, DateTime createdAt, DateTime updatedAt, String? workspaceSkillId, String? appSkillIdentifier
});




}
/// @nodoc
class _$ConversationSkillEntityCopyWithImpl<$Res>
    implements $ConversationSkillEntityCopyWith<$Res> {
  _$ConversationSkillEntityCopyWithImpl(this._self, this._then);

  final ConversationSkillEntity _self;
  final $Res Function(ConversationSkillEntity) _then;

/// Create a copy of ConversationSkillEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? isLoaded = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceSkillId = freezed,Object? appSkillIdentifier = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,isLoaded: null == isLoaded ? _self.isLoaded : isLoaded // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceSkillId: freezed == workspaceSkillId ? _self.workspaceSkillId : workspaceSkillId // ignore: cast_nullable_to_non_nullable
as String?,appSkillIdentifier: freezed == appSkillIdentifier ? _self.appSkillIdentifier : appSkillIdentifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationSkillEntity].
extension ConversationSkillEntityPatterns on ConversationSkillEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationSkillEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationSkillEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationSkillEntity value)  $default,){
final _that = this;
switch (_that) {
case _ConversationSkillEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationSkillEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationSkillEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  bool isLoaded,  DateTime createdAt,  DateTime updatedAt,  String? workspaceSkillId,  String? appSkillIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationSkillEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.isLoaded,_that.createdAt,_that.updatedAt,_that.workspaceSkillId,_that.appSkillIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  bool isLoaded,  DateTime createdAt,  DateTime updatedAt,  String? workspaceSkillId,  String? appSkillIdentifier)  $default,) {final _that = this;
switch (_that) {
case _ConversationSkillEntity():
return $default(_that.id,_that.conversationId,_that.isLoaded,_that.createdAt,_that.updatedAt,_that.workspaceSkillId,_that.appSkillIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  bool isLoaded,  DateTime createdAt,  DateTime updatedAt,  String? workspaceSkillId,  String? appSkillIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _ConversationSkillEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.isLoaded,_that.createdAt,_that.updatedAt,_that.workspaceSkillId,_that.appSkillIdentifier);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationSkillEntity extends ConversationSkillEntity {
  const _ConversationSkillEntity({required this.id, required this.conversationId, required this.isLoaded, required this.createdAt, required this.updatedAt, this.workspaceSkillId, this.appSkillIdentifier}): super._();
  

@override final  String id;
@override final  String conversationId;
@override final  bool isLoaded;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? workspaceSkillId;
@override final  String? appSkillIdentifier;

/// Create a copy of ConversationSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationSkillEntityCopyWith<_ConversationSkillEntity> get copyWith => __$ConversationSkillEntityCopyWithImpl<_ConversationSkillEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationSkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.isLoaded, isLoaded) || other.isLoaded == isLoaded)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.workspaceSkillId, workspaceSkillId) || other.workspaceSkillId == workspaceSkillId)&&(identical(other.appSkillIdentifier, appSkillIdentifier) || other.appSkillIdentifier == appSkillIdentifier));
}


@override
int get hashCode => Object.hash(runtimeType,id,conversationId,isLoaded,createdAt,updatedAt,workspaceSkillId,appSkillIdentifier);

@override
String toString() {
  return 'ConversationSkillEntity(id: $id, conversationId: $conversationId, isLoaded: $isLoaded, createdAt: $createdAt, updatedAt: $updatedAt, workspaceSkillId: $workspaceSkillId, appSkillIdentifier: $appSkillIdentifier)';
}


}

/// @nodoc
abstract mixin class _$ConversationSkillEntityCopyWith<$Res> implements $ConversationSkillEntityCopyWith<$Res> {
  factory _$ConversationSkillEntityCopyWith(_ConversationSkillEntity value, $Res Function(_ConversationSkillEntity) _then) = __$ConversationSkillEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, bool isLoaded, DateTime createdAt, DateTime updatedAt, String? workspaceSkillId, String? appSkillIdentifier
});




}
/// @nodoc
class __$ConversationSkillEntityCopyWithImpl<$Res>
    implements _$ConversationSkillEntityCopyWith<$Res> {
  __$ConversationSkillEntityCopyWithImpl(this._self, this._then);

  final _ConversationSkillEntity _self;
  final $Res Function(_ConversationSkillEntity) _then;

/// Create a copy of ConversationSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? isLoaded = null,Object? createdAt = null,Object? updatedAt = null,Object? workspaceSkillId = freezed,Object? appSkillIdentifier = freezed,}) {
  return _then(_ConversationSkillEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,isLoaded: null == isLoaded ? _self.isLoaded : isLoaded // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceSkillId: freezed == workspaceSkillId ? _self.workspaceSkillId : workspaceSkillId // ignore: cast_nullable_to_non_nullable
as String?,appSkillIdentifier: freezed == appSkillIdentifier ? _self.appSkillIdentifier : appSkillIdentifier // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
