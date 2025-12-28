// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationEntity {

/// Unique identifier for the conversation
 String get id;/// Human-readable title of the conversation
 String get title;/// ID of the workspace this conversation belongs to
 String get workspaceId;/// Whether this conversation is pinned
 bool get isPinned;/// Timestamp when the conversation was created
 DateTime get createdAt;/// Timestamp when the conversation was last updated
 DateTime get updatedAt;/// ID of the AI model used for this conversation
 String? get modelId;
/// Create a copy of ConversationEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationEntityCopyWith<ConversationEntity> get copyWith => _$ConversationEntityCopyWithImpl<ConversationEntity>(this as ConversationEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,workspaceId,isPinned,createdAt,updatedAt,modelId);

@override
String toString() {
  return 'ConversationEntity(id: $id, title: $title, workspaceId: $workspaceId, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $ConversationEntityCopyWith<$Res>  {
  factory $ConversationEntityCopyWith(ConversationEntity value, $Res Function(ConversationEntity) _then) = _$ConversationEntityCopyWithImpl;
@useResult
$Res call({
 String id, String title, String workspaceId, bool isPinned, DateTime createdAt, DateTime updatedAt, String? modelId
});




}
/// @nodoc
class _$ConversationEntityCopyWithImpl<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  _$ConversationEntityCopyWithImpl(this._self, this._then);

  final ConversationEntity _self;
  final $Res Function(ConversationEntity) _then;

/// Create a copy of ConversationEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? workspaceId = null,Object? isPinned = null,Object? createdAt = null,Object? updatedAt = null,Object? modelId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationEntity].
extension ConversationEntityPatterns on ConversationEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationEntity value)  $default,){
final _that = this;
switch (_that) {
case _ConversationEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String workspaceId,  bool isPinned,  DateTime createdAt,  DateTime updatedAt,  String? modelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationEntity() when $default != null:
return $default(_that.id,_that.title,_that.workspaceId,_that.isPinned,_that.createdAt,_that.updatedAt,_that.modelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String workspaceId,  bool isPinned,  DateTime createdAt,  DateTime updatedAt,  String? modelId)  $default,) {final _that = this;
switch (_that) {
case _ConversationEntity():
return $default(_that.id,_that.title,_that.workspaceId,_that.isPinned,_that.createdAt,_that.updatedAt,_that.modelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String workspaceId,  bool isPinned,  DateTime createdAt,  DateTime updatedAt,  String? modelId)?  $default,) {final _that = this;
switch (_that) {
case _ConversationEntity() when $default != null:
return $default(_that.id,_that.title,_that.workspaceId,_that.isPinned,_that.createdAt,_that.updatedAt,_that.modelId);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationEntity extends ConversationEntity {
  const _ConversationEntity({required this.id, required this.title, required this.workspaceId, required this.isPinned, required this.createdAt, required this.updatedAt, this.modelId}): super._();
  

/// Unique identifier for the conversation
@override final  String id;
/// Human-readable title of the conversation
@override final  String title;
/// ID of the workspace this conversation belongs to
@override final  String workspaceId;
/// Whether this conversation is pinned
@override final  bool isPinned;
/// Timestamp when the conversation was created
@override final  DateTime createdAt;
/// Timestamp when the conversation was last updated
@override final  DateTime updatedAt;
/// ID of the AI model used for this conversation
@override final  String? modelId;

/// Create a copy of ConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationEntityCopyWith<_ConversationEntity> get copyWith => __$ConversationEntityCopyWithImpl<_ConversationEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.modelId, modelId) || other.modelId == modelId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,workspaceId,isPinned,createdAt,updatedAt,modelId);

@override
String toString() {
  return 'ConversationEntity(id: $id, title: $title, workspaceId: $workspaceId, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt, modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class _$ConversationEntityCopyWith<$Res> implements $ConversationEntityCopyWith<$Res> {
  factory _$ConversationEntityCopyWith(_ConversationEntity value, $Res Function(_ConversationEntity) _then) = __$ConversationEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String workspaceId, bool isPinned, DateTime createdAt, DateTime updatedAt, String? modelId
});




}
/// @nodoc
class __$ConversationEntityCopyWithImpl<$Res>
    implements _$ConversationEntityCopyWith<$Res> {
  __$ConversationEntityCopyWithImpl(this._self, this._then);

  final _ConversationEntity _self;
  final $Res Function(_ConversationEntity) _then;

/// Create a copy of ConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? workspaceId = null,Object? isPinned = null,Object? createdAt = null,Object? updatedAt = null,Object? modelId = freezed,}) {
  return _then(_ConversationEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ConversationToCreate {

/// Human-readable title of the conversation
 String get title;/// ID of the workspace this conversation belongs to
 String get workspaceId;/// ID of the AI model used for this conversation
 String? get modelId;/// Whether this conversation is pinned
 bool? get isPinned;
/// Create a copy of ConversationToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToCreateCopyWith<ConversationToCreate> get copyWith => _$ConversationToCreateCopyWithImpl<ConversationToCreate>(this as ConversationToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,workspaceId,modelId,isPinned);

@override
String toString() {
  return 'ConversationToCreate(title: $title, workspaceId: $workspaceId, modelId: $modelId, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class $ConversationToCreateCopyWith<$Res>  {
  factory $ConversationToCreateCopyWith(ConversationToCreate value, $Res Function(ConversationToCreate) _then) = _$ConversationToCreateCopyWithImpl;
@useResult
$Res call({
 String title, String workspaceId, String? modelId, bool? isPinned
});




}
/// @nodoc
class _$ConversationToCreateCopyWithImpl<$Res>
    implements $ConversationToCreateCopyWith<$Res> {
  _$ConversationToCreateCopyWithImpl(this._self, this._then);

  final ConversationToCreate _self;
  final $Res Function(ConversationToCreate) _then;

/// Create a copy of ConversationToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? workspaceId = null,Object? modelId = freezed,Object? isPinned = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationToCreate].
extension ConversationToCreatePatterns on ConversationToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToCreate value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String workspaceId,  String? modelId,  bool? isPinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToCreate() when $default != null:
return $default(_that.title,_that.workspaceId,_that.modelId,_that.isPinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String workspaceId,  String? modelId,  bool? isPinned)  $default,) {final _that = this;
switch (_that) {
case _ConversationToCreate():
return $default(_that.title,_that.workspaceId,_that.modelId,_that.isPinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String workspaceId,  String? modelId,  bool? isPinned)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToCreate() when $default != null:
return $default(_that.title,_that.workspaceId,_that.modelId,_that.isPinned);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToCreate extends ConversationToCreate {
  const _ConversationToCreate({required this.title, required this.workspaceId, this.modelId, this.isPinned}): super._();
  

/// Human-readable title of the conversation
@override final  String title;
/// ID of the workspace this conversation belongs to
@override final  String workspaceId;
/// ID of the AI model used for this conversation
@override final  String? modelId;
/// Whether this conversation is pinned
@override final  bool? isPinned;

/// Create a copy of ConversationToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToCreateCopyWith<_ConversationToCreate> get copyWith => __$ConversationToCreateCopyWithImpl<_ConversationToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,workspaceId,modelId,isPinned);

@override
String toString() {
  return 'ConversationToCreate(title: $title, workspaceId: $workspaceId, modelId: $modelId, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class _$ConversationToCreateCopyWith<$Res> implements $ConversationToCreateCopyWith<$Res> {
  factory _$ConversationToCreateCopyWith(_ConversationToCreate value, $Res Function(_ConversationToCreate) _then) = __$ConversationToCreateCopyWithImpl;
@override @useResult
$Res call({
 String title, String workspaceId, String? modelId, bool? isPinned
});




}
/// @nodoc
class __$ConversationToCreateCopyWithImpl<$Res>
    implements _$ConversationToCreateCopyWith<$Res> {
  __$ConversationToCreateCopyWithImpl(this._self, this._then);

  final _ConversationToCreate _self;
  final $Res Function(_ConversationToCreate) _then;

/// Create a copy of ConversationToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? workspaceId = null,Object? modelId = freezed,Object? isPinned = freezed,}) {
  return _then(_ConversationToCreate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$ConversationToUpdate {

/// Human-readable title of the conversation
 String? get title;/// ID of the AI model used for this conversation
 String? get modelId;/// Whether this conversation is pinned
 bool? get isPinned;
/// Create a copy of ConversationToUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToUpdateCopyWith<ConversationToUpdate> get copyWith => _$ConversationToUpdateCopyWithImpl<ConversationToUpdate>(this as ConversationToUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,modelId,isPinned);

@override
String toString() {
  return 'ConversationToUpdate(title: $title, modelId: $modelId, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class $ConversationToUpdateCopyWith<$Res>  {
  factory $ConversationToUpdateCopyWith(ConversationToUpdate value, $Res Function(ConversationToUpdate) _then) = _$ConversationToUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? modelId, bool? isPinned
});




}
/// @nodoc
class _$ConversationToUpdateCopyWithImpl<$Res>
    implements $ConversationToUpdateCopyWith<$Res> {
  _$ConversationToUpdateCopyWithImpl(this._self, this._then);

  final ConversationToUpdate _self;
  final $Res Function(ConversationToUpdate) _then;

/// Create a copy of ConversationToUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? modelId = freezed,Object? isPinned = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationToUpdate].
extension ConversationToUpdatePatterns on ConversationToUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToUpdate value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? modelId,  bool? isPinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToUpdate() when $default != null:
return $default(_that.title,_that.modelId,_that.isPinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? modelId,  bool? isPinned)  $default,) {final _that = this;
switch (_that) {
case _ConversationToUpdate():
return $default(_that.title,_that.modelId,_that.isPinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? modelId,  bool? isPinned)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToUpdate() when $default != null:
return $default(_that.title,_that.modelId,_that.isPinned);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToUpdate extends ConversationToUpdate {
  const _ConversationToUpdate({this.title, this.modelId, this.isPinned}): super._();
  

/// Human-readable title of the conversation
@override final  String? title;
/// ID of the AI model used for this conversation
@override final  String? modelId;
/// Whether this conversation is pinned
@override final  bool? isPinned;

/// Create a copy of ConversationToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToUpdateCopyWith<_ConversationToUpdate> get copyWith => __$ConversationToUpdateCopyWithImpl<_ConversationToUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,modelId,isPinned);

@override
String toString() {
  return 'ConversationToUpdate(title: $title, modelId: $modelId, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class _$ConversationToUpdateCopyWith<$Res> implements $ConversationToUpdateCopyWith<$Res> {
  factory _$ConversationToUpdateCopyWith(_ConversationToUpdate value, $Res Function(_ConversationToUpdate) _then) = __$ConversationToUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? modelId, bool? isPinned
});




}
/// @nodoc
class __$ConversationToUpdateCopyWithImpl<$Res>
    implements _$ConversationToUpdateCopyWith<$Res> {
  __$ConversationToUpdateCopyWithImpl(this._self, this._then);

  final _ConversationToUpdate _self;
  final $Res Function(_ConversationToUpdate) _then;

/// Create a copy of ConversationToUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? modelId = freezed,Object? isPinned = freezed,}) {
  return _then(_ConversationToUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
