// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'url_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UrlResponse {

 int get statusCode; String get body; Map<String, List<String>> get headers; Duration get elapsed;
/// Create a copy of UrlResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrlResponseCopyWith<UrlResponse> get copyWith => _$UrlResponseCopyWithImpl<UrlResponse>(this as UrlResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrlResponse&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.headers, headers)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,body,const DeepCollectionEquality().hash(headers),elapsed);

@override
String toString() {
  return 'UrlResponse(statusCode: $statusCode, body: $body, headers: $headers, elapsed: $elapsed)';
}


}

/// @nodoc
abstract mixin class $UrlResponseCopyWith<$Res>  {
  factory $UrlResponseCopyWith(UrlResponse value, $Res Function(UrlResponse) _then) = _$UrlResponseCopyWithImpl;
@useResult
$Res call({
 int statusCode, String body, Map<String, List<String>> headers, Duration elapsed
});




}
/// @nodoc
class _$UrlResponseCopyWithImpl<$Res>
    implements $UrlResponseCopyWith<$Res> {
  _$UrlResponseCopyWithImpl(this._self, this._then);

  final UrlResponse _self;
  final $Res Function(UrlResponse) _then;

/// Create a copy of UrlResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? statusCode = null,Object? body = null,Object? headers = null,Object? elapsed = null,}) {
  return _then(_self.copyWith(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [UrlResponse].
extension UrlResponsePatterns on UrlResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrlResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrlResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrlResponse value)  $default,){
final _that = this;
switch (_that) {
case _UrlResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrlResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UrlResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int statusCode,  String body,  Map<String, List<String>> headers,  Duration elapsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrlResponse() when $default != null:
return $default(_that.statusCode,_that.body,_that.headers,_that.elapsed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int statusCode,  String body,  Map<String, List<String>> headers,  Duration elapsed)  $default,) {final _that = this;
switch (_that) {
case _UrlResponse():
return $default(_that.statusCode,_that.body,_that.headers,_that.elapsed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int statusCode,  String body,  Map<String, List<String>> headers,  Duration elapsed)?  $default,) {final _that = this;
switch (_that) {
case _UrlResponse() when $default != null:
return $default(_that.statusCode,_that.body,_that.headers,_that.elapsed);case _:
  return null;

}
}

}

/// @nodoc


class _UrlResponse extends UrlResponse {
  const _UrlResponse({required this.statusCode, required this.body, required final  Map<String, List<String>> headers, required this.elapsed}): _headers = headers,super._();
  

@override final  int statusCode;
@override final  String body;
 final  Map<String, List<String>> _headers;
@override Map<String, List<String>> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

@override final  Duration elapsed;

/// Create a copy of UrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrlResponseCopyWith<_UrlResponse> get copyWith => __$UrlResponseCopyWithImpl<_UrlResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrlResponse&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._headers, _headers)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,body,const DeepCollectionEquality().hash(_headers),elapsed);

@override
String toString() {
  return 'UrlResponse(statusCode: $statusCode, body: $body, headers: $headers, elapsed: $elapsed)';
}


}

/// @nodoc
abstract mixin class _$UrlResponseCopyWith<$Res> implements $UrlResponseCopyWith<$Res> {
  factory _$UrlResponseCopyWith(_UrlResponse value, $Res Function(_UrlResponse) _then) = __$UrlResponseCopyWithImpl;
@override @useResult
$Res call({
 int statusCode, String body, Map<String, List<String>> headers, Duration elapsed
});




}
/// @nodoc
class __$UrlResponseCopyWithImpl<$Res>
    implements _$UrlResponseCopyWith<$Res> {
  __$UrlResponseCopyWithImpl(this._self, this._then);

  final _UrlResponse _self;
  final $Res Function(_UrlResponse) _then;

/// Create a copy of UrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? body = null,Object? headers = null,Object? elapsed = null,}) {
  return _then(_UrlResponse(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
