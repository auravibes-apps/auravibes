// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_execution_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackedToolCall {

 String get id; String get toolName; String get messageId; bool get isRunning;
/// Create a copy of TrackedToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackedToolCallCopyWith<TrackedToolCall> get copyWith => _$TrackedToolCallCopyWithImpl<TrackedToolCall>(this as TrackedToolCall, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackedToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning));
}


@override
int get hashCode => Object.hash(runtimeType,id,toolName,messageId,isRunning);

@override
String toString() {
  return 'TrackedToolCall(id: $id, toolName: $toolName, messageId: $messageId, isRunning: $isRunning)';
}


}

/// @nodoc
abstract mixin class $TrackedToolCallCopyWith<$Res>  {
  factory $TrackedToolCallCopyWith(TrackedToolCall value, $Res Function(TrackedToolCall) _then) = _$TrackedToolCallCopyWithImpl;
@useResult
$Res call({
 String id, String toolName, String messageId, bool isRunning
});




}
/// @nodoc
class _$TrackedToolCallCopyWithImpl<$Res>
    implements $TrackedToolCallCopyWith<$Res> {
  _$TrackedToolCallCopyWithImpl(this._self, this._then);

  final TrackedToolCall _self;
  final $Res Function(TrackedToolCall) _then;

/// Create a copy of TrackedToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? toolName = null,Object? messageId = null,Object? isRunning = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackedToolCall].
extension TrackedToolCallPatterns on TrackedToolCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackedToolCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackedToolCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackedToolCall value)  $default,){
final _that = this;
switch (_that) {
case _TrackedToolCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackedToolCall value)?  $default,){
final _that = this;
switch (_that) {
case _TrackedToolCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String toolName,  String messageId,  bool isRunning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackedToolCall() when $default != null:
return $default(_that.id,_that.toolName,_that.messageId,_that.isRunning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String toolName,  String messageId,  bool isRunning)  $default,) {final _that = this;
switch (_that) {
case _TrackedToolCall():
return $default(_that.id,_that.toolName,_that.messageId,_that.isRunning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String toolName,  String messageId,  bool isRunning)?  $default,) {final _that = this;
switch (_that) {
case _TrackedToolCall() when $default != null:
return $default(_that.id,_that.toolName,_that.messageId,_that.isRunning);case _:
  return null;

}
}

}

/// @nodoc


class _TrackedToolCall implements TrackedToolCall {
  const _TrackedToolCall({required this.id, required this.toolName, required this.messageId, required this.isRunning});
  

@override final  String id;
@override final  String toolName;
@override final  String messageId;
@override final  bool isRunning;

/// Create a copy of TrackedToolCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackedToolCallCopyWith<_TrackedToolCall> get copyWith => __$TrackedToolCallCopyWithImpl<_TrackedToolCall>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackedToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning));
}


@override
int get hashCode => Object.hash(runtimeType,id,toolName,messageId,isRunning);

@override
String toString() {
  return 'TrackedToolCall(id: $id, toolName: $toolName, messageId: $messageId, isRunning: $isRunning)';
}


}

/// @nodoc
abstract mixin class _$TrackedToolCallCopyWith<$Res> implements $TrackedToolCallCopyWith<$Res> {
  factory _$TrackedToolCallCopyWith(_TrackedToolCall value, $Res Function(_TrackedToolCall) _then) = __$TrackedToolCallCopyWithImpl;
@override @useResult
$Res call({
 String id, String toolName, String messageId, bool isRunning
});




}
/// @nodoc
class __$TrackedToolCallCopyWithImpl<$Res>
    implements _$TrackedToolCallCopyWith<$Res> {
  __$TrackedToolCallCopyWithImpl(this._self, this._then);

  final _TrackedToolCall _self;
  final $Res Function(_TrackedToolCall) _then;

/// Create a copy of TrackedToolCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? toolName = null,Object? messageId = null,Object? isRunning = null,}) {
  return _then(_TrackedToolCall(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
