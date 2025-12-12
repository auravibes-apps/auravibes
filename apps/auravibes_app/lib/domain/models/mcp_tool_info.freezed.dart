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

 String get toolName; String get description; Map<String, dynamic> get inputSchema; bool? get supportsProgress; bool? get supportsCancellation; Map<String, dynamic>? get metadata;
/// Create a copy of McpToolInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpToolInfoCopyWith<McpToolInfo> get copyWith => _$McpToolInfoCopyWithImpl<McpToolInfo>(this as McpToolInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpToolInfo&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.inputSchema, inputSchema)&&(identical(other.supportsProgress, supportsProgress) || other.supportsProgress == supportsProgress)&&(identical(other.supportsCancellation, supportsCancellation) || other.supportsCancellation == supportsCancellation)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}


@override
int get hashCode => Object.hash(runtimeType,toolName,description,const DeepCollectionEquality().hash(inputSchema),supportsProgress,supportsCancellation,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'McpToolInfo(toolName: $toolName, description: $description, inputSchema: $inputSchema, supportsProgress: $supportsProgress, supportsCancellation: $supportsCancellation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $McpToolInfoCopyWith<$Res>  {
  factory $McpToolInfoCopyWith(McpToolInfo value, $Res Function(McpToolInfo) _then) = _$McpToolInfoCopyWithImpl;
@useResult
$Res call({
 String toolName, String description, Map<String, dynamic> inputSchema, bool? supportsProgress, bool? supportsCancellation, Map<String, dynamic>? metadata
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
@pragma('vm:prefer-inline') @override $Res call({Object? toolName = null,Object? description = null,Object? inputSchema = null,Object? supportsProgress = freezed,Object? supportsCancellation = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self.inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,supportsProgress: freezed == supportsProgress ? _self.supportsProgress : supportsProgress // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolName,  String description,  Map<String, dynamic> inputSchema,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.toolName,_that.description,_that.inputSchema,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolName,  String description,  Map<String, dynamic> inputSchema,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo():
return $default(_that.toolName,_that.description,_that.inputSchema,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolName,  String description,  Map<String, dynamic> inputSchema,  bool? supportsProgress,  bool? supportsCancellation,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _McpToolInfo() when $default != null:
return $default(_that.toolName,_that.description,_that.inputSchema,_that.supportsProgress,_that.supportsCancellation,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _McpToolInfo extends McpToolInfo {
  const _McpToolInfo({required this.toolName, required this.description, required final  Map<String, dynamic> inputSchema, this.supportsProgress, this.supportsCancellation, final  Map<String, dynamic>? metadata}): _inputSchema = inputSchema,_metadata = metadata,super._();
  

@override final  String toolName;
@override final  String description;
 final  Map<String, dynamic> _inputSchema;
@override Map<String, dynamic> get inputSchema {
  if (_inputSchema is EqualUnmodifiableMapView) return _inputSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_inputSchema);
}

@override final  bool? supportsProgress;
@override final  bool? supportsCancellation;
 final  Map<String, dynamic>? _metadata;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpToolInfo&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._inputSchema, _inputSchema)&&(identical(other.supportsProgress, supportsProgress) || other.supportsProgress == supportsProgress)&&(identical(other.supportsCancellation, supportsCancellation) || other.supportsCancellation == supportsCancellation)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}


@override
int get hashCode => Object.hash(runtimeType,toolName,description,const DeepCollectionEquality().hash(_inputSchema),supportsProgress,supportsCancellation,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'McpToolInfo(toolName: $toolName, description: $description, inputSchema: $inputSchema, supportsProgress: $supportsProgress, supportsCancellation: $supportsCancellation, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$McpToolInfoCopyWith<$Res> implements $McpToolInfoCopyWith<$Res> {
  factory _$McpToolInfoCopyWith(_McpToolInfo value, $Res Function(_McpToolInfo) _then) = __$McpToolInfoCopyWithImpl;
@override @useResult
$Res call({
 String toolName, String description, Map<String, dynamic> inputSchema, bool? supportsProgress, bool? supportsCancellation, Map<String, dynamic>? metadata
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
@override @pragma('vm:prefer-inline') $Res call({Object? toolName = null,Object? description = null,Object? inputSchema = null,Object? supportsProgress = freezed,Object? supportsCancellation = freezed,Object? metadata = freezed,}) {
  return _then(_McpToolInfo(
toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self._inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,supportsProgress: freezed == supportsProgress ? _self.supportsProgress : supportsProgress // ignore: cast_nullable_to_non_nullable
as bool?,supportsCancellation: freezed == supportsCancellation ? _self.supportsCancellation : supportsCancellation // ignore: cast_nullable_to_non_nullable
as bool?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc
mixin _$MCPServerWithTools {

 McpServerEntity get server; List<WorkspaceToolEntity> get tools;
/// Create a copy of MCPServerWithTools
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MCPServerWithToolsCopyWith<MCPServerWithTools> get copyWith => _$MCPServerWithToolsCopyWithImpl<MCPServerWithTools>(this as MCPServerWithTools, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MCPServerWithTools&&(identical(other.server, server) || other.server == server)&&const DeepCollectionEquality().equals(other.tools, tools));
}


@override
int get hashCode => Object.hash(runtimeType,server,const DeepCollectionEquality().hash(tools));

@override
String toString() {
  return 'MCPServerWithTools(server: $server, tools: $tools)';
}


}

/// @nodoc
abstract mixin class $MCPServerWithToolsCopyWith<$Res>  {
  factory $MCPServerWithToolsCopyWith(MCPServerWithTools value, $Res Function(MCPServerWithTools) _then) = _$MCPServerWithToolsCopyWithImpl;
@useResult
$Res call({
 McpServerEntity server, List<WorkspaceToolEntity> tools
});


$McpServerEntityCopyWith<$Res> get server;

}
/// @nodoc
class _$MCPServerWithToolsCopyWithImpl<$Res>
    implements $MCPServerWithToolsCopyWith<$Res> {
  _$MCPServerWithToolsCopyWithImpl(this._self, this._then);

  final MCPServerWithTools _self;
  final $Res Function(MCPServerWithTools) _then;

/// Create a copy of MCPServerWithTools
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? server = null,Object? tools = null,}) {
  return _then(_self.copyWith(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as McpServerEntity,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<WorkspaceToolEntity>,
  ));
}
/// Create a copy of MCPServerWithTools
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpServerEntityCopyWith<$Res> get server {
  
  return $McpServerEntityCopyWith<$Res>(_self.server, (value) {
    return _then(_self.copyWith(server: value));
  });
}
}


/// Adds pattern-matching-related methods to [MCPServerWithTools].
extension MCPServerWithToolsPatterns on MCPServerWithTools {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MCPServerWithTools value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MCPServerWithTools() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MCPServerWithTools value)  $default,){
final _that = this;
switch (_that) {
case _MCPServerWithTools():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MCPServerWithTools value)?  $default,){
final _that = this;
switch (_that) {
case _MCPServerWithTools() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( McpServerEntity server,  List<WorkspaceToolEntity> tools)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MCPServerWithTools() when $default != null:
return $default(_that.server,_that.tools);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( McpServerEntity server,  List<WorkspaceToolEntity> tools)  $default,) {final _that = this;
switch (_that) {
case _MCPServerWithTools():
return $default(_that.server,_that.tools);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( McpServerEntity server,  List<WorkspaceToolEntity> tools)?  $default,) {final _that = this;
switch (_that) {
case _MCPServerWithTools() when $default != null:
return $default(_that.server,_that.tools);case _:
  return null;

}
}

}

/// @nodoc


class _MCPServerWithTools extends MCPServerWithTools {
  const _MCPServerWithTools({required this.server, required final  List<WorkspaceToolEntity> tools}): _tools = tools,super._();
  

@override final  McpServerEntity server;
 final  List<WorkspaceToolEntity> _tools;
@override List<WorkspaceToolEntity> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}


/// Create a copy of MCPServerWithTools
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MCPServerWithToolsCopyWith<_MCPServerWithTools> get copyWith => __$MCPServerWithToolsCopyWithImpl<_MCPServerWithTools>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MCPServerWithTools&&(identical(other.server, server) || other.server == server)&&const DeepCollectionEquality().equals(other._tools, _tools));
}


@override
int get hashCode => Object.hash(runtimeType,server,const DeepCollectionEquality().hash(_tools));

@override
String toString() {
  return 'MCPServerWithTools(server: $server, tools: $tools)';
}


}

/// @nodoc
abstract mixin class _$MCPServerWithToolsCopyWith<$Res> implements $MCPServerWithToolsCopyWith<$Res> {
  factory _$MCPServerWithToolsCopyWith(_MCPServerWithTools value, $Res Function(_MCPServerWithTools) _then) = __$MCPServerWithToolsCopyWithImpl;
@override @useResult
$Res call({
 McpServerEntity server, List<WorkspaceToolEntity> tools
});


@override $McpServerEntityCopyWith<$Res> get server;

}
/// @nodoc
class __$MCPServerWithToolsCopyWithImpl<$Res>
    implements _$MCPServerWithToolsCopyWith<$Res> {
  __$MCPServerWithToolsCopyWithImpl(this._self, this._then);

  final _MCPServerWithTools _self;
  final $Res Function(_MCPServerWithTools) _then;

/// Create a copy of MCPServerWithTools
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? server = null,Object? tools = null,}) {
  return _then(_MCPServerWithTools(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as McpServerEntity,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<WorkspaceToolEntity>,
  ));
}

/// Create a copy of MCPServerWithTools
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
