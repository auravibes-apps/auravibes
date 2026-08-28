// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'switch_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceSwitchState {

 SwitchStatus get status; String? get targetWorkspaceId; String? get errorLocalizationKey;
/// Create a copy of WorkspaceSwitchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceSwitchStateCopyWith<WorkspaceSwitchState> get copyWith => _$WorkspaceSwitchStateCopyWithImpl<WorkspaceSwitchState>(this as WorkspaceSwitchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceSwitchState&&(identical(other.status, status) || other.status == status)&&(identical(other.targetWorkspaceId, targetWorkspaceId) || other.targetWorkspaceId == targetWorkspaceId)&&(identical(other.errorLocalizationKey, errorLocalizationKey) || other.errorLocalizationKey == errorLocalizationKey));
}


@override
int get hashCode => Object.hash(runtimeType,status,targetWorkspaceId,errorLocalizationKey);

@override
String toString() {
  return 'WorkspaceSwitchState(status: $status, targetWorkspaceId: $targetWorkspaceId, errorLocalizationKey: $errorLocalizationKey)';
}


}

/// @nodoc
abstract mixin class $WorkspaceSwitchStateCopyWith<$Res>  {
  factory $WorkspaceSwitchStateCopyWith(WorkspaceSwitchState value, $Res Function(WorkspaceSwitchState) _then) = _$WorkspaceSwitchStateCopyWithImpl;
@useResult
$Res call({
 SwitchStatus status, String? targetWorkspaceId, String? errorLocalizationKey
});




}
/// @nodoc
class _$WorkspaceSwitchStateCopyWithImpl<$Res>
    implements $WorkspaceSwitchStateCopyWith<$Res> {
  _$WorkspaceSwitchStateCopyWithImpl(this._self, this._then);

  final WorkspaceSwitchState _self;
  final $Res Function(WorkspaceSwitchState) _then;

/// Create a copy of WorkspaceSwitchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? targetWorkspaceId = freezed,Object? errorLocalizationKey = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SwitchStatus,targetWorkspaceId: freezed == targetWorkspaceId ? _self.targetWorkspaceId : targetWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,errorLocalizationKey: freezed == errorLocalizationKey ? _self.errorLocalizationKey : errorLocalizationKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceSwitchState].
extension WorkspaceSwitchStatePatterns on WorkspaceSwitchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceSwitchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceSwitchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceSwitchState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceSwitchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceSwitchState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceSwitchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SwitchStatus status,  String? targetWorkspaceId,  String? errorLocalizationKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceSwitchState() when $default != null:
return $default(_that.status,_that.targetWorkspaceId,_that.errorLocalizationKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SwitchStatus status,  String? targetWorkspaceId,  String? errorLocalizationKey)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceSwitchState():
return $default(_that.status,_that.targetWorkspaceId,_that.errorLocalizationKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SwitchStatus status,  String? targetWorkspaceId,  String? errorLocalizationKey)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceSwitchState() when $default != null:
return $default(_that.status,_that.targetWorkspaceId,_that.errorLocalizationKey);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceSwitchState implements WorkspaceSwitchState {
  const _WorkspaceSwitchState({this.status = SwitchStatus.idle, this.targetWorkspaceId, this.errorLocalizationKey});
  

@override@JsonKey() final  SwitchStatus status;
@override final  String? targetWorkspaceId;
@override final  String? errorLocalizationKey;

/// Create a copy of WorkspaceSwitchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceSwitchStateCopyWith<_WorkspaceSwitchState> get copyWith => __$WorkspaceSwitchStateCopyWithImpl<_WorkspaceSwitchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceSwitchState&&(identical(other.status, status) || other.status == status)&&(identical(other.targetWorkspaceId, targetWorkspaceId) || other.targetWorkspaceId == targetWorkspaceId)&&(identical(other.errorLocalizationKey, errorLocalizationKey) || other.errorLocalizationKey == errorLocalizationKey));
}


@override
int get hashCode => Object.hash(runtimeType,status,targetWorkspaceId,errorLocalizationKey);

@override
String toString() {
  return 'WorkspaceSwitchState(status: $status, targetWorkspaceId: $targetWorkspaceId, errorLocalizationKey: $errorLocalizationKey)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceSwitchStateCopyWith<$Res> implements $WorkspaceSwitchStateCopyWith<$Res> {
  factory _$WorkspaceSwitchStateCopyWith(_WorkspaceSwitchState value, $Res Function(_WorkspaceSwitchState) _then) = __$WorkspaceSwitchStateCopyWithImpl;
@override @useResult
$Res call({
 SwitchStatus status, String? targetWorkspaceId, String? errorLocalizationKey
});




}
/// @nodoc
class __$WorkspaceSwitchStateCopyWithImpl<$Res>
    implements _$WorkspaceSwitchStateCopyWith<$Res> {
  __$WorkspaceSwitchStateCopyWithImpl(this._self, this._then);

  final _WorkspaceSwitchState _self;
  final $Res Function(_WorkspaceSwitchState) _then;

/// Create a copy of WorkspaceSwitchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? targetWorkspaceId = freezed,Object? errorLocalizationKey = freezed,}) {
  return _then(_WorkspaceSwitchState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SwitchStatus,targetWorkspaceId: freezed == targetWorkspaceId ? _self.targetWorkspaceId : targetWorkspaceId // ignore: cast_nullable_to_non_nullable
as String?,errorLocalizationKey: freezed == errorLocalizationKey ? _self.errorLocalizationKey : errorLocalizationKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
