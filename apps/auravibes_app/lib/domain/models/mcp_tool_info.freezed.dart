// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_tool_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpToolInfo {

/// Original tool name from the MCP server
 String get toolName;/// Original MCP server name to avoid conflicts
 String get serverName;/// Tool description from the MCP server
 String get description;/// JSON Schema for the tool's input parameters
 Map<String, dynamic> get inputSchema;/// ID of the MCP server that provides this tool
 String get mcpServerId;/// Whether the tool supports progress updates
 bool? get supportsProgress;/// Whether the tool supports cancellation
 bool? get supportsCancellation;/// Additional metadata for the tool
 Map<String, dynamic>? get metadata;
/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpToolInfoCopyWith<McpToolInfo> get copyWith => _$McpToolInfoCopyWithImpl<McpToolInfo>(this as McpToolInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpToolInfo&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.inputSchema, inputSchema)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId)&&(identical(other.supportsProgress, supportsProgress) || other.supportsProgress == supportsProgress)&&(identical(other.supportsCancellation, supportsCancellation) || other.supportsCancellation == supportsCancellation)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}


@override
int get hashCode => Object.hash(runtimeType,toolName,serverName,description,const DeepCollectionEquality().hash(inputSchema),mcpServerId,supportsProgress,supportsCancellation,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'McpToolInfo(toolName: $toolName, serverName: $serverName, description: $description, inputSchema: $inputSchema, mcpServerId: $mcpServerId, supportsProgress: $supportsProgress, supportsCancellation: $supportsCancellation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $McpToolInfoCopyWith<$Res>  {
  factory $McpToolInfoCopyWith(McpToolInfo value, $Res Function(McpToolInfo) _then) = _$McpToolInfoCopyWithImpl;
@useResult
$Res call({
 String toolName, String serverName, String description, Map<String, dynamic> inputSchema, String mcpServerId, bool? supportsProgress, bool? supportsCancellation, Map<String, dynamic>? metadata
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
@pragma('vm:prefer-inline') @override $Res call({Object? toolName = null,Object? serverName = null,Object? description = null,Object? inputSchema = null,Object? mcpServerId = null,Object? supportsProgress = freezed,Object? supportsCancellation = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self.inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,mcpServerId: null == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String,supportsProgress: freezed == supportsProgress ? _self.supportsProgress : supportsProgress // ignore: cast_nullable_to_non_nullable
as bool?,supportsCancellation: freezed == supportsCancellation ? _self.supportsCancellation : supportsCancellation // ignore: cast_nullable_to_non_nullable
as bool?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolName,  String serverName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.toolName,_that.serverName,_that.description,_that.inputSchema,_that.mcpServerId,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolName,  String serverName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo():
return $default(_that.toolName,_that.serverName,_that.description,_that.inputSchema,_that.mcpServerId,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolName,  String serverName,  String description,  Map<String, dynamic> inputSchema,  String mcpServerId,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.toolName,_that.serverName,_that.description,_that.inputSchema,_that.mcpServerId,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _McpToolInfo extends McpToolInfo {
  const _McpToolInfo({required this.toolName, required this.serverName, required this.description, required final  Map<String, dynamic> inputSchema, required this.mcpServerId, this.supportsProgress, this.supportsCancellation, final  Map<String, dynamic>? metadata}): _inputSchema = inputSchema,_metadata = metadata,super._();
  

/// Original tool name from the MCP server
@override final  String toolName;
/// Original MCP server name to avoid conflicts
@override final  String serverName;
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
/// Whether the tool supports progress updates
@override final  bool? supportsProgress;
/// Whether the tool supports cancellation
@override final  bool? supportsCancellation;
/// Additional metadata for the tool
 final  Map<String, dynamic>? _metadata;
/// Additional metadata for the tool
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpToolInfoCopyWith<_McpToolInfo> get copyWith => __$McpToolInfoCopyWithImpl<_McpToolInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpToolInfo&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._inputSchema, _inputSchema)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId)&&(identical(other.supportsProgress, supportsProgress) || other.supportsProgress == supportsProgress)&&(identical(other.supportsCancellation, supportsCancellation) || other.supportsCancellation == supportsCancellation)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}


@override
int get hashCode => Object.hash(runtimeType,toolName,serverName,description,const DeepCollectionEquality().hash(_inputSchema),mcpServerId,supportsProgress,supportsCancellation,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'McpToolInfo(toolName: $toolName, serverName: $serverName, description: $description, inputSchema: $inputSchema, mcpServerId: $mcpServerId, supportsProgress: $supportsProgress, supportsCancellation: $supportsCancellation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$McpToolInfoCopyWith<$Res> implements $McpToolInfoCopyWith<$Res> {
  factory _$McpToolInfoCopyWith(_McpToolInfo value, $Res Function(_McpToolInfo) _then) = __$McpToolInfoCopyWithImpl;
@override @useResult
$Res call({
 String toolName, String serverName, String description, Map<String, dynamic> inputSchema, String mcpServerId, bool? supportsProgress, bool? supportsCancellation, Map<String, dynamic>? metadata
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
@override @pragma('vm:prefer-inline') $Res call({Object? toolName = null,Object? serverName = null,Object? description = null,Object? inputSchema = null,Object? mcpServerId = null,Object? supportsProgress = freezed,Object? supportsCancellation = freezed,Object? metadata = freezed,}) {
  return _then(_McpToolInfo(
toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self._inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,mcpServerId: null == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String,supportsProgress: freezed == supportsProgress ? _self.supportsProgress : supportsProgress // ignore: cast_nullable_to_non_nullable
as bool?,supportsCancellation: freezed == supportsCancellation ? _self.supportsCancellation : supportsCancellation // ignore: cast_nullable_to_non_nullable
as bool?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
