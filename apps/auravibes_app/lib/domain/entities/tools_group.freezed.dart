// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tools_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToolsGroupEntity {

/// Unique ID of this tools group record in the database
 String get id;/// ID of the workspace this tools group belongs to
 String get workspaceId;/// Name of the tools group
 String get name;/// Whether the tools group is enabled for this workspace
 bool get isEnabled;/// Permission mode for tools in this group
 PermissionAccess get permissions;/// Timestamp when this group was created
 DateTime get createdAt;/// Timestamp when this group was last updated
 DateTime get updatedAt;/// Optional reference to the MCP server this group belongs to.
/// If set, this group represents tools from an MCP server.
 String? get mcpServerId;
/// Create a copy of ToolsGroupEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolsGroupEntityCopyWith<ToolsGroupEntity> get copyWith => _$ToolsGroupEntityCopyWithImpl<ToolsGroupEntity>(this as ToolsGroupEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolsGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,isEnabled,permissions,createdAt,updatedAt,mcpServerId);

@override
String toString() {
  return 'ToolsGroupEntity(id: $id, workspaceId: $workspaceId, name: $name, isEnabled: $isEnabled, permissions: $permissions, createdAt: $createdAt, updatedAt: $updatedAt, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class $ToolsGroupEntityCopyWith<$Res>  {
  factory $ToolsGroupEntityCopyWith(ToolsGroupEntity value, $Res Function(ToolsGroupEntity) _then) = _$ToolsGroupEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, bool isEnabled, PermissionAccess permissions, DateTime createdAt, DateTime updatedAt, String? mcpServerId
});




}
/// @nodoc
class _$ToolsGroupEntityCopyWithImpl<$Res>
    implements $ToolsGroupEntityCopyWith<$Res> {
  _$ToolsGroupEntityCopyWithImpl(this._self, this._then);

  final ToolsGroupEntity _self;
  final $Res Function(ToolsGroupEntity) _then;

/// Create a copy of ToolsGroupEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? isEnabled = null,Object? permissions = null,Object? createdAt = null,Object? updatedAt = null,Object? mcpServerId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as PermissionAccess,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mcpServerId: freezed == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolsGroupEntity].
extension ToolsGroupEntityPatterns on ToolsGroupEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolsGroupEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolsGroupEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolsGroupEntity value)  $default,){
final _that = this;
switch (_that) {
case _ToolsGroupEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolsGroupEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ToolsGroupEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  bool isEnabled,  PermissionAccess permissions,  DateTime createdAt,  DateTime updatedAt,  String? mcpServerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolsGroupEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.isEnabled,_that.permissions,_that.createdAt,_that.updatedAt,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  bool isEnabled,  PermissionAccess permissions,  DateTime createdAt,  DateTime updatedAt,  String? mcpServerId)  $default,) {final _that = this;
switch (_that) {
case _ToolsGroupEntity():
return $default(_that.id,_that.workspaceId,_that.name,_that.isEnabled,_that.permissions,_that.createdAt,_that.updatedAt,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  bool isEnabled,  PermissionAccess permissions,  DateTime createdAt,  DateTime updatedAt,  String? mcpServerId)?  $default,) {final _that = this;
switch (_that) {
case _ToolsGroupEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.isEnabled,_that.permissions,_that.createdAt,_that.updatedAt,_that.mcpServerId);case _:
  return null;

}
}

}

/// @nodoc


class _ToolsGroupEntity extends ToolsGroupEntity {
  const _ToolsGroupEntity({required this.id, required this.workspaceId, required this.name, required this.isEnabled, required this.permissions, required this.createdAt, required this.updatedAt, this.mcpServerId}): super._();
  

/// Unique ID of this tools group record in the database
@override final  String id;
/// ID of the workspace this tools group belongs to
@override final  String workspaceId;
/// Name of the tools group
@override final  String name;
/// Whether the tools group is enabled for this workspace
@override final  bool isEnabled;
/// Permission mode for tools in this group
@override final  PermissionAccess permissions;
/// Timestamp when this group was created
@override final  DateTime createdAt;
/// Timestamp when this group was last updated
@override final  DateTime updatedAt;
/// Optional reference to the MCP server this group belongs to.
/// If set, this group represents tools from an MCP server.
@override final  String? mcpServerId;

/// Create a copy of ToolsGroupEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolsGroupEntityCopyWith<_ToolsGroupEntity> get copyWith => __$ToolsGroupEntityCopyWithImpl<_ToolsGroupEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolsGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,isEnabled,permissions,createdAt,updatedAt,mcpServerId);

@override
String toString() {
  return 'ToolsGroupEntity(id: $id, workspaceId: $workspaceId, name: $name, isEnabled: $isEnabled, permissions: $permissions, createdAt: $createdAt, updatedAt: $updatedAt, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class _$ToolsGroupEntityCopyWith<$Res> implements $ToolsGroupEntityCopyWith<$Res> {
  factory _$ToolsGroupEntityCopyWith(_ToolsGroupEntity value, $Res Function(_ToolsGroupEntity) _then) = __$ToolsGroupEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, bool isEnabled, PermissionAccess permissions, DateTime createdAt, DateTime updatedAt, String? mcpServerId
});




}
/// @nodoc
class __$ToolsGroupEntityCopyWithImpl<$Res>
    implements _$ToolsGroupEntityCopyWith<$Res> {
  __$ToolsGroupEntityCopyWithImpl(this._self, this._then);

  final _ToolsGroupEntity _self;
  final $Res Function(_ToolsGroupEntity) _then;

/// Create a copy of ToolsGroupEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? isEnabled = null,Object? permissions = null,Object? createdAt = null,Object? updatedAt = null,Object? mcpServerId = freezed,}) {
  return _then(_ToolsGroupEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as PermissionAccess,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mcpServerId: freezed == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ToolsGroupToCreate {

/// Name of the tools group
 String get name;/// Whether the tools group should be enabled (defaults to true)
 bool get isEnabled;/// Permission mode for tools in this group (defaults to ask)
 PermissionAccess get permissions;/// Optional reference to the MCP server this group belongs to
 String? get mcpServerId;
/// Create a copy of ToolsGroupToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolsGroupToCreateCopyWith<ToolsGroupToCreate> get copyWith => _$ToolsGroupToCreateCopyWithImpl<ToolsGroupToCreate>(this as ToolsGroupToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolsGroupToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,name,isEnabled,permissions,mcpServerId);

@override
String toString() {
  return 'ToolsGroupToCreate(name: $name, isEnabled: $isEnabled, permissions: $permissions, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class $ToolsGroupToCreateCopyWith<$Res>  {
  factory $ToolsGroupToCreateCopyWith(ToolsGroupToCreate value, $Res Function(ToolsGroupToCreate) _then) = _$ToolsGroupToCreateCopyWithImpl;
@useResult
$Res call({
 String name, bool isEnabled, PermissionAccess permissions, String? mcpServerId
});




}
/// @nodoc
class _$ToolsGroupToCreateCopyWithImpl<$Res>
    implements $ToolsGroupToCreateCopyWith<$Res> {
  _$ToolsGroupToCreateCopyWithImpl(this._self, this._then);

  final ToolsGroupToCreate _self;
  final $Res Function(ToolsGroupToCreate) _then;

/// Create a copy of ToolsGroupToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? isEnabled = null,Object? permissions = null,Object? mcpServerId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as PermissionAccess,mcpServerId: freezed == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolsGroupToCreate].
extension ToolsGroupToCreatePatterns on ToolsGroupToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolsGroupToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolsGroupToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolsGroupToCreate value)  $default,){
final _that = this;
switch (_that) {
case _ToolsGroupToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolsGroupToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ToolsGroupToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool isEnabled,  PermissionAccess permissions,  String? mcpServerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolsGroupToCreate() when $default != null:
return $default(_that.name,_that.isEnabled,_that.permissions,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool isEnabled,  PermissionAccess permissions,  String? mcpServerId)  $default,) {final _that = this;
switch (_that) {
case _ToolsGroupToCreate():
return $default(_that.name,_that.isEnabled,_that.permissions,_that.mcpServerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool isEnabled,  PermissionAccess permissions,  String? mcpServerId)?  $default,) {final _that = this;
switch (_that) {
case _ToolsGroupToCreate() when $default != null:
return $default(_that.name,_that.isEnabled,_that.permissions,_that.mcpServerId);case _:
  return null;

}
}

}

/// @nodoc


class _ToolsGroupToCreate extends ToolsGroupToCreate {
  const _ToolsGroupToCreate({required this.name, this.isEnabled = true, this.permissions = PermissionAccess.ask, this.mcpServerId}): super._();
  

/// Name of the tools group
@override final  String name;
/// Whether the tools group should be enabled (defaults to true)
@override@JsonKey() final  bool isEnabled;
/// Permission mode for tools in this group (defaults to ask)
@override@JsonKey() final  PermissionAccess permissions;
/// Optional reference to the MCP server this group belongs to
@override final  String? mcpServerId;

/// Create a copy of ToolsGroupToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolsGroupToCreateCopyWith<_ToolsGroupToCreate> get copyWith => __$ToolsGroupToCreateCopyWithImpl<_ToolsGroupToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolsGroupToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.mcpServerId, mcpServerId) || other.mcpServerId == mcpServerId));
}


@override
int get hashCode => Object.hash(runtimeType,name,isEnabled,permissions,mcpServerId);

@override
String toString() {
  return 'ToolsGroupToCreate(name: $name, isEnabled: $isEnabled, permissions: $permissions, mcpServerId: $mcpServerId)';
}


}

/// @nodoc
abstract mixin class _$ToolsGroupToCreateCopyWith<$Res> implements $ToolsGroupToCreateCopyWith<$Res> {
  factory _$ToolsGroupToCreateCopyWith(_ToolsGroupToCreate value, $Res Function(_ToolsGroupToCreate) _then) = __$ToolsGroupToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, bool isEnabled, PermissionAccess permissions, String? mcpServerId
});




}
/// @nodoc
class __$ToolsGroupToCreateCopyWithImpl<$Res>
    implements _$ToolsGroupToCreateCopyWith<$Res> {
  __$ToolsGroupToCreateCopyWithImpl(this._self, this._then);

  final _ToolsGroupToCreate _self;
  final $Res Function(_ToolsGroupToCreate) _then;

/// Create a copy of ToolsGroupToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? isEnabled = null,Object? permissions = null,Object? mcpServerId = freezed,}) {
  return _then(_ToolsGroupToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as PermissionAccess,mcpServerId: freezed == mcpServerId ? _self.mcpServerId : mcpServerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
