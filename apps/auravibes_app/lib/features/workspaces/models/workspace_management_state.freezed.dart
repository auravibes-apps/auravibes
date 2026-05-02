// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_management_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceManagementState {

 ManagementMode get mode; WorkspaceEntity? get editingWorkspace;
/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceManagementStateCopyWith<WorkspaceManagementState> get copyWith => _$WorkspaceManagementStateCopyWithImpl<WorkspaceManagementState>(this as WorkspaceManagementState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceManagementState&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.editingWorkspace, editingWorkspace) || other.editingWorkspace == editingWorkspace));
}


@override
int get hashCode => Object.hash(runtimeType,mode,editingWorkspace);

@override
String toString() {
  return 'WorkspaceManagementState(mode: $mode, editingWorkspace: $editingWorkspace)';
}


}

/// @nodoc
abstract mixin class $WorkspaceManagementStateCopyWith<$Res>  {
  factory $WorkspaceManagementStateCopyWith(WorkspaceManagementState value, $Res Function(WorkspaceManagementState) _then) = _$WorkspaceManagementStateCopyWithImpl;
@useResult
$Res call({
 ManagementMode mode, WorkspaceEntity? editingWorkspace
});


$WorkspaceEntityCopyWith<$Res>? get editingWorkspace;

}
/// @nodoc
class _$WorkspaceManagementStateCopyWithImpl<$Res>
    implements $WorkspaceManagementStateCopyWith<$Res> {
  _$WorkspaceManagementStateCopyWithImpl(this._self, this._then);

  final WorkspaceManagementState _self;
  final $Res Function(WorkspaceManagementState) _then;

/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? editingWorkspace = freezed,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ManagementMode,editingWorkspace: freezed == editingWorkspace ? _self.editingWorkspace : editingWorkspace // ignore: cast_nullable_to_non_nullable
as WorkspaceEntity?,
  ));
}
/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceEntityCopyWith<$Res>? get editingWorkspace {
    if (_self.editingWorkspace == null) {
    return null;
  }

  return $WorkspaceEntityCopyWith<$Res>(_self.editingWorkspace!, (value) {
    return _then(_self.copyWith(editingWorkspace: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceManagementState].
extension WorkspaceManagementStatePatterns on WorkspaceManagementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceManagementState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceManagementState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceManagementState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceManagementState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceManagementState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceManagementState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ManagementMode mode,  WorkspaceEntity? editingWorkspace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceManagementState() when $default != null:
return $default(_that.mode,_that.editingWorkspace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ManagementMode mode,  WorkspaceEntity? editingWorkspace)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceManagementState():
return $default(_that.mode,_that.editingWorkspace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ManagementMode mode,  WorkspaceEntity? editingWorkspace)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceManagementState() when $default != null:
return $default(_that.mode,_that.editingWorkspace);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceManagementState extends WorkspaceManagementState {
  const _WorkspaceManagementState({this.mode = ManagementMode.list, this.editingWorkspace}): super._();
  

@override@JsonKey() final  ManagementMode mode;
@override final  WorkspaceEntity? editingWorkspace;

/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceManagementStateCopyWith<_WorkspaceManagementState> get copyWith => __$WorkspaceManagementStateCopyWithImpl<_WorkspaceManagementState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceManagementState&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.editingWorkspace, editingWorkspace) || other.editingWorkspace == editingWorkspace));
}


@override
int get hashCode => Object.hash(runtimeType,mode,editingWorkspace);

@override
String toString() {
  return 'WorkspaceManagementState(mode: $mode, editingWorkspace: $editingWorkspace)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceManagementStateCopyWith<$Res> implements $WorkspaceManagementStateCopyWith<$Res> {
  factory _$WorkspaceManagementStateCopyWith(_WorkspaceManagementState value, $Res Function(_WorkspaceManagementState) _then) = __$WorkspaceManagementStateCopyWithImpl;
@override @useResult
$Res call({
 ManagementMode mode, WorkspaceEntity? editingWorkspace
});


@override $WorkspaceEntityCopyWith<$Res>? get editingWorkspace;

}
/// @nodoc
class __$WorkspaceManagementStateCopyWithImpl<$Res>
    implements _$WorkspaceManagementStateCopyWith<$Res> {
  __$WorkspaceManagementStateCopyWithImpl(this._self, this._then);

  final _WorkspaceManagementState _self;
  final $Res Function(_WorkspaceManagementState) _then;

/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? editingWorkspace = freezed,}) {
  return _then(_WorkspaceManagementState(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ManagementMode,editingWorkspace: freezed == editingWorkspace ? _self.editingWorkspace : editingWorkspace // ignore: cast_nullable_to_non_nullable
as WorkspaceEntity?,
  ));
}

/// Create a copy of WorkspaceManagementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceEntityCopyWith<$Res>? get editingWorkspace {
    if (_self.editingWorkspace == null) {
    return null;
  }

  return $WorkspaceEntityCopyWith<$Res>(_self.editingWorkspace!, (value) {
    return _then(_self.copyWith(editingWorkspace: value));
  });
}
}

// dart format on
