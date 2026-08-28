// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messages_streaming_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MessagesStreamingState {

 CompositeSubscription get streamSubscription; ChatResult<ChatMessage>? get lastResult;
/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagesStreamingStateCopyWith<MessagesStreamingState> get copyWith => _$MessagesStreamingStateCopyWithImpl<MessagesStreamingState>(this as MessagesStreamingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagesStreamingState&&(identical(other.streamSubscription, streamSubscription) || other.streamSubscription == streamSubscription)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult));
}


@override
int get hashCode => Object.hash(runtimeType,streamSubscription,lastResult);

@override
String toString() {
  return 'MessagesStreamingState(streamSubscription: $streamSubscription, lastResult: $lastResult)';
}


}

/// @nodoc
abstract mixin class $MessagesStreamingStateCopyWith<$Res>  {
  factory $MessagesStreamingStateCopyWith(MessagesStreamingState value, $Res Function(MessagesStreamingState) _then) = _$MessagesStreamingStateCopyWithImpl;
@useResult
$Res call({
 CompositeSubscription streamSubscription, ChatResult<ChatMessage>? lastResult
});


$ChatResultCopyWith<ChatMessage, $Res>? get lastResult;

}
/// @nodoc
class _$MessagesStreamingStateCopyWithImpl<$Res>
    implements $MessagesStreamingStateCopyWith<$Res> {
  _$MessagesStreamingStateCopyWithImpl(this._self, this._then);

  final MessagesStreamingState _self;
  final $Res Function(MessagesStreamingState) _then;

/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streamSubscription = null,Object? lastResult = freezed,}) {
  return _then(_self.copyWith(
streamSubscription: null == streamSubscription ? _self.streamSubscription : streamSubscription // ignore: cast_nullable_to_non_nullable
as CompositeSubscription,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as ChatResult<ChatMessage>?,
  ));
}
/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatResultCopyWith<ChatMessage, $Res>? get lastResult {
    if (_self.lastResult == null) {
    return null;
  }

  return $ChatResultCopyWith<ChatMessage, $Res>(_self.lastResult!, (value) {
    return _then(_self.copyWith(lastResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessagesStreamingState].
extension MessagesStreamingStatePatterns on MessagesStreamingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessagesStreamingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessagesStreamingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessagesStreamingState value)  $default,){
final _that = this;
switch (_that) {
case _MessagesStreamingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessagesStreamingState value)?  $default,){
final _that = this;
switch (_that) {
case _MessagesStreamingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CompositeSubscription streamSubscription,  ChatResult<ChatMessage>? lastResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagesStreamingState() when $default != null:
return $default(_that.streamSubscription,_that.lastResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CompositeSubscription streamSubscription,  ChatResult<ChatMessage>? lastResult)  $default,) {final _that = this;
switch (_that) {
case _MessagesStreamingState():
return $default(_that.streamSubscription,_that.lastResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CompositeSubscription streamSubscription,  ChatResult<ChatMessage>? lastResult)?  $default,) {final _that = this;
switch (_that) {
case _MessagesStreamingState() when $default != null:
return $default(_that.streamSubscription,_that.lastResult);case _:
  return null;

}
}

}

/// @nodoc


class _MessagesStreamingState implements MessagesStreamingState {
  const _MessagesStreamingState({required this.streamSubscription, this.lastResult});
  

@override final  CompositeSubscription streamSubscription;
@override final  ChatResult<ChatMessage>? lastResult;

/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagesStreamingStateCopyWith<_MessagesStreamingState> get copyWith => __$MessagesStreamingStateCopyWithImpl<_MessagesStreamingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagesStreamingState&&(identical(other.streamSubscription, streamSubscription) || other.streamSubscription == streamSubscription)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult));
}


@override
int get hashCode => Object.hash(runtimeType,streamSubscription,lastResult);

@override
String toString() {
  return 'MessagesStreamingState(streamSubscription: $streamSubscription, lastResult: $lastResult)';
}


}

/// @nodoc
abstract mixin class _$MessagesStreamingStateCopyWith<$Res> implements $MessagesStreamingStateCopyWith<$Res> {
  factory _$MessagesStreamingStateCopyWith(_MessagesStreamingState value, $Res Function(_MessagesStreamingState) _then) = __$MessagesStreamingStateCopyWithImpl;
@override @useResult
$Res call({
 CompositeSubscription streamSubscription, ChatResult<ChatMessage>? lastResult
});


@override $ChatResultCopyWith<ChatMessage, $Res>? get lastResult;

}
/// @nodoc
class __$MessagesStreamingStateCopyWithImpl<$Res>
    implements _$MessagesStreamingStateCopyWith<$Res> {
  __$MessagesStreamingStateCopyWithImpl(this._self, this._then);

  final _MessagesStreamingState _self;
  final $Res Function(_MessagesStreamingState) _then;

/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streamSubscription = null,Object? lastResult = freezed,}) {
  return _then(_MessagesStreamingState(
streamSubscription: null == streamSubscription ? _self.streamSubscription : streamSubscription // ignore: cast_nullable_to_non_nullable
as CompositeSubscription,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as ChatResult<ChatMessage>?,
  ));
}

/// Create a copy of MessagesStreamingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatResultCopyWith<ChatMessage, $Res>? get lastResult {
    if (_self.lastResult == null) {
    return null;
  }

  return $ChatResultCopyWith<ChatMessage, $Res>(_self.lastResult!, (value) {
    return _then(_self.copyWith(lastResult: value));
  });
}
}

// dart format on
