// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_model_provider_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddModelProviderModel {

 String? get name; String? get modelId; String? get key; String? get url;
/// Create a copy of AddModelProviderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddModelProviderModelCopyWith<AddModelProviderModel> get copyWith => _$AddModelProviderModelCopyWithImpl<AddModelProviderModel>(this as AddModelProviderModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddModelProviderModel&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,modelId,key,url);

@override
String toString() {
  return 'AddModelProviderModel(name: $name, modelId: $modelId, key: $key, url: $url)';
}


}

/// @nodoc
abstract mixin class $AddModelProviderModelCopyWith<$Res>  {
  factory $AddModelProviderModelCopyWith(AddModelProviderModel value, $Res Function(AddModelProviderModel) _then) = _$AddModelProviderModelCopyWithImpl;
@useResult
$Res call({
 String? name, String? modelId, String? key, String? url
});




}
/// @nodoc
class _$AddModelProviderModelCopyWithImpl<$Res>
    implements $AddModelProviderModelCopyWith<$Res> {
  _$AddModelProviderModelCopyWithImpl(this._self, this._then);

  final AddModelProviderModel _self;
  final $Res Function(AddModelProviderModel) _then;

/// Create a copy of AddModelProviderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? modelId = freezed,Object? key = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddModelProviderModel].
extension AddModelProviderModelPatterns on AddModelProviderModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddModelProviderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddModelProviderModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddModelProviderModel value)  $default,){
final _that = this;
switch (_that) {
case _AddModelProviderModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddModelProviderModel value)?  $default,){
final _that = this;
switch (_that) {
case _AddModelProviderModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? modelId,  String? key,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddModelProviderModel() when $default != null:
return $default(_that.name,_that.modelId,_that.key,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? modelId,  String? key,  String? url)  $default,) {final _that = this;
switch (_that) {
case _AddModelProviderModel():
return $default(_that.name,_that.modelId,_that.key,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? modelId,  String? key,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _AddModelProviderModel() when $default != null:
return $default(_that.name,_that.modelId,_that.key,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _AddModelProviderModel extends AddModelProviderModel {
  const _AddModelProviderModel({this.name, this.modelId, this.key, this.url}): super._();
  

@override final  String? name;
@override final  String? modelId;
@override final  String? key;
@override final  String? url;

/// Create a copy of AddModelProviderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddModelProviderModelCopyWith<_AddModelProviderModel> get copyWith => __$AddModelProviderModelCopyWithImpl<_AddModelProviderModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddModelProviderModel&&(identical(other.name, name) || other.name == name)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,name,modelId,key,url);

@override
String toString() {
  return 'AddModelProviderModel(name: $name, modelId: $modelId, key: $key, url: $url)';
}


}

/// @nodoc
abstract mixin class _$AddModelProviderModelCopyWith<$Res> implements $AddModelProviderModelCopyWith<$Res> {
  factory _$AddModelProviderModelCopyWith(_AddModelProviderModel value, $Res Function(_AddModelProviderModel) _then) = __$AddModelProviderModelCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? modelId, String? key, String? url
});




}
/// @nodoc
class __$AddModelProviderModelCopyWithImpl<$Res>
    implements _$AddModelProviderModelCopyWith<$Res> {
  __$AddModelProviderModelCopyWithImpl(this._self, this._then);

  final _AddModelProviderModel _self;
  final $Res Function(_AddModelProviderModel) _then;

/// Create a copy of AddModelProviderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? modelId = freezed,Object? key = freezed,Object? url = freezed,}) {
  return _then(_AddModelProviderModel(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
