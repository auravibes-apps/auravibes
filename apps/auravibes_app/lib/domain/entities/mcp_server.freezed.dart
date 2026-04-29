// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mcp_server.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OAutTokenModel {

 String get accessToken; String? get refreshToken; int? get expiresIn; String? get tokenType; String? get scope;
/// Create a copy of OAutTokenModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAutTokenModelCopyWith<OAutTokenModel> get copyWith => _$OAutTokenModelCopyWithImpl<OAutTokenModel>(this as OAutTokenModel, _$identity);

  /// Serializes this OAutTokenModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAutTokenModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.scope, scope) || other.scope == scope));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,tokenType,scope);

@override
String toString() {
  return 'OAutTokenModel(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, scope: $scope)';
}


}

/// @nodoc
abstract mixin class $OAutTokenModelCopyWith<$Res>  {
  factory $OAutTokenModelCopyWith(OAutTokenModel value, $Res Function(OAutTokenModel) _then) = _$OAutTokenModelCopyWithImpl;
@useResult
$Res call({
 String accessToken, String? refreshToken, int? expiresIn, String? tokenType, String? scope
});




}
/// @nodoc
class _$OAutTokenModelCopyWithImpl<$Res>
    implements $OAutTokenModelCopyWith<$Res> {
  _$OAutTokenModelCopyWithImpl(this._self, this._then);

  final OAutTokenModel _self;
  final $Res Function(OAutTokenModel) _then;

/// Create a copy of OAutTokenModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = freezed,Object? tokenType = freezed,Object? scope = freezed,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OAutTokenModel].
extension OAutTokenModelPatterns on OAutTokenModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OAutTokenModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OAutTokenModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OAutTokenModel value)  $default,){
final _that = this;
switch (_that) {
case _OAutTokenModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OAutTokenModel value)?  $default,){
final _that = this;
switch (_that) {
case _OAutTokenModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int? expiresIn,  String? tokenType,  String? scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OAutTokenModel() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int? expiresIn,  String? tokenType,  String? scope)  $default,) {final _that = this;
switch (_that) {
case _OAutTokenModel():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String? refreshToken,  int? expiresIn,  String? tokenType,  String? scope)?  $default,) {final _that = this;
switch (_that) {
case _OAutTokenModel() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scope);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: .snake)
class _OAutTokenModel extends OAutTokenModel {
  const _OAutTokenModel({required this.accessToken, this.refreshToken, this.expiresIn, this.tokenType, this.scope}): super._();
  factory _OAutTokenModel.fromJson(Map<String, dynamic> json) => _$OAutTokenModelFromJson(json);

@override final  String accessToken;
@override final  String? refreshToken;
@override final  int? expiresIn;
@override final  String? tokenType;
@override final  String? scope;

/// Create a copy of OAutTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OAutTokenModelCopyWith<_OAutTokenModel> get copyWith => __$OAutTokenModelCopyWithImpl<_OAutTokenModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAutTokenModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OAutTokenModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.scope, scope) || other.scope == scope));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,tokenType,scope);

@override
String toString() {
  return 'OAutTokenModel(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$OAutTokenModelCopyWith<$Res> implements $OAutTokenModelCopyWith<$Res> {
  factory _$OAutTokenModelCopyWith(_OAutTokenModel value, $Res Function(_OAutTokenModel) _then) = __$OAutTokenModelCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String? refreshToken, int? expiresIn, String? tokenType, String? scope
});




}
/// @nodoc
class __$OAutTokenModelCopyWithImpl<$Res>
    implements _$OAutTokenModelCopyWith<$Res> {
  __$OAutTokenModelCopyWithImpl(this._self, this._then);

  final _OAutTokenModel _self;
  final $Res Function(_OAutTokenModel) _then;

/// Create a copy of OAutTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = freezed,Object? tokenType = freezed,Object? scope = freezed,}) {
  return _then(_OAutTokenModel(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OAutTokenEntity {

 String get accessToken; DateTime get issuedAt; String? get refreshToken; int? get expiresIn; String? get tokenType; List<String>? get scopes;
/// Create a copy of OAutTokenEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAutTokenEntityCopyWith<OAutTokenEntity> get copyWith => _$OAutTokenEntityCopyWithImpl<OAutTokenEntity>(this as OAutTokenEntity, _$identity);

  /// Serializes this OAutTokenEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAutTokenEntity&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&const DeepCollectionEquality().equals(other.scopes, scopes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,issuedAt,refreshToken,expiresIn,tokenType,const DeepCollectionEquality().hash(scopes));

@override
String toString() {
  return 'OAutTokenEntity(accessToken: $accessToken, issuedAt: $issuedAt, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, scopes: $scopes)';
}


}

/// @nodoc
abstract mixin class $OAutTokenEntityCopyWith<$Res>  {
  factory $OAutTokenEntityCopyWith(OAutTokenEntity value, $Res Function(OAutTokenEntity) _then) = _$OAutTokenEntityCopyWithImpl;
@useResult
$Res call({
 String accessToken, DateTime issuedAt, String? refreshToken, int? expiresIn, String? tokenType, List<String>? scopes
});




}
/// @nodoc
class _$OAutTokenEntityCopyWithImpl<$Res>
    implements $OAutTokenEntityCopyWith<$Res> {
  _$OAutTokenEntityCopyWithImpl(this._self, this._then);

  final OAutTokenEntity _self;
  final $Res Function(OAutTokenEntity) _then;

/// Create a copy of OAutTokenEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? issuedAt = null,Object? refreshToken = freezed,Object? expiresIn = freezed,Object? tokenType = freezed,Object? scopes = freezed,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,scopes: freezed == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [OAutTokenEntity].
extension OAutTokenEntityPatterns on OAutTokenEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OAutTokenEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OAutTokenEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OAutTokenEntity value)  $default,){
final _that = this;
switch (_that) {
case _OAutTokenEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OAutTokenEntity value)?  $default,){
final _that = this;
switch (_that) {
case _OAutTokenEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  DateTime issuedAt,  String? refreshToken,  int? expiresIn,  String? tokenType,  List<String>? scopes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OAutTokenEntity() when $default != null:
return $default(_that.accessToken,_that.issuedAt,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scopes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  DateTime issuedAt,  String? refreshToken,  int? expiresIn,  String? tokenType,  List<String>? scopes)  $default,) {final _that = this;
switch (_that) {
case _OAutTokenEntity():
return $default(_that.accessToken,_that.issuedAt,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scopes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  DateTime issuedAt,  String? refreshToken,  int? expiresIn,  String? tokenType,  List<String>? scopes)?  $default,) {final _that = this;
switch (_that) {
case _OAutTokenEntity() when $default != null:
return $default(_that.accessToken,_that.issuedAt,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.scopes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OAutTokenEntity extends OAutTokenEntity {
  const _OAutTokenEntity({required this.accessToken, required this.issuedAt, this.refreshToken, this.expiresIn, this.tokenType, final  List<String>? scopes}): _scopes = scopes,super._();
  factory _OAutTokenEntity.fromJson(Map<String, dynamic> json) => _$OAutTokenEntityFromJson(json);

@override final  String accessToken;
@override final  DateTime issuedAt;
@override final  String? refreshToken;
@override final  int? expiresIn;
@override final  String? tokenType;
 final  List<String>? _scopes;
@override List<String>? get scopes {
  final value = _scopes;
  if (value == null) return null;
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of OAutTokenEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OAutTokenEntityCopyWith<_OAutTokenEntity> get copyWith => __$OAutTokenEntityCopyWithImpl<_OAutTokenEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAutTokenEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OAutTokenEntity&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&const DeepCollectionEquality().equals(other._scopes, _scopes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,issuedAt,refreshToken,expiresIn,tokenType,const DeepCollectionEquality().hash(_scopes));

@override
String toString() {
  return 'OAutTokenEntity(accessToken: $accessToken, issuedAt: $issuedAt, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, scopes: $scopes)';
}


}

/// @nodoc
abstract mixin class _$OAutTokenEntityCopyWith<$Res> implements $OAutTokenEntityCopyWith<$Res> {
  factory _$OAutTokenEntityCopyWith(_OAutTokenEntity value, $Res Function(_OAutTokenEntity) _then) = __$OAutTokenEntityCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, DateTime issuedAt, String? refreshToken, int? expiresIn, String? tokenType, List<String>? scopes
});




}
/// @nodoc
class __$OAutTokenEntityCopyWithImpl<$Res>
    implements _$OAutTokenEntityCopyWith<$Res> {
  __$OAutTokenEntityCopyWithImpl(this._self, this._then);

  final _OAutTokenEntity _self;
  final $Res Function(_OAutTokenEntity) _then;

/// Create a copy of OAutTokenEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? issuedAt = null,Object? refreshToken = freezed,Object? expiresIn = freezed,Object? tokenType = freezed,Object? scopes = freezed,}) {
  return _then(_OAutTokenEntity(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,scopes: freezed == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

McpAuthenticationType _$McpAuthenticationTypeFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'none':
          return McpAuthenticationTypeNone.fromJson(
            json
          );
                case 'oauth':
          return McpAuthenticationTypeOAuth.fromJson(
            json
          );
                case 'bearerToken':
          return McpAuthenticationTypeBearerToken.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'McpAuthenticationType',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$McpAuthenticationType {



  /// Serializes this McpAuthenticationType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpAuthenticationType);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpAuthenticationType()';
}


}

/// @nodoc
class $McpAuthenticationTypeCopyWith<$Res>  {
$McpAuthenticationTypeCopyWith(McpAuthenticationType _, $Res Function(McpAuthenticationType) __);
}


/// Adds pattern-matching-related methods to [McpAuthenticationType].
extension McpAuthenticationTypePatterns on McpAuthenticationType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( McpAuthenticationTypeNone value)?  none,TResult Function( McpAuthenticationTypeOAuth value)?  oauth,TResult Function( McpAuthenticationTypeBearerToken value)?  bearerToken,required TResult orElse(),}){
final _that = this;
switch (_that) {
case McpAuthenticationTypeNone() when none != null:
return none(_that);case McpAuthenticationTypeOAuth() when oauth != null:
return oauth(_that);case McpAuthenticationTypeBearerToken() when bearerToken != null:
return bearerToken(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( McpAuthenticationTypeNone value)  none,required TResult Function( McpAuthenticationTypeOAuth value)  oauth,required TResult Function( McpAuthenticationTypeBearerToken value)  bearerToken,}){
final _that = this;
switch (_that) {
case McpAuthenticationTypeNone():
return none(_that);case McpAuthenticationTypeOAuth():
return oauth(_that);case McpAuthenticationTypeBearerToken():
return bearerToken(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( McpAuthenticationTypeNone value)?  none,TResult? Function( McpAuthenticationTypeOAuth value)?  oauth,TResult? Function( McpAuthenticationTypeBearerToken value)?  bearerToken,}){
final _that = this;
switch (_that) {
case McpAuthenticationTypeNone() when none != null:
return none(_that);case McpAuthenticationTypeOAuth() when oauth != null:
return oauth(_that);case McpAuthenticationTypeBearerToken() when bearerToken != null:
return bearerToken(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( OAutTokenEntity token,  String clientId,  String authorizationEndpoint,  String tokenEndpoint)?  oauth,TResult Function( String bearerToken)?  bearerToken,required TResult orElse(),}) {final _that = this;
switch (_that) {
case McpAuthenticationTypeNone() when none != null:
return none();case McpAuthenticationTypeOAuth() when oauth != null:
return oauth(_that.token,_that.clientId,_that.authorizationEndpoint,_that.tokenEndpoint);case McpAuthenticationTypeBearerToken() when bearerToken != null:
return bearerToken(_that.bearerToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( OAutTokenEntity token,  String clientId,  String authorizationEndpoint,  String tokenEndpoint)  oauth,required TResult Function( String bearerToken)  bearerToken,}) {final _that = this;
switch (_that) {
case McpAuthenticationTypeNone():
return none();case McpAuthenticationTypeOAuth():
return oauth(_that.token,_that.clientId,_that.authorizationEndpoint,_that.tokenEndpoint);case McpAuthenticationTypeBearerToken():
return bearerToken(_that.bearerToken);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( OAutTokenEntity token,  String clientId,  String authorizationEndpoint,  String tokenEndpoint)?  oauth,TResult? Function( String bearerToken)?  bearerToken,}) {final _that = this;
switch (_that) {
case McpAuthenticationTypeNone() when none != null:
return none();case McpAuthenticationTypeOAuth() when oauth != null:
return oauth(_that.token,_that.clientId,_that.authorizationEndpoint,_that.tokenEndpoint);case McpAuthenticationTypeBearerToken() when bearerToken != null:
return bearerToken(_that.bearerToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class McpAuthenticationTypeNone extends McpAuthenticationType {
  const McpAuthenticationTypeNone({final  String? $type}): $type = $type ?? 'none',super._();
  factory McpAuthenticationTypeNone.fromJson(Map<String, dynamic> json) => _$McpAuthenticationTypeNoneFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$McpAuthenticationTypeNoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpAuthenticationTypeNone);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'McpAuthenticationType.none()';
}


}




/// @nodoc
@JsonSerializable()

class McpAuthenticationTypeOAuth extends McpAuthenticationType {
  const McpAuthenticationTypeOAuth({required this.token, required this.clientId, required this.authorizationEndpoint, required this.tokenEndpoint, final  String? $type}): $type = $type ?? 'oauth',super._();
  factory McpAuthenticationTypeOAuth.fromJson(Map<String, dynamic> json) => _$McpAuthenticationTypeOAuthFromJson(json);

 final  OAutTokenEntity token;
 final  String clientId;
 final  String authorizationEndpoint;
 final  String tokenEndpoint;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of McpAuthenticationType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpAuthenticationTypeOAuthCopyWith<McpAuthenticationTypeOAuth> get copyWith => _$McpAuthenticationTypeOAuthCopyWithImpl<McpAuthenticationTypeOAuth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpAuthenticationTypeOAuthToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpAuthenticationTypeOAuth&&(identical(other.token, token) || other.token == token)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.authorizationEndpoint, authorizationEndpoint) || other.authorizationEndpoint == authorizationEndpoint)&&(identical(other.tokenEndpoint, tokenEndpoint) || other.tokenEndpoint == tokenEndpoint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,clientId,authorizationEndpoint,tokenEndpoint);

@override
String toString() {
  return 'McpAuthenticationType.oauth(token: $token, clientId: $clientId, authorizationEndpoint: $authorizationEndpoint, tokenEndpoint: $tokenEndpoint)';
}


}

/// @nodoc
abstract mixin class $McpAuthenticationTypeOAuthCopyWith<$Res> implements $McpAuthenticationTypeCopyWith<$Res> {
  factory $McpAuthenticationTypeOAuthCopyWith(McpAuthenticationTypeOAuth value, $Res Function(McpAuthenticationTypeOAuth) _then) = _$McpAuthenticationTypeOAuthCopyWithImpl;
@useResult
$Res call({
 OAutTokenEntity token, String clientId, String authorizationEndpoint, String tokenEndpoint
});


$OAutTokenEntityCopyWith<$Res> get token;

}
/// @nodoc
class _$McpAuthenticationTypeOAuthCopyWithImpl<$Res>
    implements $McpAuthenticationTypeOAuthCopyWith<$Res> {
  _$McpAuthenticationTypeOAuthCopyWithImpl(this._self, this._then);

  final McpAuthenticationTypeOAuth _self;
  final $Res Function(McpAuthenticationTypeOAuth) _then;

/// Create a copy of McpAuthenticationType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? token = null,Object? clientId = null,Object? authorizationEndpoint = null,Object? tokenEndpoint = null,}) {
  return _then(McpAuthenticationTypeOAuth(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as OAutTokenEntity,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,authorizationEndpoint: null == authorizationEndpoint ? _self.authorizationEndpoint : authorizationEndpoint // ignore: cast_nullable_to_non_nullable
as String,tokenEndpoint: null == tokenEndpoint ? _self.tokenEndpoint : tokenEndpoint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of McpAuthenticationType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAutTokenEntityCopyWith<$Res> get token {
  
  return $OAutTokenEntityCopyWith<$Res>(_self.token, (value) {
    return _then(_self.copyWith(token: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class McpAuthenticationTypeBearerToken extends McpAuthenticationType {
  const McpAuthenticationTypeBearerToken({required this.bearerToken, final  String? $type}): $type = $type ?? 'bearerToken',super._();
  factory McpAuthenticationTypeBearerToken.fromJson(Map<String, dynamic> json) => _$McpAuthenticationTypeBearerTokenFromJson(json);

 final  String bearerToken;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of McpAuthenticationType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpAuthenticationTypeBearerTokenCopyWith<McpAuthenticationTypeBearerToken> get copyWith => _$McpAuthenticationTypeBearerTokenCopyWithImpl<McpAuthenticationTypeBearerToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$McpAuthenticationTypeBearerTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpAuthenticationTypeBearerToken&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bearerToken);

@override
String toString() {
  return 'McpAuthenticationType.bearerToken(bearerToken: $bearerToken)';
}


}

/// @nodoc
abstract mixin class $McpAuthenticationTypeBearerTokenCopyWith<$Res> implements $McpAuthenticationTypeCopyWith<$Res> {
  factory $McpAuthenticationTypeBearerTokenCopyWith(McpAuthenticationTypeBearerToken value, $Res Function(McpAuthenticationTypeBearerToken) _then) = _$McpAuthenticationTypeBearerTokenCopyWithImpl;
@useResult
$Res call({
 String bearerToken
});




}
/// @nodoc
class _$McpAuthenticationTypeBearerTokenCopyWithImpl<$Res>
    implements $McpAuthenticationTypeBearerTokenCopyWith<$Res> {
  _$McpAuthenticationTypeBearerTokenCopyWithImpl(this._self, this._then);

  final McpAuthenticationTypeBearerToken _self;
  final $Res Function(McpAuthenticationTypeBearerToken) _then;

/// Create a copy of McpAuthenticationType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bearerToken = null,}) {
  return _then(McpAuthenticationTypeBearerToken(
bearerToken: null == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$McpServerToCreate {

/// User-friendly name for the MCP server
 String get name;/// URL endpoint for the MCP server
 String get url;/// Transport type used for communication
 McpTransportType get transport;/// Authentication type for the MCP server
 McpAuthenticationType get authenticationType;/// Optional description of what this MCP server provides
 String? get description;
/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerToCreateCopyWith<McpServerToCreate> get copyWith => _$McpServerToCreateCopyWithImpl<McpServerToCreate>(this as McpServerToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,description);

@override
String toString() {
  return 'McpServerToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, description: $description)';
}


}

/// @nodoc
abstract mixin class $McpServerToCreateCopyWith<$Res>  {
  factory $McpServerToCreateCopyWith(McpServerToCreate value, $Res Function(McpServerToCreate) _then) = _$McpServerToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, String? description
});


$McpAuthenticationTypeCopyWith<$Res> get authenticationType;

}
/// @nodoc
class _$McpServerToCreateCopyWithImpl<$Res>
    implements $McpServerToCreateCopyWith<$Res> {
  _$McpServerToCreateCopyWithImpl(this._self, this._then);

  final McpServerToCreate _self;
  final $Res Function(McpServerToCreate) _then;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpAuthenticationTypeCopyWith<$Res> get authenticationType {
  
  return $McpAuthenticationTypeCopyWith<$Res>(_self.authenticationType, (value) {
    return _then(_self.copyWith(authenticationType: value));
  });
}
}


/// Adds pattern-matching-related methods to [McpServerToCreate].
extension McpServerToCreatePatterns on McpServerToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerToCreate value)  $default,){
final _that = this;
switch (_that) {
case _McpServerToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description)  $default,) {final _that = this;
switch (_that) {
case _McpServerToCreate():
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _McpServerToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerToCreate extends McpServerToCreate {
  const _McpServerToCreate({required this.name, required this.url, required this.transport, required this.authenticationType, this.description}): super._();
  

/// User-friendly name for the MCP server
@override final  String name;
/// URL endpoint for the MCP server
@override final  String url;
/// Transport type used for communication
@override final  McpTransportType transport;
/// Authentication type for the MCP server
@override final  McpAuthenticationType authenticationType;
/// Optional description of what this MCP server provides
@override final  String? description;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerToCreateCopyWith<_McpServerToCreate> get copyWith => __$McpServerToCreateCopyWithImpl<_McpServerToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,description);

@override
String toString() {
  return 'McpServerToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, description: $description)';
}


}

/// @nodoc
abstract mixin class _$McpServerToCreateCopyWith<$Res> implements $McpServerToCreateCopyWith<$Res> {
  factory _$McpServerToCreateCopyWith(_McpServerToCreate value, $Res Function(_McpServerToCreate) _then) = __$McpServerToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, String? description
});


@override $McpAuthenticationTypeCopyWith<$Res> get authenticationType;

}
/// @nodoc
class __$McpServerToCreateCopyWithImpl<$Res>
    implements _$McpServerToCreateCopyWith<$Res> {
  __$McpServerToCreateCopyWithImpl(this._self, this._then);

  final _McpServerToCreate _self;
  final $Res Function(_McpServerToCreate) _then;

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? description = freezed,}) {
  return _then(_McpServerToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of McpServerToCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpAuthenticationTypeCopyWith<$Res> get authenticationType {
  
  return $McpAuthenticationTypeCopyWith<$Res>(_self.authenticationType, (value) {
    return _then(_self.copyWith(authenticationType: value));
  });
}
}

/// @nodoc
mixin _$McpServerEntity {

/// Unique ID of this MCP server record in the database
 String get id;/// ID of the workspace this MCP server belongs to
 String get workspaceId;/// User-friendly name for the MCP server
 String get name;/// URL endpoint for the MCP server
 String get url;/// Transport type used for communication
 McpTransportType get transport;/// Authentication type for the MCP server
 McpAuthenticationType get authenticationType;/// Timestamp when this configuration was created
 DateTime get createdAt;/// Timestamp when this configuration was last updated
 DateTime get updatedAt;/// Optional description of what this MCP server provides
 String? get description;/// Whether the MCP server is enabled
 bool get isEnabled;
/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerEntityCopyWith<McpServerEntity> get copyWith => _$McpServerEntityCopyWithImpl<McpServerEntity>(this as McpServerEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,url,transport,authenticationType,createdAt,updatedAt,description,isEnabled);

@override
String toString() {
  return 'McpServerEntity(id: $id, workspaceId: $workspaceId, name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $McpServerEntityCopyWith<$Res> implements $McpServerToCreateCopyWith<$Res> {
  factory $McpServerEntityCopyWith(McpServerEntity value, $Res Function(McpServerEntity) _then) = _$McpServerEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, DateTime createdAt, DateTime updatedAt, String? description, bool isEnabled
});


$McpAuthenticationTypeCopyWith<$Res> get authenticationType;

}
/// @nodoc
class _$McpServerEntityCopyWithImpl<$Res>
    implements $McpServerEntityCopyWith<$Res> {
  _$McpServerEntityCopyWithImpl(this._self, this._then);

  final McpServerEntity _self;
  final $Res Function(McpServerEntity) _then;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpAuthenticationTypeCopyWith<$Res> get authenticationType {
  
  return $McpAuthenticationTypeCopyWith<$Res>(_self.authenticationType, (value) {
    return _then(_self.copyWith(authenticationType: value));
  });
}
}


/// Adds pattern-matching-related methods to [McpServerEntity].
extension McpServerEntityPatterns on McpServerEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerEntity value)  $default,){
final _that = this;
switch (_that) {
case _McpServerEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerEntity value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _McpServerEntity():
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  String url,  McpTransportType transport,  McpAuthenticationType authenticationType,  DateTime createdAt,  DateTime updatedAt,  String? description,  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _McpServerEntity() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.url,_that.transport,_that.authenticationType,_that.createdAt,_that.updatedAt,_that.description,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerEntity extends McpServerEntity {
  const _McpServerEntity({required this.id, required this.workspaceId, required this.name, required this.url, required this.transport, required this.authenticationType, required this.createdAt, required this.updatedAt, this.description, this.isEnabled = true}): super._();
  

/// Unique ID of this MCP server record in the database
@override final  String id;
/// ID of the workspace this MCP server belongs to
@override final  String workspaceId;
/// User-friendly name for the MCP server
@override final  String name;
/// URL endpoint for the MCP server
@override final  String url;
/// Transport type used for communication
@override final  McpTransportType transport;
/// Authentication type for the MCP server
@override final  McpAuthenticationType authenticationType;
/// Timestamp when this configuration was created
@override final  DateTime createdAt;
/// Timestamp when this configuration was last updated
@override final  DateTime updatedAt;
/// Optional description of what this MCP server provides
@override final  String? description;
/// Whether the MCP server is enabled
@override@JsonKey() final  bool isEnabled;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerEntityCopyWith<_McpServerEntity> get copyWith => __$McpServerEntityCopyWithImpl<_McpServerEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,url,transport,authenticationType,createdAt,updatedAt,description,isEnabled);

@override
String toString() {
  return 'McpServerEntity(id: $id, workspaceId: $workspaceId, name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$McpServerEntityCopyWith<$Res> implements $McpServerEntityCopyWith<$Res> {
  factory _$McpServerEntityCopyWith(_McpServerEntity value, $Res Function(_McpServerEntity) _then) = __$McpServerEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, String url, McpTransportType transport, McpAuthenticationType authenticationType, DateTime createdAt, DateTime updatedAt, String? description, bool isEnabled
});


@override $McpAuthenticationTypeCopyWith<$Res> get authenticationType;

}
/// @nodoc
class __$McpServerEntityCopyWithImpl<$Res>
    implements _$McpServerEntityCopyWith<$Res> {
  __$McpServerEntityCopyWithImpl(this._self, this._then);

  final _McpServerEntity _self;
  final $Res Function(_McpServerEntity) _then;

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? isEnabled = null,}) {
  return _then(_McpServerEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of McpServerEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$McpAuthenticationTypeCopyWith<$Res> get authenticationType {
  
  return $McpAuthenticationTypeCopyWith<$Res>(_self.authenticationType, (value) {
    return _then(_self.copyWith(authenticationType: value));
  });
}
}

/// @nodoc
mixin _$McpServerFormToCreate {

 String get name; String get url; McpTransportType get transport; McpAuthenticationTypeOptions get authenticationType; String? get bearerToken; String? get description;
/// Create a copy of McpServerFormToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$McpServerFormToCreateCopyWith<McpServerFormToCreate> get copyWith => _$McpServerFormToCreateCopyWithImpl<McpServerFormToCreate>(this as McpServerFormToCreate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is McpServerFormToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,bearerToken,description);

@override
String toString() {
  return 'McpServerFormToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, bearerToken: $bearerToken, description: $description)';
}


}

/// @nodoc
abstract mixin class $McpServerFormToCreateCopyWith<$Res>  {
  factory $McpServerFormToCreateCopyWith(McpServerFormToCreate value, $Res Function(McpServerFormToCreate) _then) = _$McpServerFormToCreateCopyWithImpl;
@useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationTypeOptions authenticationType, String? bearerToken, String? description
});




}
/// @nodoc
class _$McpServerFormToCreateCopyWithImpl<$Res>
    implements $McpServerFormToCreateCopyWith<$Res> {
  _$McpServerFormToCreateCopyWithImpl(this._self, this._then);

  final McpServerFormToCreate _self;
  final $Res Function(McpServerFormToCreate) _then;

/// Create a copy of McpServerFormToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? bearerToken = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationTypeOptions,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [McpServerFormToCreate].
extension McpServerFormToCreatePatterns on McpServerFormToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _McpServerFormToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _McpServerFormToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _McpServerFormToCreate value)  $default,){
final _that = this;
switch (_that) {
case _McpServerFormToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _McpServerFormToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _McpServerFormToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationTypeOptions authenticationType,  String? bearerToken,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _McpServerFormToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  McpTransportType transport,  McpAuthenticationTypeOptions authenticationType,  String? bearerToken,  String? description)  $default,) {final _that = this;
switch (_that) {
case _McpServerFormToCreate():
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  McpTransportType transport,  McpAuthenticationTypeOptions authenticationType,  String? bearerToken,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _McpServerFormToCreate() when $default != null:
return $default(_that.name,_that.url,_that.transport,_that.authenticationType,_that.bearerToken,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _McpServerFormToCreate extends McpServerFormToCreate {
  const _McpServerFormToCreate({required this.name, required this.url, required this.transport, required this.authenticationType, required this.bearerToken, this.description}): super._();
  

@override final  String name;
@override final  String url;
@override final  McpTransportType transport;
@override final  McpAuthenticationTypeOptions authenticationType;
@override final  String? bearerToken;
@override final  String? description;

/// Create a copy of McpServerFormToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$McpServerFormToCreateCopyWith<_McpServerFormToCreate> get copyWith => __$McpServerFormToCreateCopyWithImpl<_McpServerFormToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _McpServerFormToCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.authenticationType, authenticationType) || other.authenticationType == authenticationType)&&(identical(other.bearerToken, bearerToken) || other.bearerToken == bearerToken)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,url,transport,authenticationType,bearerToken,description);

@override
String toString() {
  return 'McpServerFormToCreate(name: $name, url: $url, transport: $transport, authenticationType: $authenticationType, bearerToken: $bearerToken, description: $description)';
}


}

/// @nodoc
abstract mixin class _$McpServerFormToCreateCopyWith<$Res> implements $McpServerFormToCreateCopyWith<$Res> {
  factory _$McpServerFormToCreateCopyWith(_McpServerFormToCreate value, $Res Function(_McpServerFormToCreate) _then) = __$McpServerFormToCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, McpTransportType transport, McpAuthenticationTypeOptions authenticationType, String? bearerToken, String? description
});




}
/// @nodoc
class __$McpServerFormToCreateCopyWithImpl<$Res>
    implements _$McpServerFormToCreateCopyWith<$Res> {
  __$McpServerFormToCreateCopyWithImpl(this._self, this._then);

  final _McpServerFormToCreate _self;
  final $Res Function(_McpServerFormToCreate) _then;

/// Create a copy of McpServerFormToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? transport = null,Object? authenticationType = null,Object? bearerToken = freezed,Object? description = freezed,}) {
  return _then(_McpServerFormToCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as McpTransportType,authenticationType: null == authenticationType ? _self.authenticationType : authenticationType // ignore: cast_nullable_to_non_nullable
as McpAuthenticationTypeOptions,bearerToken: freezed == bearerToken ? _self.bearerToken : bearerToken // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
