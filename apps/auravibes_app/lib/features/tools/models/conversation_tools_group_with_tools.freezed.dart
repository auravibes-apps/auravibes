// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_tools_group_with_tools.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationToolsGroupWithTools {

/// The tools group entity, or null for the "Built-in Tools" default group.
 ToolsGroupEntity? get group;/// The list of tools belonging to this group with conversation state.
 List<ConversationToolState> get tools;/// The MCP connection state for MCP groups, null for non-MCP groups.
 McpConnectionState? get mcpConnectionState;
/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationToolsGroupWithToolsCopyWith<ConversationToolsGroupWithTools> get copyWith => _$ConversationToolsGroupWithToolsCopyWithImpl<ConversationToolsGroupWithTools>(this as ConversationToolsGroupWithTools, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationToolsGroupWithTools&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other.tools, tools)&&(identical(other.mcpConnectionState, mcpConnectionState) || other.mcpConnectionState == mcpConnectionState));
}


@override
int get hashCode => Object.hash(runtimeType,group,const DeepCollectionEquality().hash(tools),mcpConnectionState);

@override
String toString() {
  return 'ConversationToolsGroupWithTools(group: $group, tools: $tools, mcpConnectionState: $mcpConnectionState)';
}


}

/// @nodoc
abstract mixin class $ConversationToolsGroupWithToolsCopyWith<$Res>  {
  factory $ConversationToolsGroupWithToolsCopyWith(ConversationToolsGroupWithTools value, $Res Function(ConversationToolsGroupWithTools) _then) = _$ConversationToolsGroupWithToolsCopyWithImpl;
@useResult
$Res call({
 ToolsGroupEntity? group, List<ConversationToolState> tools, McpConnectionState? mcpConnectionState
});


$ToolsGroupEntityCopyWith<$Res>? get group;$McpConnectionStateCopyWith<$Res>? get mcpConnectionState;

}
/// @nodoc
class _$ConversationToolsGroupWithToolsCopyWithImpl<$Res>
    implements $ConversationToolsGroupWithToolsCopyWith<$Res> {
  _$ConversationToolsGroupWithToolsCopyWithImpl(this._self, this._then);

  final ConversationToolsGroupWithTools _self;
  final $Res Function(ConversationToolsGroupWithTools) _then;

/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = freezed,Object? tools = null,Object? mcpConnectionState = freezed,}) {
  return _then(_self.copyWith(
group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as ToolsGroupEntity?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<ConversationToolState>,mcpConnectionState: freezed == mcpConnectionState ? _self.mcpConnectionState : mcpConnectionState // ignore: cast_nullable_to_non_nullable
as McpConnectionState?,
  ));
}
/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolsGroupEntityCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $ToolsGroupEntityCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpConnectionStateCopyWith<$Res>? get mcpConnectionState {
    if (_self.mcpConnectionState == null) {
    return null;
  }

  return $McpConnectionStateCopyWith<$Res>(_self.mcpConnectionState!, (value) {
    return _then(_self.copyWith(mcpConnectionState: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationToolsGroupWithTools].
extension ConversationToolsGroupWithToolsPatterns on ConversationToolsGroupWithTools {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationToolsGroupWithTools value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationToolsGroupWithTools value)  $default,){
final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationToolsGroupWithTools value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ToolsGroupEntity? group,  List<ConversationToolState> tools,  McpConnectionState? mcpConnectionState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools() when $default != null:
return $default(_that.group,_that.tools,_that.mcpConnectionState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ToolsGroupEntity? group,  List<ConversationToolState> tools,  McpConnectionState? mcpConnectionState)  $default,) {final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools():
return $default(_that.group,_that.tools,_that.mcpConnectionState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ToolsGroupEntity? group,  List<ConversationToolState> tools,  McpConnectionState? mcpConnectionState)?  $default,) {final _that = this;
switch (_that) {
case _ConversationToolsGroupWithTools() when $default != null:
return $default(_that.group,_that.tools,_that.mcpConnectionState);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationToolsGroupWithTools extends ConversationToolsGroupWithTools {
  const _ConversationToolsGroupWithTools({required this.group, required final  List<ConversationToolState> tools, this.mcpConnectionState}): _tools = tools,super._();
  

/// The tools group entity, or null for the "Built-in Tools" default group.
@override final  ToolsGroupEntity? group;
/// The list of tools belonging to this group with conversation state.
 final  List<ConversationToolState> _tools;
/// The list of tools belonging to this group with conversation state.
@override List<ConversationToolState> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}

/// The MCP connection state for MCP groups, null for non-MCP groups.
@override final  McpConnectionState? mcpConnectionState;

/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationToolsGroupWithToolsCopyWith<_ConversationToolsGroupWithTools> get copyWith => __$ConversationToolsGroupWithToolsCopyWithImpl<_ConversationToolsGroupWithTools>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationToolsGroupWithTools&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other._tools, _tools)&&(identical(other.mcpConnectionState, mcpConnectionState) || other.mcpConnectionState == mcpConnectionState));
}


@override
int get hashCode => Object.hash(runtimeType,group,const DeepCollectionEquality().hash(_tools),mcpConnectionState);

@override
String toString() {
  return 'ConversationToolsGroupWithTools(group: $group, tools: $tools, mcpConnectionState: $mcpConnectionState)';
}


}

/// @nodoc
abstract mixin class _$ConversationToolsGroupWithToolsCopyWith<$Res> implements $ConversationToolsGroupWithToolsCopyWith<$Res> {
  factory _$ConversationToolsGroupWithToolsCopyWith(_ConversationToolsGroupWithTools value, $Res Function(_ConversationToolsGroupWithTools) _then) = __$ConversationToolsGroupWithToolsCopyWithImpl;
@override @useResult
$Res call({
 ToolsGroupEntity? group, List<ConversationToolState> tools, McpConnectionState? mcpConnectionState
});


@override $ToolsGroupEntityCopyWith<$Res>? get group;@override $McpConnectionStateCopyWith<$Res>? get mcpConnectionState;

}
/// @nodoc
class __$ConversationToolsGroupWithToolsCopyWithImpl<$Res>
    implements _$ConversationToolsGroupWithToolsCopyWith<$Res> {
  __$ConversationToolsGroupWithToolsCopyWithImpl(this._self, this._then);

  final _ConversationToolsGroupWithTools _self;
  final $Res Function(_ConversationToolsGroupWithTools) _then;

/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = freezed,Object? tools = null,Object? mcpConnectionState = freezed,}) {
  return _then(_ConversationToolsGroupWithTools(
group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as ToolsGroupEntity?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<ConversationToolState>,mcpConnectionState: freezed == mcpConnectionState ? _self.mcpConnectionState : mcpConnectionState // ignore: cast_nullable_to_non_nullable
as McpConnectionState?,
  ));
}

/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolsGroupEntityCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $ToolsGroupEntityCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of ConversationToolsGroupWithTools
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpConnectionStateCopyWith<$Res>? get mcpConnectionState {
    if (_self.mcpConnectionState == null) {
    return null;
  }

  return $McpConnectionStateCopyWith<$Res>(_self.mcpConnectionState!, (value) {
    return _then(_self.copyWith(mcpConnectionState: value));
  });
}
}

// dart format on
