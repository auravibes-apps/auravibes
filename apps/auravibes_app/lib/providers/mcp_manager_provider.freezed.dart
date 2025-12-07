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
mixin _$McpToolInfo {

/// Original tool name from the MCP server
 String get originalName;/// Prefixed name for avoiding conflicts: "mcp_${slug}_${originalName}"
 String get prefixedName;/// Tool description from the MCP server
 String get description;/// JSON Schema for the tool's input parameters
 Map<String, dynamic> get inputSchema;/// ID of the MCP server that provides this tool
 String get mcpServerId;
/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpToolInfoCopyWith<McpToolInfo> get copyWith => _$McpToolInfoCopyWithImpl<McpToolInfo>(this as McpToolInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpToolInfo&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.prefixedName, prefixedName) || other.prefixedName == prefixedName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.inputSchema, inputSchema)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,originalName,prefixedName,description,const DeepCollectionEquality().hash(inputSchema),mcpServerId);

@override
String toString() {
  return 'McpToolInfo(originalName: $originalName, prefixedName: $prefixedName, description: $description, inputSchema: $inputSchema, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class $McpToolInfoCopyWith<$Res>  {
  factory $McpToolInfoCopyWith(McpToolInfo value, $Res Function(McpToolInfo) _then) = _$McpToolInfoCopyWithImpl;
@useResult
$Res call({
 String originalName, String prefixedName, String description, Map<String, dynamic> inputSchema, String mcpServerId
});




}
/// @nodoc
class _$McpToolInfoCopyWithImpl<$Res>
    implements $McpToolInfoCopyWith<$Res> {
  _$McpToolInfoCopyWithImpl(this._self, this._then);

  final McpToolInfo _self;
  final $Res Function(McpToolInfo) _then;

/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalName = null,Object? prefixedName = null,Object? description = null,Object? inputSchema = null,Object? mcpServerId = null,}) {
  return _then(_self.copyWith(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,prefixedName: null == prefixedName ? _self.prefixedName : prefixedName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self.inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,mcpServerId: null == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [McpToolInfo].
extension McpToolInfoPatterns on McpToolInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpToolInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpToolInfo value)  $default,){
final _that = this;
switch (_that) {
case _McpToolInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpToolInfo value)?  $default,){
final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String originalName,  String prefixedName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.originalName,_that.prefixedName,_that.description,_that.inputSchema,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String originalName,  String prefixedName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId)  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo():
return $default(_that.originalName,_that.prefixedName,_that.description,_that.inputSchema,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String originalName,  String prefixedName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId)?  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.originalName,_that.prefixedName,_that.description,_that.inputSchema,_that.mcpServerId);case _:
  return null;

}
}

}

/// @nodoc


class _McpToolInfo extends McpToolInfo {
  const _McpToolInfo({required this.originalName, required this.prefixedName, required this.description, required final  Map<String, dynamic> inputSchema, required this.mcpServerId}): _inputSchema = inputSchema,super._();
  

/// Original tool name from the MCP server
@override final  String originalName;
/// Prefixed name for avoiding conflicts: "mcp_${slug}_${originalName}"
@override final  String prefixedName;
/// Tool description from the MCP server
@override final  String description;
/// JSON Schema for the tool's input parameters
 final  Map<String, dynamic> _inputSchema;
/// JSON Schema for the tool's input parameters
@override Map<String, dynamic> get inputSchema {
  if (_inputSchema is EqualUnmodifiableMapView) return _inputSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_inputSchema);
}

/// ID of the MCP server that provides this tool
@override final  String mcpServerId;

/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpToolInfoCopyWith<_McpToolInfo> get copyWith => __$McpToolInfoCopyWithImpl<_McpToolInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpToolInfo&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.prefixedName, prefixedName) || other.prefixedName == prefixedName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._inputSchema, _inputSchema)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,originalName,prefixedName,description,const DeepCollectionEquality().hash(_inputSchema),mcpServerId);

@override
String toString() {
  return 'McpToolInfo(originalName: $originalName, prefixedName: $prefixedName, description: $description, inputSchema: $inputSchema, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class _$McpToolInfoCopyWith<$Res> implements $McpToolInfoCopyWith<$Res> {
  factory _$McpToolInfoCopyWith(_McpToolInfo value, $Res Function(_McpToolInfo) _then) = __$McpToolInfoCopyWithImpl;
@override @useResult
$Res call({
 String originalName, String prefixedName, String description, Map<String, dynamic> inputSchema, String mcpServerId
});




}
/// @nodoc
class __$McpToolInfoCopyWithImpl<$Res>
    implements _$McpToolInfoCopyWith<$Res> {
  __$McpToolInfoCopyWithImpl(this._self, this._then);

  final _McpToolInfo _self;
  final $Res Function(_McpToolInfo) _then;

/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalName = null,Object? prefixedName = null,Object? description = null,Object? inputSchema = null,Object? mcpServerId = null,}) {
  return _then(_McpToolInfo(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,prefixedName: null == prefixedName ? _self.prefixedName : prefixedName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self._inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,mcpServerId: null == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$McpConnectionState {

/// The MCP server configuration
 McpServerEntity get server;/// Current connection status
 McpConnectionStatus get status;/// The connected MCP client instance (null if not connected)
 mcp.Client? get client;/// Tools available from this MCP server
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
 McpServerEntity server, McpConnectionStatus status, mcp.Client? client, List<McpToolInfo> tools, String? errorMessage
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
as mcp.Client?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( McpServerEntity server,  McpConnectionStatus status,  mcp.Client? client,  List<McpToolInfo> tools,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( McpServerEntity server,  McpConnectionStatus status,  mcp.Client? client,  List<McpToolInfo> tools,  String? errorMessage)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( McpServerEntity server,  McpConnectionStatus status,  mcp.Client? client,  List<McpToolInfo> tools,  String? errorMessage)?  $default,) {final _that = this;
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
@override final  mcp.Client? client;
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
 McpServerEntity server, McpConnectionStatus status, mcp.Client? client, List<McpToolInfo> tools, String? errorMessage
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
as mcp.Client?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
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
