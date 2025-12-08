// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_server.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpServerEntity {

/// Unique ID of this MCP server record in the database
 String get id;/// ID of the workspace this MCP server belongs to
 String get workspaceId;/// User-friendly name for the MCP server
 String get name;/// URL endpoint for the MCP server
 String get url;/// Transport type used for communication
 McpTransportType get transport;/// Authentication type for the MCP server
 McpAuthenticationType get authenticationType;/// Timestamp when this configuration was created
 DateTime get createdAt;/// Timestamp when this configuration was last updated
 DateTime get updatedAt;/// Optional description of what this MCP server provides
 String? get description;/// OAuth client ID (required when authenticationType is oauth)
 String? get clientId;/// OAuth token endpoint URL (required when authenticationType is oauth)
 String? get tokenEndpoint;/// OAuth authorization endpoint URL
/// (required when authenticationType is oauth)
 String? get authorizationEndpoint;/// Bearer token (required when authenticationType is bearerToken)
 String? get bearerToken;/// Whether to use HTTP/2 (only applicable for streamableHttp transport)
 bool get useHttp2;/// Whether the MCP server is enabled
 bool get isEnabled;
/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerEntityCopyWith<McpServerEntity> get copyWith => _$McpServerEntityCopyWithImpl<McpServerEntity>(this as McpServerEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.tokenEndpoint, tokenEndpoint) || other.tokenEndpoint == tokenEndpoint)&&(identical(other.authorizationEndpoint, authorizationEndpoint) || other.authorizationEndpoint == authorizationEndpoint)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,url,transport,authenticationType,createdAt,updatedAt,description,clientId,tokenEndpoint,authorizationEndpoint,bearerToken,useHttp2,isEnabled);

@override
String toString() {
  return 'McpServerEntity(id: $id, workspaceId: $workspaceId, name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, clientId: $clientId, tokenEndpoint: $tokenEndpoint, authorizationEndpoint: $authorizationEndpoint, bearerToken: $bearerToken, useHttp2: $useHttp2, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $McpServerEntityCopyWith<$Res>  {
  factory $McpServerEntityCopyWith(McpServerEntity value, $Res Function(McpServerEntity) _then) = _$McpServerEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, DateTime createdAt, DateTime updatedAt, String? description, String? clientId, String? tokenEndpoint, String? authorizationEndpoint, String? bearerToken, bool useHttp2, bool isEnabled
});




}
/// @nodoc
class _$McpServerEntityCopyWithImpl<$Res>
    implements $McpServerEntityCopyWith<$Res> {
  _$McpServerEntityCopyWithImpl(this._self, this._then);

  final McpServerEntity _self;
  final $Res Function(McpServerEntity) _then;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? clientId = freezed,Object? tokenEndpoint = freezed,Object? authorizationEndpoint = freezed,Object? bearerToken = freezed,Object? useHttp2 = null,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,tokenEndpoint: freezed == tokenEndpoint ? _self.tokenEndpoint : tokenEndpoint // ignore: cast_nullable_to_non_nullable
as String?,authorizationEndpoint: freezed == authorizationEndpoint ? _self.authorizationEndpoint : authorizationEndpoint // ignore: cast_nullable_to_non_nullable
as String?,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerEntity].
extension McpServerEntityPatterns on McpServerEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerEntity value)  $default,){
final _that = this;
switch (_that) {
case _McpServerEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerEntity value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2,  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2,  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _McpServerEntity():
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2,  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerEntity extends McpServerEntity {
  const _McpServerEntity({required this.id, required this.workspaceId, required this.name, required this.url, required this.transport, required this.authenticationType, required this.createdAt, required this.updatedAt, this.description, this.clientId, this.tokenEndpoint, this.authorizationEndpoint, this.bearerToken, this.useHttp2 = false, this.isEnabled = true}): super._();
  

/// Unique ID of this MCP server record in the database
@override final  String id;
/// ID of the workspace this MCP server belongs to
@override final  String workspaceId;
/// User-friendly name for the MCP server
@override final  String name;
/// URL endpoint for the MCP server
@override final  String url;
/// Transport type used for communication
@override final  McpTransportType transport;
/// Authentication type for the MCP server
@override final  McpAuthenticationType authenticationType;
/// Timestamp when this configuration was created
@override final  DateTime createdAt;
/// Timestamp when this configuration was last updated
@override final  DateTime updatedAt;
/// Optional description of what this MCP server provides
@override final  String? description;
/// OAuth client ID (required when authenticationType is oauth)
@override final  String? clientId;
/// OAuth token endpoint URL (required when authenticationType is oauth)
@override final  String? tokenEndpoint;
/// OAuth authorization endpoint URL
/// (required when authenticationType is oauth)
@override final  String? authorizationEndpoint;
/// Bearer token (required when authenticationType is bearerToken)
@override final  String? bearerToken;
/// Whether to use HTTP/2 (only applicable for streamableHttp transport)
@override@JsonKey() final  bool useHttp2;
/// Whether the MCP server is enabled
@override@JsonKey() final  bool isEnabled;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerEntityCopyWith<_McpServerEntity> get copyWith => __$McpServerEntityCopyWithImpl<_McpServerEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.tokenEndpoint, tokenEndpoint) || other.tokenEndpoint == tokenEndpoint)&&(identical(other.authorizationEndpoint, authorizationEndpoint) || other.authorizationEndpoint == authorizationEndpoint)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,url,transport,authenticationType,createdAt,updatedAt,description,clientId,tokenEndpoint,authorizationEndpoint,bearerToken,useHttp2,isEnabled);

@override
String toString() {
  return 'McpServerEntity(id: $id, workspaceId: $workspaceId, name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, clientId: $clientId, tokenEndpoint: $tokenEndpoint, authorizationEndpoint: $authorizationEndpoint, bearerToken: $bearerToken, useHttp2: $useHttp2, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$McpServerEntityCopyWith<$Res> implements $McpServerEntityCopyWith<$Res> {
  factory _$McpServerEntityCopyWith(_McpServerEntity value, $Res Function(_McpServerEntity) _then) = __$McpServerEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, DateTime createdAt, DateTime updatedAt, String? description, String? clientId, String? tokenEndpoint, String? authorizationEndpoint, String? bearerToken, bool useHttp2, bool isEnabled
});




}
/// @nodoc
class __$McpServerEntityCopyWithImpl<$Res>
    implements _$McpServerEntityCopyWith<$Res> {
  __$McpServerEntityCopyWithImpl(this._self, this._then);

  final _McpServerEntity _self;
  final $Res Function(_McpServerEntity) _then;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? clientId = freezed,Object? tokenEndpoint = freezed,Object? authorizationEndpoint = freezed,Object? bearerToken = freezed,Object? useHttp2 = null,Object? isEnabled = null,}) {
  return _then(_McpServerEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,tokenEndpoint: freezed == tokenEndpoint ? _self.tokenEndpoint : tokenEndpoint // ignore: cast_nullable_to_non_nullable
as String?,authorizationEndpoint: freezed == authorizationEndpoint ? _self.authorizationEndpoint : authorizationEndpoint // ignore: cast_nullable_to_non_nullable
as String?,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$McpServerToCreate {

/// User-friendly name for the MCP server
 String get name;/// URL endpoint for the MCP server
 String get url;/// Transport type used for communication
 McpTransportType get transport;/// Authentication type for the MCP server
 McpAuthenticationType get authenticationType;/// Optional description of what this MCP server provides
 String? get description;/// OAuth client ID (required when authenticationType is oauth)
 String? get clientId;/// OAuth token endpoint URL (required when authenticationType is oauth)
 String? get tokenEndpoint;/// OAuth authorization endpoint URL
/// (required when authenticationType is oauth)
 String? get authorizationEndpoint;/// Bearer token (required when authenticationType is bearerToken)
 String? get bearerToken;/// Whether to use HTTP/2 (only applicable for streamableHttp transport)
 bool get useHttp2;
/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerToCreateCopyWith<McpServerToCreate> get copyWith => _$McpServerToCreateCopyWithImpl<McpServerToCreate>(this as McpServerToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.description, description) || other.description == description)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.tokenEndpoint, tokenEndpoint) || other.tokenEndpoint == tokenEndpoint)&&(identical(other.authorizationEndpoint, authorizationEndpoint) || other.authorizationEndpoint == authorizationEndpoint)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,description,clientId,tokenEndpoint,authorizationEndpoint,bearerToken,useHttp2);

@override
String toString() {
  return 'McpServerToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, description: $description, clientId: $clientId, tokenEndpoint: $tokenEndpoint, authorizationEndpoint: $authorizationEndpoint, bearerToken: $bearerToken, useHttp2: $useHttp2)';
}


}

/// @nodoc
abstract mixin class $McpServerToCreateCopyWith<$Res>  {
  factory $McpServerToCreateCopyWith(McpServerToCreate value, $Res Function(McpServerToCreate) _then) = _$McpServerToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, String? description, String? clientId, String? tokenEndpoint, String? authorizationEndpoint, String? bearerToken, bool useHttp2
});




}
/// @nodoc
class _$McpServerToCreateCopyWithImpl<$Res>
    implements $McpServerToCreateCopyWith<$Res> {
  _$McpServerToCreateCopyWithImpl(this._self, this._then);

  final McpServerToCreate _self;
  final $Res Function(McpServerToCreate) _then;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? description = freezed,Object? clientId = freezed,Object? tokenEndpoint = freezed,Object? authorizationEndpoint = freezed,Object? bearerToken = freezed,Object? useHttp2 = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,tokenEndpoint: freezed == tokenEndpoint ? _self.tokenEndpoint : tokenEndpoint // ignore: cast_nullable_to_non_nullable
as String?,authorizationEndpoint: freezed == authorizationEndpoint ? _self.authorizationEndpoint : authorizationEndpoint // ignore: cast_nullable_to_non_nullable
as String?,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerToCreate].
extension McpServerToCreatePatterns on McpServerToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerToCreate value)  $default,){
final _that = this;
switch (_that) {
case _McpServerToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2)  $default,) {final _that = this;
switch (_that) {
case _McpServerToCreate():
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description,  String? clientId,  String? tokenEndpoint,  String? authorizationEndpoint,  String? bearerToken,  bool useHttp2)?  $default,) {final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description,_that.clientId,_that.tokenEndpoint,_that.authorizationEndpoint,_that.bearerToken,_that.useHttp2);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerToCreate extends McpServerToCreate {
  const _McpServerToCreate({required this.name, required this.url, required this.transport, required this.authenticationType, this.description, this.clientId, this.tokenEndpoint, this.authorizationEndpoint, this.bearerToken, this.useHttp2 = false}): super._();
  

/// User-friendly name for the MCP server
@override final  String name;
/// URL endpoint for the MCP server
@override final  String url;
/// Transport type used for communication
@override final  McpTransportType transport;
/// Authentication type for the MCP server
@override final  McpAuthenticationType authenticationType;
/// Optional description of what this MCP server provides
@override final  String? description;
/// OAuth client ID (required when authenticationType is oauth)
@override final  String? clientId;
/// OAuth token endpoint URL (required when authenticationType is oauth)
@override final  String? tokenEndpoint;
/// OAuth authorization endpoint URL
/// (required when authenticationType is oauth)
@override final  String? authorizationEndpoint;
/// Bearer token (required when authenticationType is bearerToken)
@override final  String? bearerToken;
/// Whether to use HTTP/2 (only applicable for streamableHttp transport)
@override@JsonKey() final  bool useHttp2;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerToCreateCopyWith<_McpServerToCreate> get copyWith => __$McpServerToCreateCopyWithImpl<_McpServerToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.description, description) || other.description == description)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.tokenEndpoint, tokenEndpoint) || other.tokenEndpoint == tokenEndpoint)&&(identical(other.authorizationEndpoint, authorizationEndpoint) || other.authorizationEndpoint == authorizationEndpoint)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,description,clientId,tokenEndpoint,authorizationEndpoint,bearerToken,useHttp2);

@override
String toString() {
  return 'McpServerToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, description: $description, clientId: $clientId, tokenEndpoint: $tokenEndpoint, authorizationEndpoint: $authorizationEndpoint, bearerToken: $bearerToken, useHttp2: $useHttp2)';
}


}

/// @nodoc
abstract mixin class _$McpServerToCreateCopyWith<$Res> implements $McpServerToCreateCopyWith<$Res> {
  factory _$McpServerToCreateCopyWith(_McpServerToCreate value, $Res Function(_McpServerToCreate) _then) = __$McpServerToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, String? description, String? clientId, String? tokenEndpoint, String? authorizationEndpoint, String? bearerToken, bool useHttp2
});




}
/// @nodoc
class __$McpServerToCreateCopyWithImpl<$Res>
    implements _$McpServerToCreateCopyWith<$Res> {
  __$McpServerToCreateCopyWithImpl(this._self, this._then);

  final _McpServerToCreate _self;
  final $Res Function(_McpServerToCreate) _then;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? description = freezed,Object? clientId = freezed,Object? tokenEndpoint = freezed,Object? authorizationEndpoint = freezed,Object? bearerToken = freezed,Object? useHttp2 = null,}) {
  return _then(_McpServerToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,tokenEndpoint: freezed == tokenEndpoint ? _self.tokenEndpoint : tokenEndpoint // ignore: cast_nullable_to_non_nullable
as String?,authorizationEndpoint: freezed == authorizationEndpoint ? _self.authorizationEndpoint : authorizationEndpoint // ignore: cast_nullable_to_non_nullable
as String?,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
