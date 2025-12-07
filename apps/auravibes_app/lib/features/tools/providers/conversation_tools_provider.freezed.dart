// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_tools_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationToolState {

 WorkspaceToolEntity get tool; bool get isEnabled; ToolPermissionMode get permissionMode;/// Whether this tool is enabled at the workspace level
 bool get isWorkspaceEnabled;
/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToolStateCopyWith<ConversationToolState> get copyWith => _$ConversationToolStateCopyWithImpl<ConversationToolState>(this as ConversationToolState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToolState&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.isWorkspaceEnabled, isWorkspaceEnabled) || other.isWorkspaceEnabled == isWorkspaceEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,tool,isEnabled,permissionMode,isWorkspaceEnabled);

@override
String toString() {
  return 'ConversationToolState(tool: $tool, isEnabled: $isEnabled, permissionMode: $permissionMode, isWorkspaceEnabled: $isWorkspaceEnabled)';
}


}

/// @nodoc
abstract mixin class $ConversationToolStateCopyWith<$Res>  {
  factory $ConversationToolStateCopyWith(ConversationToolState value, $Res Function(ConversationToolState) _then) = _$ConversationToolStateCopyWithImpl;
@useResult
$Res call({
 WorkspaceToolEntity tool, bool isEnabled, ToolPermissionMode permissionMode, bool isWorkspaceEnabled
});


$WorkspaceToolEntityCopyWith<$Res> get tool;

}
/// @nodoc
class _$ConversationToolStateCopyWithImpl<$Res>
    implements $ConversationToolStateCopyWith<$Res> {
  _$ConversationToolStateCopyWithImpl(this._self, this._then);

  final ConversationToolState _self;
  final $Res Function(ConversationToolState) _then;

/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? isEnabled = null,Object? permissionMode = null,Object? isWorkspaceEnabled = null,}) {
  return _then(_self.copyWith(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as WorkspaceToolEntity,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode,isWorkspaceEnabled: null == isWorkspaceEnabled ? _self.isWorkspaceEnabled : isWorkspaceEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceToolEntityCopyWith<$Res> get tool {
  
  return $WorkspaceToolEntityCopyWith<$Res>(_self.tool, (value) {
    return _then(_self.copyWith(tool: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationToolState].
extension ConversationToolStatePatterns on ConversationToolState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToolState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToolState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToolState value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToolState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToolState value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToolState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceToolEntity tool,  bool isEnabled,  ToolPermissionMode permissionMode,  bool isWorkspaceEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToolState() when $default != null:
return $default(_that.tool,_that.isEnabled,_that.permissionMode,_that.isWorkspaceEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceToolEntity tool,  bool isEnabled,  ToolPermissionMode permissionMode,  bool isWorkspaceEnabled)  $default,) {final _that = this;
switch (_that) {
case _ConversationToolState():
return $default(_that.tool,_that.isEnabled,_that.permissionMode,_that.isWorkspaceEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceToolEntity tool,  bool isEnabled,  ToolPermissionMode permissionMode,  bool isWorkspaceEnabled)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToolState() when $default != null:
return $default(_that.tool,_that.isEnabled,_that.permissionMode,_that.isWorkspaceEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToolState implements ConversationToolState {
  const _ConversationToolState({required this.tool, required this.isEnabled, required this.permissionMode, required this.isWorkspaceEnabled});
  

@override final  WorkspaceToolEntity tool;
@override final  bool isEnabled;
@override final  ToolPermissionMode permissionMode;
/// Whether this tool is enabled at the workspace level
@override final  bool isWorkspaceEnabled;

/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToolStateCopyWith<_ConversationToolState> get copyWith => __$ConversationToolStateCopyWithImpl<_ConversationToolState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToolState&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissionMode, permissionMode) || other.permissionMode == permissionMode)&&(identical(other.isWorkspaceEnabled, isWorkspaceEnabled) || other.isWorkspaceEnabled == isWorkspaceEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,tool,isEnabled,permissionMode,isWorkspaceEnabled);

@override
String toString() {
  return 'ConversationToolState(tool: $tool, isEnabled: $isEnabled, permissionMode: $permissionMode, isWorkspaceEnabled: $isWorkspaceEnabled)';
}


}

/// @nodoc
abstract mixin class _$ConversationToolStateCopyWith<$Res> implements $ConversationToolStateCopyWith<$Res> {
  factory _$ConversationToolStateCopyWith(_ConversationToolState value, $Res Function(_ConversationToolState) _then) = __$ConversationToolStateCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceToolEntity tool, bool isEnabled, ToolPermissionMode permissionMode, bool isWorkspaceEnabled
});


@override $WorkspaceToolEntityCopyWith<$Res> get tool;

}
/// @nodoc
class __$ConversationToolStateCopyWithImpl<$Res>
    implements _$ConversationToolStateCopyWith<$Res> {
  __$ConversationToolStateCopyWithImpl(this._self, this._then);

  final _ConversationToolState _self;
  final $Res Function(_ConversationToolState) _then;

/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? isEnabled = null,Object? permissionMode = null,Object? isWorkspaceEnabled = null,}) {
  return _then(_ConversationToolState(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as WorkspaceToolEntity,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissionMode: null == permissionMode ? _self.permissionMode : permissionMode // ignore: cast_nullable_to_non_nullable
as ToolPermissionMode,isWorkspaceEnabled: null == isWorkspaceEnabled ? _self.isWorkspaceEnabled : isWorkspaceEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ConversationToolState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceToolEntityCopyWith<$Res> get tool {
  
  return $WorkspaceToolEntityCopyWith<$Res>(_self.tool, (value) {
    return _then(_self.copyWith(tool: value));
  });
}
}

// dart format on
