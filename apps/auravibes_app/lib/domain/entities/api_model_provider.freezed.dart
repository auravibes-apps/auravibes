// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_model_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiModelProviderEntity {

/// Unique identifier for the provider
 String get id;/// Human-readable name of the provider
 String get name; ModelProvidersType? get type;/// API endpoint URL for the provider
 String? get url;/// Documentation URL for the provider
 String? get doc;
/// Create a copy of ApiModelProviderEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiModelProviderEntityCopyWith<ApiModelProviderEntity> get copyWith => _$ApiModelProviderEntityCopyWithImpl<ApiModelProviderEntity>(this as ApiModelProviderEntity, _$identity);

  /// Serializes this ApiModelProviderEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiModelProviderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.doc, doc) || other.doc == doc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,url,doc);

@override
String toString() {
  return 'ApiModelProviderEntity(id: $id, name: $name, type: $type, url: $url, doc: $doc)';
}


}

/// @nodoc
abstract mixin class $ApiModelProviderEntityCopyWith<$Res>  {
  factory $ApiModelProviderEntityCopyWith(ApiModelProviderEntity value, $Res Function(ApiModelProviderEntity) _then) = _$ApiModelProviderEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, ModelProvidersType? type, String? url, String? doc
});




}
/// @nodoc
class _$ApiModelProviderEntityCopyWithImpl<$Res>
    implements $ApiModelProviderEntityCopyWith<$Res> {
  _$ApiModelProviderEntityCopyWithImpl(this._self, this._then);

  final ApiModelProviderEntity _self;
  final $Res Function(ApiModelProviderEntity) _then;

/// Create a copy of ApiModelProviderEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = freezed,Object? url = freezed,Object? doc = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ModelProvidersType?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,doc: freezed == doc ? _self.doc : doc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiModelProviderEntity].
extension ApiModelProviderEntityPatterns on ApiModelProviderEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiModelProviderEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiModelProviderEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiModelProviderEntity value)  $default,){
final _that = this;
switch (_that) {
case _ApiModelProviderEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiModelProviderEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ApiModelProviderEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ModelProvidersType? type,  String? url,  String? doc)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiModelProviderEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.url,_that.doc);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ModelProvidersType? type,  String? url,  String? doc)  $default,) {final _that = this;
switch (_that) {
case _ApiModelProviderEntity():
return $default(_that.id,_that.name,_that.type,_that.url,_that.doc);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ModelProvidersType? type,  String? url,  String? doc)?  $default,) {final _that = this;
switch (_that) {
case _ApiModelProviderEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.url,_that.doc);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiModelProviderEntity extends ApiModelProviderEntity {
  const _ApiModelProviderEntity({required this.id, required this.name, required this.type, this.url, this.doc}): super._();
  factory _ApiModelProviderEntity.fromJson(Map<String, dynamic> json) => _$ApiModelProviderEntityFromJson(json);

/// Unique identifier for the provider
@override final  String id;
/// Human-readable name of the provider
@override final  String name;
@override final  ModelProvidersType? type;
/// API endpoint URL for the provider
@override final  String? url;
/// Documentation URL for the provider
@override final  String? doc;

/// Create a copy of ApiModelProviderEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiModelProviderEntityCopyWith<_ApiModelProviderEntity> get copyWith => __$ApiModelProviderEntityCopyWithImpl<_ApiModelProviderEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiModelProviderEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiModelProviderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.doc, doc) || other.doc == doc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,url,doc);

@override
String toString() {
  return 'ApiModelProviderEntity(id: $id, name: $name, type: $type, url: $url, doc: $doc)';
}


}

/// @nodoc
abstract mixin class _$ApiModelProviderEntityCopyWith<$Res> implements $ApiModelProviderEntityCopyWith<$Res> {
  factory _$ApiModelProviderEntityCopyWith(_ApiModelProviderEntity value, $Res Function(_ApiModelProviderEntity) _then) = __$ApiModelProviderEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ModelProvidersType? type, String? url, String? doc
});




}
/// @nodoc
class __$ApiModelProviderEntityCopyWithImpl<$Res>
    implements _$ApiModelProviderEntityCopyWith<$Res> {
  __$ApiModelProviderEntityCopyWithImpl(this._self, this._then);

  final _ApiModelProviderEntity _self;
  final $Res Function(_ApiModelProviderEntity) _then;

/// Create a copy of ApiModelProviderEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = freezed,Object? url = freezed,Object? doc = freezed,}) {
  return _then(_ApiModelProviderEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ModelProvidersType?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,doc: freezed == doc ? _self.doc : doc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
