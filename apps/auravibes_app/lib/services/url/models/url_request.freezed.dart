// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'url_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UrlRequest {

 String get url; UrlRequestMethod get method; Map<String, String> get headers; String? get body; Duration get timeout; UrlResponseFormat get format;
/// Create a copy of UrlRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrlRequestCopyWith<UrlRequest> get copyWith => _$UrlRequestCopyWithImpl<UrlRequest>(this as UrlRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrlRequest&&(identical(other.url, url) || other.url == url)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.headers, headers)&&(identical(other.body, body) || other.body == body)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,url,method,const DeepCollectionEquality().hash(headers),body,timeout,format);

@override
String toString() {
  return 'UrlRequest(url: $url, method: $method, headers: $headers, body: $body, timeout: $timeout, format: $format)';
}


}

/// @nodoc
abstract mixin class $UrlRequestCopyWith<$Res>  {
  factory $UrlRequestCopyWith(UrlRequest value, $Res Function(UrlRequest) _then) = _$UrlRequestCopyWithImpl;
@useResult
$Res call({
 String url, UrlRequestMethod method, Map<String, String> headers, String? body, Duration timeout, UrlResponseFormat format
});




}
/// @nodoc
class _$UrlRequestCopyWithImpl<$Res>
    implements $UrlRequestCopyWith<$Res> {
  _$UrlRequestCopyWithImpl(this._self, this._then);

  final UrlRequest _self;
  final $Res Function(UrlRequest) _then;

/// Create a copy of UrlRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? method = null,Object? headers = null,Object? body = freezed,Object? timeout = null,Object? format = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as UrlRequestMethod,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as Duration,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as UrlResponseFormat,
  ));
}

}


/// Adds pattern-matching-related methods to [UrlRequest].
extension UrlRequestPatterns on UrlRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrlRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrlRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrlRequest value)  $default,){
final _that = this;
switch (_that) {
case _UrlRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrlRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UrlRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  UrlRequestMethod method,  Map<String, String> headers,  String? body,  Duration timeout,  UrlResponseFormat format)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrlRequest() when $default != null:
return $default(_that.url,_that.method,_that.headers,_that.body,_that.timeout,_that.format);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  UrlRequestMethod method,  Map<String, String> headers,  String? body,  Duration timeout,  UrlResponseFormat format)  $default,) {final _that = this;
switch (_that) {
case _UrlRequest():
return $default(_that.url,_that.method,_that.headers,_that.body,_that.timeout,_that.format);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  UrlRequestMethod method,  Map<String, String> headers,  String? body,  Duration timeout,  UrlResponseFormat format)?  $default,) {final _that = this;
switch (_that) {
case _UrlRequest() when $default != null:
return $default(_that.url,_that.method,_that.headers,_that.body,_that.timeout,_that.format);case _:
  return null;

}
}

}

/// @nodoc


class _UrlRequest implements UrlRequest {
  const _UrlRequest({required this.url, this.method = UrlRequestMethod.get, final  Map<String, String> headers = const {}, this.body, this.timeout = const Duration(seconds: 30), this.format = UrlResponseFormat.defaultFormat}): _headers = headers;
  

@override final  String url;
@override@JsonKey() final  UrlRequestMethod method;
 final  Map<String, String> _headers;
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

@override final  String? body;
@override@JsonKey() final  Duration timeout;
@override@JsonKey() final  UrlResponseFormat format;

/// Create a copy of UrlRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrlRequestCopyWith<_UrlRequest> get copyWith => __$UrlRequestCopyWithImpl<_UrlRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrlRequest&&(identical(other.url, url) || other.url == url)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other._headers, _headers)&&(identical(other.body, body) || other.body == body)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,url,method,const DeepCollectionEquality().hash(_headers),body,timeout,format);

@override
String toString() {
  return 'UrlRequest(url: $url, method: $method, headers: $headers, body: $body, timeout: $timeout, format: $format)';
}


}

/// @nodoc
abstract mixin class _$UrlRequestCopyWith<$Res> implements $UrlRequestCopyWith<$Res> {
  factory _$UrlRequestCopyWith(_UrlRequest value, $Res Function(_UrlRequest) _then) = __$UrlRequestCopyWithImpl;
@override @useResult
$Res call({
 String url, UrlRequestMethod method, Map<String, String> headers, String? body, Duration timeout, UrlResponseFormat format
});




}
/// @nodoc
class __$UrlRequestCopyWithImpl<$Res>
    implements _$UrlRequestCopyWith<$Res> {
  __$UrlRequestCopyWithImpl(this._self, this._then);

  final _UrlRequest _self;
  final $Res Function(_UrlRequest) _then;

/// Create a copy of UrlRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? method = null,Object? headers = null,Object? body = freezed,Object? timeout = null,Object? format = null,}) {
  return _then(_UrlRequest(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as UrlRequestMethod,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as Duration,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as UrlResponseFormat,
  ));
}


}

// dart format on
