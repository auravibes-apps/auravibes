// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceEntity {

/// Unique identifier for the workspace.
 String get id;/// Human-readable name of the workspace.
 String get name;/// Type of workspace (local or remote).
 WorkspaceType get type;/// Timestamp when the workspace was created.
 DateTime get createdAt;/// Timestamp when the workspace was last updated.
 DateTime get updatedAt;/// URL for remote workspaces, null for local workspaces.
 String? get url;/// Cloud workspace identifier for mirrored cloud workspaces.
 String? get cloudWorkspaceId;/// Cloud account identifier used to access this local mirror.
 String? get cloudAccountId;
/// Create a copy of WorkspaceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceEntityCopyWith<WorkspaceEntity> get copyWith => _$WorkspaceEntityCopyWithImpl<WorkspaceEntity>(this as WorkspaceEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkspaceEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.cloudWorkspaceId, _this.cloudWorkspaceId) || other.cloudWorkspaceId == _this.cloudWorkspaceId)&&(identical(other.cloudAccountId, _this.cloudAccountId) || other.cloudAccountId == _this.cloudAccountId));
}


@override
int get hashCode {
  final _this = this as WorkspaceEntity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.createdAt,_this.updatedAt,_this.url,_this.cloudWorkspaceId,_this.cloudAccountId);
}

@override
String toString() {
  final _this = this as WorkspaceEntity;
  return 'WorkspaceEntity(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, url: ${_this.url}, cloudWorkspaceId: ${_this.cloudWorkspaceId}, cloudAccountId: ${_this.cloudAccountId})';
}


}

/// @nodoc
abstract mixin class $WorkspaceEntityCopyWith<$Res>  {
  factory $WorkspaceEntityCopyWith(WorkspaceEntity value, $Res Function(WorkspaceEntity) _then) = _$WorkspaceEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, WorkspaceType type, DateTime createdAt, DateTime updatedAt, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class _$WorkspaceEntityCopyWithImpl<$Res>
    implements $WorkspaceEntityCopyWith<$Res> {
  _$WorkspaceEntityCopyWithImpl(this._self, this._then);

  final WorkspaceEntity _self;
  final $Res Function(WorkspaceEntity) _then;

/// Create a copy of WorkspaceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(WorkspaceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceEntity].
extension WorkspaceEntityPatterns on WorkspaceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  WorkspaceType type,  DateTime createdAt,  DateTime updatedAt,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.createdAt,_that.updatedAt,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  WorkspaceType type,  DateTime createdAt,  DateTime updatedAt,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceEntity():
return $default(_that.id,_that.name,_that.type,_that.createdAt,_that.updatedAt,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  WorkspaceType type,  DateTime createdAt,  DateTime updatedAt,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.createdAt,_that.updatedAt,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceEntity extends WorkspaceEntity {
  const _WorkspaceEntity({required this.id, required this.name, required this.type, required this.createdAt, required this.updatedAt, this.url, this.cloudWorkspaceId, this.cloudAccountId}): super._();
  

/// Unique identifier for the workspace.
@override final  String id;
/// Human-readable name of the workspace.
@override final  String name;
/// Type of workspace (local or remote).
@override final  WorkspaceType type;
/// Timestamp when the workspace was created.
@override final  DateTime createdAt;
/// Timestamp when the workspace was last updated.
@override final  DateTime updatedAt;
/// URL for remote workspaces, null for local workspaces.
@override final  String? url;
/// Cloud workspace identifier for mirrored cloud workspaces.
@override final  String? cloudWorkspaceId;
/// Cloud account identifier used to access this local mirror.
@override final  String? cloudAccountId;

/// Create a copy of WorkspaceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceEntityCopyWith<_WorkspaceEntity> get copyWith => __$WorkspaceEntityCopyWithImpl<_WorkspaceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.url, url) || other.url == url)&&(identical(other.cloudWorkspaceId, cloudWorkspaceId) || other.cloudWorkspaceId == cloudWorkspaceId)&&(identical(other.cloudAccountId, cloudAccountId) || other.cloudAccountId == cloudAccountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,createdAt,updatedAt,url,cloudWorkspaceId,cloudAccountId);
}

@override
String toString() {
    return 'WorkspaceEntity(id: $id, name: $name, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, url: $url, cloudWorkspaceId: $cloudWorkspaceId, cloudAccountId: $cloudAccountId)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceEntityCopyWith<$Res> implements $WorkspaceEntityCopyWith<$Res> {
  factory _$WorkspaceEntityCopyWith(_WorkspaceEntity value, $Res Function(_WorkspaceEntity) _then) = __$WorkspaceEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, WorkspaceType type, DateTime createdAt, DateTime updatedAt, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class __$WorkspaceEntityCopyWithImpl<$Res>
    implements _$WorkspaceEntityCopyWith<$Res> {
  __$WorkspaceEntityCopyWithImpl(this._self, this._then);

  final _WorkspaceEntity _self;
  final $Res Function(_WorkspaceEntity) _then;

/// Create a copy of WorkspaceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(_WorkspaceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$WorkspaceToCreate {

/// Human-readable name of the workspace.
 String get name;/// Type of workspace (local or remote).
 WorkspaceType get type;/// URL for remote workspaces, null for local workspaces.
 String? get url;/// Cloud workspace identifier for mirrored cloud workspaces.
 String? get cloudWorkspaceId;/// Cloud account identifier that owns this local mirror.
 String? get cloudAccountId;
/// Create a copy of WorkspaceToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceToCreateCopyWith<WorkspaceToCreate> get copyWith => _$WorkspaceToCreateCopyWithImpl<WorkspaceToCreate>(this as WorkspaceToCreate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkspaceToCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceToCreate&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.cloudWorkspaceId, _this.cloudWorkspaceId) || other.cloudWorkspaceId == _this.cloudWorkspaceId)&&(identical(other.cloudAccountId, _this.cloudAccountId) || other.cloudAccountId == _this.cloudAccountId));
}


@override
int get hashCode {
  final _this = this as WorkspaceToCreate;
  return Object.hash(runtimeType,_this.name,_this.type,_this.url,_this.cloudWorkspaceId,_this.cloudAccountId);
}

@override
String toString() {
  final _this = this as WorkspaceToCreate;
  return 'WorkspaceToCreate(name: ${_this.name}, type: ${_this.type}, url: ${_this.url}, cloudWorkspaceId: ${_this.cloudWorkspaceId}, cloudAccountId: ${_this.cloudAccountId})';
}


}

/// @nodoc
abstract mixin class $WorkspaceToCreateCopyWith<$Res>  {
  factory $WorkspaceToCreateCopyWith(WorkspaceToCreate value, $Res Function(WorkspaceToCreate) _then) = _$WorkspaceToCreateCopyWithImpl;
@useResult
$Res call({
 String name, WorkspaceType type, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class _$WorkspaceToCreateCopyWithImpl<$Res>
    implements $WorkspaceToCreateCopyWith<$Res> {
  _$WorkspaceToCreateCopyWithImpl(this._self, this._then);

  final WorkspaceToCreate _self;
  final $Res Function(WorkspaceToCreate) _then;

/// Create a copy of WorkspaceToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(WorkspaceToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceToCreate].
extension WorkspaceToCreatePatterns on WorkspaceToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceToCreate value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  WorkspaceType type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceToCreate() when $default != null:
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  WorkspaceType type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceToCreate():
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  WorkspaceType type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceToCreate() when $default != null:
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceToCreate extends WorkspaceToCreate {
  const _WorkspaceToCreate({required this.name, required this.type, this.url, this.cloudWorkspaceId, this.cloudAccountId}): super._();
  

/// Human-readable name of the workspace.
@override final  String name;
/// Type of workspace (local or remote).
@override final  WorkspaceType type;
/// URL for remote workspaces, null for local workspaces.
@override final  String? url;
/// Cloud workspace identifier for mirrored cloud workspaces.
@override final  String? cloudWorkspaceId;
/// Cloud account identifier that owns this local mirror.
@override final  String? cloudAccountId;

/// Create a copy of WorkspaceToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceToCreateCopyWith<_WorkspaceToCreate> get copyWith => __$WorkspaceToCreateCopyWithImpl<_WorkspaceToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.cloudWorkspaceId, cloudWorkspaceId) || other.cloudWorkspaceId == cloudWorkspaceId)&&(identical(other.cloudAccountId, cloudAccountId) || other.cloudAccountId == cloudAccountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,type,url,cloudWorkspaceId,cloudAccountId);
}

@override
String toString() {
    return 'WorkspaceToCreate(name: $name, type: $type, url: $url, cloudWorkspaceId: $cloudWorkspaceId, cloudAccountId: $cloudAccountId)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceToCreateCopyWith<$Res> implements $WorkspaceToCreateCopyWith<$Res> {
  factory _$WorkspaceToCreateCopyWith(_WorkspaceToCreate value, $Res Function(_WorkspaceToCreate) _then) = __$WorkspaceToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, WorkspaceType type, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class __$WorkspaceToCreateCopyWithImpl<$Res>
    implements _$WorkspaceToCreateCopyWith<$Res> {
  __$WorkspaceToCreateCopyWithImpl(this._self, this._then);

  final _WorkspaceToCreate _self;
  final $Res Function(_WorkspaceToCreate) _then;

/// Create a copy of WorkspaceToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(_WorkspaceToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$WorkspacePatch {

 String? get name; WorkspaceType? get type; String? get url; String? get cloudWorkspaceId; String? get cloudAccountId;
/// Create a copy of WorkspacePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspacePatchCopyWith<WorkspacePatch> get copyWith => _$WorkspacePatchCopyWithImpl<WorkspacePatch>(this as WorkspacePatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkspacePatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspacePatch&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.cloudWorkspaceId, _this.cloudWorkspaceId) || other.cloudWorkspaceId == _this.cloudWorkspaceId)&&(identical(other.cloudAccountId, _this.cloudAccountId) || other.cloudAccountId == _this.cloudAccountId));
}


@override
int get hashCode {
  final _this = this as WorkspacePatch;
  return Object.hash(runtimeType,_this.name,_this.type,_this.url,_this.cloudWorkspaceId,_this.cloudAccountId);
}

@override
String toString() {
  final _this = this as WorkspacePatch;
  return 'WorkspacePatch(name: ${_this.name}, type: ${_this.type}, url: ${_this.url}, cloudWorkspaceId: ${_this.cloudWorkspaceId}, cloudAccountId: ${_this.cloudAccountId})';
}


}

/// @nodoc
abstract mixin class $WorkspacePatchCopyWith<$Res>  {
  factory $WorkspacePatchCopyWith(WorkspacePatch value, $Res Function(WorkspacePatch) _then) = _$WorkspacePatchCopyWithImpl;
@useResult
$Res call({
 String? name, WorkspaceType? type, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class _$WorkspacePatchCopyWithImpl<$Res>
    implements $WorkspacePatchCopyWith<$Res> {
  _$WorkspacePatchCopyWithImpl(this._self, this._then);

  final WorkspacePatch _self;
  final $Res Function(WorkspacePatch) _then;

/// Create a copy of WorkspacePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? type = freezed,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(WorkspacePatch(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspacePatch].
extension WorkspacePatchPatterns on WorkspacePatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspacePatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspacePatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspacePatch value)  $default,){
final _that = this;
switch (_that) {
case _WorkspacePatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspacePatch value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspacePatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  WorkspaceType? type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspacePatch() when $default != null:
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  WorkspaceType? type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)  $default,) {final _that = this;
switch (_that) {
case _WorkspacePatch():
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  WorkspaceType? type,  String? url,  String? cloudWorkspaceId,  String? cloudAccountId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspacePatch() when $default != null:
return $default(_that.name,_that.type,_that.url,_that.cloudWorkspaceId,_that.cloudAccountId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspacePatch extends WorkspacePatch {
  const _WorkspacePatch({this.name, this.type, this.url, this.cloudWorkspaceId, this.cloudAccountId}): super._();
  

@override final  String? name;
@override final  WorkspaceType? type;
@override final  String? url;
@override final  String? cloudWorkspaceId;
@override final  String? cloudAccountId;

/// Create a copy of WorkspacePatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspacePatchCopyWith<_WorkspacePatch> get copyWith => __$WorkspacePatchCopyWithImpl<_WorkspacePatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspacePatch&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.cloudWorkspaceId, cloudWorkspaceId) || other.cloudWorkspaceId == cloudWorkspaceId)&&(identical(other.cloudAccountId, cloudAccountId) || other.cloudAccountId == cloudAccountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,type,url,cloudWorkspaceId,cloudAccountId);
}

@override
String toString() {
    return 'WorkspacePatch(name: $name, type: $type, url: $url, cloudWorkspaceId: $cloudWorkspaceId, cloudAccountId: $cloudAccountId)';
}


}

/// @nodoc
abstract mixin class _$WorkspacePatchCopyWith<$Res> implements $WorkspacePatchCopyWith<$Res> {
  factory _$WorkspacePatchCopyWith(_WorkspacePatch value, $Res Function(_WorkspacePatch) _then) = __$WorkspacePatchCopyWithImpl;
@override @useResult
$Res call({
 String? name, WorkspaceType? type, String? url, String? cloudWorkspaceId, String? cloudAccountId
});




}
/// @nodoc
class __$WorkspacePatchCopyWithImpl<$Res>
    implements _$WorkspacePatchCopyWith<$Res> {
  __$WorkspacePatchCopyWithImpl(this._self, this._then);

  final _WorkspacePatch _self;
  final $Res Function(_WorkspacePatch) _then;

/// Create a copy of WorkspacePatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? type = freezed,Object? url = freezed,Object? cloudWorkspaceId = freezed,Object? cloudAccountId = freezed,}) {
  return _then(_WorkspacePatch(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,cloudWorkspaceId: freezed == cloudWorkspaceId ? _self.cloudWorkspaceId : cloudWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,cloudAccountId: freezed == cloudAccountId ? _self.cloudAccountId : cloudAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
