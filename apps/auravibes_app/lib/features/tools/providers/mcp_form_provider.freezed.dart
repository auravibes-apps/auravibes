// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_form_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$McpFormState {

 String get name; String get description; String get url; McpTransportTypeOptions get transport; McpAuthenticationTypeOptions get authenticationType; String get bearerToken; bool get useHttp2; bool get isSubmitting; String? get errorMessage;
/// Create a copy of McpFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpFormStateCopyWith<McpFormState> get copyWith => _$McpFormStateCopyWithImpl<McpFormState>(this as McpFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,url,transport,authenticationType,bearerToken,useHttp2,isSubmitting,errorMessage);

@override
String toString() {
  return 'McpFormState(name: $name, description: $description, url: $url, transport: $transport, authenticationType: $authenticationType, bearerToken: $bearerToken, useHttp2: $useHttp2, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $McpFormStateCopyWith<$Res>  {
  factory $McpFormStateCopyWith(McpFormState value, $Res Function(McpFormState) _then) = _$McpFormStateCopyWithImpl;
@useResult
$Res call({
 String name, String description, String url, McpTransportTypeOptions transport, McpAuthenticationTypeOptions authenticationType, String bearerToken, bool useHttp2, bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class _$McpFormStateCopyWithImpl<$Res>
    implements $McpFormStateCopyWith<$Res> {
  _$McpFormStateCopyWithImpl(this._self, this._then);

  final McpFormState _self;
  final $Res Function(McpFormState) _then;

/// Create a copy of McpFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? bearerToken = null,Object? useHttp2 = null,Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportTypeOptions,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationTypeOptions,bearerToken: null == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpFormState].
extension McpFormStatePatterns on McpFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpFormState value)  $default,){
final _that = this;
switch (_that) {
case _McpFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpFormState value)?  $default,){
final _that = this;
switch (_that) {
case _McpFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String url,  McpTransportTypeOptions transport,  McpAuthenticationTypeOptions authenticationType,  String bearerToken,  bool useHttp2,  bool isSubmitting,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpFormState() when $default != null:
return $default(_that.name,_that.description,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.useHttp2,_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String url,  McpTransportTypeOptions transport,  McpAuthenticationTypeOptions authenticationType,  String bearerToken,  bool useHttp2,  bool isSubmitting,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _McpFormState():
return $default(_that.name,_that.description,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.useHttp2,_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String url,  McpTransportTypeOptions transport,  McpAuthenticationTypeOptions authenticationType,  String bearerToken,  bool useHttp2,  bool isSubmitting,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _McpFormState() when $default != null:
return $default(_that.name,_that.description,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.useHttp2,_that.isSubmitting,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _McpFormState extends McpFormState {
  const _McpFormState({this.name = '', this.description = '', this.url = '', this.transport = McpTransportTypeOptions.streamableHttp, this.authenticationType = McpAuthenticationTypeOptions.none, this.bearerToken = '', this.useHttp2 = false, this.isSubmitting = false, this.errorMessage}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String url;
@override@JsonKey() final  McpTransportTypeOptions transport;
@override@JsonKey() final  McpAuthenticationTypeOptions authenticationType;
@override@JsonKey() final  String bearerToken;
@override@JsonKey() final  bool useHttp2;
@override@JsonKey() final  bool isSubmitting;
@override final  String? errorMessage;

/// Create a copy of McpFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpFormStateCopyWith<_McpFormState> get copyWith => __$McpFormStateCopyWithImpl<_McpFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.useHttp2, useHttp2) || other.useHttp2 == useHttp2)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,url,transport,authenticationType,bearerToken,useHttp2,isSubmitting,errorMessage);

@override
String toString() {
  return 'McpFormState(name: $name, description: $description, url: $url, transport: $transport, authenticationType: $authenticationType, bearerToken: $bearerToken, useHttp2: $useHttp2, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$McpFormStateCopyWith<$Res> implements $McpFormStateCopyWith<$Res> {
  factory _$McpFormStateCopyWith(_McpFormState value, $Res Function(_McpFormState) _then) = __$McpFormStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String url, McpTransportTypeOptions transport, McpAuthenticationTypeOptions authenticationType, String bearerToken, bool useHttp2, bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class __$McpFormStateCopyWithImpl<$Res>
    implements _$McpFormStateCopyWith<$Res> {
  __$McpFormStateCopyWithImpl(this._self, this._then);

  final _McpFormState _self;
  final $Res Function(_McpFormState) _then;

/// Create a copy of McpFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? bearerToken = null,Object? useHttp2 = null,Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_McpFormState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportTypeOptions,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationTypeOptions,bearerToken: null == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String,useHttp2: null == useHttp2 ? _self.useHttp2 : useHttp2 // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
