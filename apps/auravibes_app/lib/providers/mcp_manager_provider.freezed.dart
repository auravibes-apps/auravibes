// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_manager_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpConnectionState {

/// The MCP server configuration
 McpServerEntity get server;/// Current connection status
 McpConnectionStatus get status;/// The connected MCP client instance (null if not connected)
 McpManagerClient? get client;/// Tools available from this MCP server
 List<McpToolInfo> get tools;/// Error message if connection failed
 String? get errorMessage;
/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpConnectionStateCopyWith<McpConnectionState> get copyWith => _$McpConnectionStateCopyWithImpl<McpConnectionState>(this as McpConnectionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpConnectionState&&(identical(other.server, server) || other.server == server)&&(identical(other.status, status) || other.status == status)&&(identical(other.client, client) || other.client == client)&&const DeepCollectionEquality().equals(other.tools, tools)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,server,status,client,const DeepCollectionEquality().hash(tools),errorMessage);

@override
String toString() {
  return 'McpConnectionState(server: $server, status: $status, client: $client, tools: $tools, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $McpConnectionStateCopyWith<$Res>  {
  factory $McpConnectionStateCopyWith(McpConnectionState value, $Res Function(McpConnectionState) _then) = _$McpConnectionStateCopyWithImpl;
@useResult
$Res call({
 McpServerEntity server, McpConnectionStatus status, McpManagerClient? client, List<McpToolInfo> tools, String? errorMessage
});


$McpServerEntityCopyWith<$Res> get server;

}
/// @nodoc
class _$McpConnectionStateCopyWithImpl<$Res>
    implements $McpConnectionStateCopyWith<$Res> {
  _$McpConnectionStateCopyWithImpl(this._self, this._then);

  final McpConnectionState _self;
  final $Res Function(McpConnectionState) _then;

/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? server = null,Object? status = null,Object? client = freezed,Object? tools = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as McpServerEntity,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as McpConnectionStatus,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as McpManagerClient?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<McpToolInfo>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpServerEntityCopyWith<$Res> get server {
  
  return $McpServerEntityCopyWith<$Res>(_self.server, (value) {
    return _then(_self.copyWith(server: value));
  });
}
}


/// Adds pattern-matching-related methods to [McpConnectionState].
extension McpConnectionStatePatterns on McpConnectionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpConnectionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpConnectionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpConnectionState value)  $default,){
final _that = this;
switch (_that) {
case _McpConnectionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpConnectionState value)?  $default,){
final _that = this;
switch (_that) {
case _McpConnectionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( McpServerEntity server,  McpConnectionStatus status,  McpManagerClient? client,  List<McpToolInfo> tools,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpConnectionState() when $default != null:
return $default(_that.server,_that.status,_that.client,_that.tools,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( McpServerEntity server,  McpConnectionStatus status,  McpManagerClient? client,  List<McpToolInfo> tools,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _McpConnectionState():
return $default(_that.server,_that.status,_that.client,_that.tools,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( McpServerEntity server,  McpConnectionStatus status,  McpManagerClient? client,  List<McpToolInfo> tools,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _McpConnectionState() when $default != null:
return $default(_that.server,_that.status,_that.client,_that.tools,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _McpConnectionState extends McpConnectionState {
  const _McpConnectionState({required this.server, required this.status, this.client, final  List<McpToolInfo> tools = const [], this.errorMessage}): _tools = tools,super._();
  

/// The MCP server configuration
@override final  McpServerEntity server;
/// Current connection status
@override final  McpConnectionStatus status;
/// The connected MCP client instance (null if not connected)
@override final  McpManagerClient? client;
/// Tools available from this MCP server
 final  List<McpToolInfo> _tools;
/// Tools available from this MCP server
@override@JsonKey() List<McpToolInfo> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}

/// Error message if connection failed
@override final  String? errorMessage;

/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpConnectionStateCopyWith<_McpConnectionState> get copyWith => __$McpConnectionStateCopyWithImpl<_McpConnectionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpConnectionState&&(identical(other.server, server) || other.server == server)&&(identical(other.status, status) || other.status == status)&&(identical(other.client, client) || other.client == client)&&const DeepCollectionEquality().equals(other._tools, _tools)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,server,status,client,const DeepCollectionEquality().hash(_tools),errorMessage);

@override
String toString() {
  return 'McpConnectionState(server: $server, status: $status, client: $client, tools: $tools, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$McpConnectionStateCopyWith<$Res> implements $McpConnectionStateCopyWith<$Res> {
  factory _$McpConnectionStateCopyWith(_McpConnectionState value, $Res Function(_McpConnectionState) _then) = __$McpConnectionStateCopyWithImpl;
@override @useResult
$Res call({
 McpServerEntity server, McpConnectionStatus status, McpManagerClient? client, List<McpToolInfo> tools, String? errorMessage
});


@override $McpServerEntityCopyWith<$Res> get server;

}
/// @nodoc
class __$McpConnectionStateCopyWithImpl<$Res>
    implements _$McpConnectionStateCopyWith<$Res> {
  __$McpConnectionStateCopyWithImpl(this._self, this._then);

  final _McpConnectionState _self;
  final $Res Function(_McpConnectionState) _then;

/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? server = null,Object? status = null,Object? client = freezed,Object? tools = null,Object? errorMessage = freezed,}) {
  return _then(_McpConnectionState(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as McpServerEntity,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as McpConnectionStatus,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as McpManagerClient?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<McpToolInfo>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of McpConnectionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpServerEntityCopyWith<$Res> get server {
  
  return $McpServerEntityCopyWith<$Res>(_self.server, (value) {
    return _then(_self.copyWith(server: value));
  });
}
}

// dart format on
