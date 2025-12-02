// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_tool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationToolEntity {

/// ID of the conversation this tool setting belongs to
 String get conversationId;/// tool identificator (e.g., 'web_search', 'calculator', etc.)
 String get toolId;/// Whether the tool is enabled for this conversation
 bool get isEnabled;/// Permission mode for this tool (always ask or always allow)
 ToolPermissionMode get permissionMode;/// Timestamp when this setting was created
 DateTime get createdAt;/// Timestamp when this setting was last updated
 DateTime get updatedAt;
/// Create a copy of ConversationToolEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToolEntityCopyWith<ConversationToolEntity> get copyWith => _$ConversationToolEntityCopyWithImpl<ConversationToolEntity>(this as ConversationToolEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToolEntity&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,toolId,isEnabled,permissionMode,createdAt,updatedAt);

@override
String toString() {
  return 'ConversationToolEntity(conversationId: $conversationId, toolId: $toolId, isEnabled: $isEnabled, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ConversationToolEntityCopyWith<$Res>  {
  factory $ConversationToolEntityCopyWith(ConversationToolEntity value, $Res Function(ConversationToolEntity) _then) = _$ConversationToolEntityCopyWithImpl;
@useResult
$Res call({
 String conversationId, String toolId, bool isEnabled, ToolPermissionMode permissionMode, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ConversationToolEntityCopyWithImpl<$Res>
    implements $ConversationToolEntityCopyWith<$Res> {
  _$ConversationToolEntityCopyWithImpl(this._self, this._then);

  final ConversationToolEntity _self;
  final $Res Function(ConversationToolEntity) _then;

/// Create a copy of ConversationToolEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? toolId = null,Object? isEnabled = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationToolEntity].
extension ConversationToolEntityPatterns on ConversationToolEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToolEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToolEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToolEntity value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToolEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToolEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToolEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String toolId,  bool isEnabled,  ToolPermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToolEntity() when $default != null:
return $default(_that.conversationId,_that.toolId,_that.isEnabled,_that.permissionMode,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String toolId,  bool isEnabled,  ToolPermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ConversationToolEntity():
return $default(_that.conversationId,_that.toolId,_that.isEnabled,_that.permissionMode,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String toolId,  bool isEnabled,  ToolPermissionMode permissionMode,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToolEntity() when $default != null:
return $default(_that.conversationId,_that.toolId,_that.isEnabled,_that.permissionMode,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToolEntity extends ConversationToolEntity {
  const _ConversationToolEntity({required this.conversationId, required this.toolId, required this.isEnabled, required this.permissionMode, required this.createdAt, required this.updatedAt}): super._();
  

/// ID of the conversation this tool setting belongs to
@override final  String conversationId;
/// tool identificator (e.g., 'web_search', 'calculator', etc.)
@override final  String toolId;
/// Whether the tool is enabled for this conversation
@override final  bool isEnabled;
/// Permission mode for this tool (always ask or always allow)
@override final  ToolPermissionMode permissionMode;
/// Timestamp when this setting was created
@override final  DateTime createdAt;
/// Timestamp when this setting was last updated
@override final  DateTime updatedAt;

/// Create a copy of ConversationToolEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToolEntityCopyWith<_ConversationToolEntity> get copyWith => __$ConversationToolEntityCopyWithImpl<_ConversationToolEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToolEntity&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,toolId,isEnabled,permissionMode,createdAt,updatedAt);

@override
String toString() {
  return 'ConversationToolEntity(conversationId: $conversationId, toolId: $toolId, isEnabled: $isEnabled, permissionMode: $permissionMode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationToolEntityCopyWith<$Res> implements $ConversationToolEntityCopyWith<$Res> {
  factory _$ConversationToolEntityCopyWith(_ConversationToolEntity value, $Res Function(_ConversationToolEntity) _then) = __$ConversationToolEntityCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String toolId, bool isEnabled, ToolPermissionMode permissionMode, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ConversationToolEntityCopyWithImpl<$Res>
    implements _$ConversationToolEntityCopyWith<$Res> {
  __$ConversationToolEntityCopyWithImpl(this._self, this._then);

  final _ConversationToolEntity _self;
  final $Res Function(_ConversationToolEntity) _then;

/// Create a copy of ConversationToolEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? toolId = null,Object? isEnabled = null,Object? permissionMode = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ConversationToolEntity(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ConversationToolToCreate {

/// tool identificator (e.g., 'web_search', 'calculator', etc.)
 String get toolId;/// Whether the tool should be enabled (defaults to true)
 bool? get isEnabled;/// Permission mode for this tool (defaults to alwaysAsk)
 ToolPermissionMode? get permissionMode;
/// Create a copy of ConversationToolToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToolToCreateCopyWith<ConversationToolToCreate> get copyWith => _$ConversationToolToCreateCopyWithImpl<ConversationToolToCreate>(this as ConversationToolToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToolToCreate&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}


@override
int get hashCode => Object.hash(runtimeType,toolId,isEnabled,permissionMode);

@override
String toString() {
  return 'ConversationToolToCreate(toolId: $toolId, isEnabled: $isEnabled, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class $ConversationToolToCreateCopyWith<$Res>  {
  factory $ConversationToolToCreateCopyWith(ConversationToolToCreate value, $Res Function(ConversationToolToCreate) _then) = _$ConversationToolToCreateCopyWithImpl;
@useResult
$Res call({
 String toolId, bool? isEnabled, ToolPermissionMode? permissionMode
});




}
/// @nodoc
class _$ConversationToolToCreateCopyWithImpl<$Res>
    implements $ConversationToolToCreateCopyWith<$Res> {
  _$ConversationToolToCreateCopyWithImpl(this._self, this._then);

  final ConversationToolToCreate _self;
  final $Res Function(ConversationToolToCreate) _then;

/// Create a copy of ConversationToolToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolId = null,Object? isEnabled = freezed,Object? permissionMode = freezed,}) {
  return _then(_self.copyWith(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationToolToCreate].
extension ConversationToolToCreatePatterns on ConversationToolToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToolToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToolToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToolToCreate value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToolToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToolToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToolToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolId,  bool? isEnabled,  ToolPermissionMode? permissionMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToolToCreate() when $default != null:
return $default(_that.toolId,_that.isEnabled,_that.permissionMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolId,  bool? isEnabled,  ToolPermissionMode? permissionMode)  $default,) {final _that = this;
switch (_that) {
case _ConversationToolToCreate():
return $default(_that.toolId,_that.isEnabled,_that.permissionMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolId,  bool? isEnabled,  ToolPermissionMode? permissionMode)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToolToCreate() when $default != null:
return $default(_that.toolId,_that.isEnabled,_that.permissionMode);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToolToCreate extends ConversationToolToCreate {
  const _ConversationToolToCreate({required this.toolId, this.isEnabled, this.permissionMode}): super._();
  

/// tool identificator (e.g., 'web_search', 'calculator', etc.)
@override final  String toolId;
/// Whether the tool should be enabled (defaults to true)
@override final  bool? isEnabled;
/// Permission mode for this tool (defaults to alwaysAsk)
@override final  ToolPermissionMode? permissionMode;

/// Create a copy of ConversationToolToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToolToCreateCopyWith<_ConversationToolToCreate> get copyWith => __$ConversationToolToCreateCopyWithImpl<_ConversationToolToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToolToCreate&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode));
}


@override
int get hashCode => Object.hash(runtimeType,toolId,isEnabled,permissionMode);

@override
String toString() {
  return 'ConversationToolToCreate(toolId: $toolId, isEnabled: $isEnabled, permissionMode: $permissionMode)';
}


}

/// @nodoc
abstract mixin class _$ConversationToolToCreateCopyWith<$Res> implements $ConversationToolToCreateCopyWith<$Res> {
  factory _$ConversationToolToCreateCopyWith(_ConversationToolToCreate value, $Res Function(_ConversationToolToCreate) _then) = __$ConversationToolToCreateCopyWithImpl;
@override @useResult
$Res call({
 String toolId, bool? isEnabled, ToolPermissionMode? permissionMode
});




}
/// @nodoc
class __$ConversationToolToCreateCopyWithImpl<$Res>
    implements _$ConversationToolToCreateCopyWith<$Res> {
  __$ConversationToolToCreateCopyWithImpl(this._self, this._then);

  final _ConversationToolToCreate _self;
  final $Res Function(_ConversationToolToCreate) _then;

/// Create a copy of ConversationToolToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolId = null,Object? isEnabled = freezed,Object? permissionMode = freezed,}) {
  return _then(_ConversationToolToCreate(
toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,isEnabled: freezed == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool?,permissionMode: freezed == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode?,
  ));
}


}

// dart format on
