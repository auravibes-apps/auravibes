// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatbotToolCall {

 String get id; String get name; Map<String, dynamic> get arguments; String get argumentsRaw; String? get responseRaw;
/// Create a copy of ChatbotToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatbotToolCallCopyWith<ChatbotToolCall> get copyWith => _$ChatbotToolCallCopyWithImpl<ChatbotToolCall>(this as ChatbotToolCall, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatbotToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.responseRaw, responseRaw) || other.responseRaw == responseRaw));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(arguments),argumentsRaw,responseRaw);

@override
String toString() {
  return 'ChatbotToolCall(id: $id, name: $name, arguments: $arguments, argumentsRaw: $argumentsRaw, responseRaw: $responseRaw)';
}


}

/// @nodoc
abstract mixin class $ChatbotToolCallCopyWith<$Res>  {
  factory $ChatbotToolCallCopyWith(ChatbotToolCall value, $Res Function(ChatbotToolCall) _then) = _$ChatbotToolCallCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, dynamic> arguments, String argumentsRaw, String? responseRaw
});




}
/// @nodoc
class _$ChatbotToolCallCopyWithImpl<$Res>
    implements $ChatbotToolCallCopyWith<$Res> {
  _$ChatbotToolCallCopyWithImpl(this._self, this._then);

  final ChatbotToolCall _self;
  final $Res Function(ChatbotToolCall) _then;

/// Create a copy of ChatbotToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? arguments = null,Object? argumentsRaw = null,Object? responseRaw = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatbotToolCall].
extension ChatbotToolCallPatterns on ChatbotToolCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatbotToolCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatbotToolCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatbotToolCall value)  $default,){
final _that = this;
switch (_that) {
case _ChatbotToolCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatbotToolCall value)?  $default,){
final _that = this;
switch (_that) {
case _ChatbotToolCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  String? responseRaw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatbotToolCall() when $default != null:
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.responseRaw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  String? responseRaw)  $default,) {final _that = this;
switch (_that) {
case _ChatbotToolCall():
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.responseRaw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  String? responseRaw)?  $default,) {final _that = this;
switch (_that) {
case _ChatbotToolCall() when $default != null:
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.responseRaw);case _:
  return null;

}
}

}

/// @nodoc


class _ChatbotToolCall implements ChatbotToolCall {
  const _ChatbotToolCall({required this.id, required this.name, required final  Map<String, dynamic> arguments, required this.argumentsRaw, this.responseRaw}): _arguments = arguments;
  

@override final  String id;
@override final  String name;
 final  Map<String, dynamic> _arguments;
@override Map<String, dynamic> get arguments {
  if (_arguments is EqualUnmodifiableMapView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_arguments);
}

@override final  String argumentsRaw;
@override final  String? responseRaw;

/// Create a copy of ChatbotToolCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatbotToolCallCopyWith<_ChatbotToolCall> get copyWith => __$ChatbotToolCallCopyWithImpl<_ChatbotToolCall>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatbotToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.responseRaw, responseRaw) || other.responseRaw == responseRaw));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_arguments),argumentsRaw,responseRaw);

@override
String toString() {
  return 'ChatbotToolCall(id: $id, name: $name, arguments: $arguments, argumentsRaw: $argumentsRaw, responseRaw: $responseRaw)';
}


}

/// @nodoc
abstract mixin class _$ChatbotToolCallCopyWith<$Res> implements $ChatbotToolCallCopyWith<$Res> {
  factory _$ChatbotToolCallCopyWith(_ChatbotToolCall value, $Res Function(_ChatbotToolCall) _then) = __$ChatbotToolCallCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Map<String, dynamic> arguments, String argumentsRaw, String? responseRaw
});




}
/// @nodoc
class __$ChatbotToolCallCopyWithImpl<$Res>
    implements _$ChatbotToolCallCopyWith<$Res> {
  __$ChatbotToolCallCopyWithImpl(this._self, this._then);

  final _ChatbotToolCall _self;
  final $Res Function(_ChatbotToolCall) _then;

/// Create a copy of ChatbotToolCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? arguments = null,Object? argumentsRaw = null,Object? responseRaw = freezed,}) {
  return _then(_ChatbotToolCall(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
