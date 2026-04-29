// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'antropic_responses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AntropicResponseModelsItem {

 String get displayName; String get id; String get type; DateTime get createdAt;
/// Create a copy of AntropicResponseModelsItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AntropicResponseModelsItemCopyWith<AntropicResponseModelsItem> get copyWith => _$AntropicResponseModelsItemCopyWithImpl<AntropicResponseModelsItem>(this as AntropicResponseModelsItem, _$identity);

  /// Serializes this AntropicResponseModelsItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntropicResponseModelsItem&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,id,type,createdAt);

@override
String toString() {
  return 'AntropicResponseModelsItem(displayName: $displayName, id: $id, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AntropicResponseModelsItemCopyWith<$Res>  {
  factory $AntropicResponseModelsItemCopyWith(AntropicResponseModelsItem value, $Res Function(AntropicResponseModelsItem) _then) = _$AntropicResponseModelsItemCopyWithImpl;
@useResult
$Res call({
 String displayName, String id, String type, DateTime createdAt
});




}
/// @nodoc
class _$AntropicResponseModelsItemCopyWithImpl<$Res>
    implements $AntropicResponseModelsItemCopyWith<$Res> {
  _$AntropicResponseModelsItemCopyWithImpl(this._self, this._then);

  final AntropicResponseModelsItem _self;
  final $Res Function(AntropicResponseModelsItem) _then;

/// Create a copy of AntropicResponseModelsItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? id = null,Object? type = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AntropicResponseModelsItem].
extension AntropicResponseModelsItemPatterns on AntropicResponseModelsItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AntropicResponseModelsItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AntropicResponseModelsItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AntropicResponseModelsItem value)  $default,){
final _that = this;
switch (_that) {
case _AntropicResponseModelsItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AntropicResponseModelsItem value)?  $default,){
final _that = this;
switch (_that) {
case _AntropicResponseModelsItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String id,  String type,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AntropicResponseModelsItem() when $default != null:
return $default(_that.displayName,_that.id,_that.type,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String id,  String type,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AntropicResponseModelsItem():
return $default(_that.displayName,_that.id,_that.type,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String id,  String type,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AntropicResponseModelsItem() when $default != null:
return $default(_that.displayName,_that.id,_that.type,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _AntropicResponseModelsItem implements AntropicResponseModelsItem {
  const _AntropicResponseModelsItem({required this.displayName, required this.id, required this.type, required this.createdAt});
  factory _AntropicResponseModelsItem.fromJson(Map<String, dynamic> json) => _$AntropicResponseModelsItemFromJson(json);

@override final  String displayName;
@override final  String id;
@override final  String type;
@override final  DateTime createdAt;

/// Create a copy of AntropicResponseModelsItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AntropicResponseModelsItemCopyWith<_AntropicResponseModelsItem> get copyWith => __$AntropicResponseModelsItemCopyWithImpl<_AntropicResponseModelsItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AntropicResponseModelsItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AntropicResponseModelsItem&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,id,type,createdAt);

@override
String toString() {
  return 'AntropicResponseModelsItem(displayName: $displayName, id: $id, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AntropicResponseModelsItemCopyWith<$Res> implements $AntropicResponseModelsItemCopyWith<$Res> {
  factory _$AntropicResponseModelsItemCopyWith(_AntropicResponseModelsItem value, $Res Function(_AntropicResponseModelsItem) _then) = __$AntropicResponseModelsItemCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String id, String type, DateTime createdAt
});




}
/// @nodoc
class __$AntropicResponseModelsItemCopyWithImpl<$Res>
    implements _$AntropicResponseModelsItemCopyWith<$Res> {
  __$AntropicResponseModelsItemCopyWithImpl(this._self, this._then);

  final _AntropicResponseModelsItem _self;
  final $Res Function(_AntropicResponseModelsItem) _then;

/// Create a copy of AntropicResponseModelsItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? id = null,Object? type = null,Object? createdAt = null,}) {
  return _then(_AntropicResponseModelsItem(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AntropicResponseModelsErrorMessage {

 String get message; String get type;
/// Create a copy of AntropicResponseModelsErrorMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AntropicResponseModelsErrorMessageCopyWith<AntropicResponseModelsErrorMessage> get copyWith => _$AntropicResponseModelsErrorMessageCopyWithImpl<AntropicResponseModelsErrorMessage>(this as AntropicResponseModelsErrorMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntropicResponseModelsErrorMessage&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,type);

@override
String toString() {
  return 'AntropicResponseModelsErrorMessage(message: $message, type: $type)';
}


}

/// @nodoc
abstract mixin class $AntropicResponseModelsErrorMessageCopyWith<$Res>  {
  factory $AntropicResponseModelsErrorMessageCopyWith(AntropicResponseModelsErrorMessage value, $Res Function(AntropicResponseModelsErrorMessage) _then) = _$AntropicResponseModelsErrorMessageCopyWithImpl;
@useResult
$Res call({
 String message, String type
});




}
/// @nodoc
class _$AntropicResponseModelsErrorMessageCopyWithImpl<$Res>
    implements $AntropicResponseModelsErrorMessageCopyWith<$Res> {
  _$AntropicResponseModelsErrorMessageCopyWithImpl(this._self, this._then);

  final AntropicResponseModelsErrorMessage _self;
  final $Res Function(AntropicResponseModelsErrorMessage) _then;

/// Create a copy of AntropicResponseModelsErrorMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? type = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AntropicResponseModelsErrorMessage].
extension AntropicResponseModelsErrorMessagePatterns on AntropicResponseModelsErrorMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AntropicResponseModelsErrorMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AntropicResponseModelsErrorMessage value)  $default,){
final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AntropicResponseModelsErrorMessage value)?  $default,){
final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage() when $default != null:
return $default(_that.message,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  String type)  $default,) {final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage():
return $default(_that.message,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  String type)?  $default,) {final _that = this;
switch (_that) {
case _AntropicResponseModelsErrorMessage() when $default != null:
return $default(_that.message,_that.type);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _AntropicResponseModelsErrorMessage implements AntropicResponseModelsErrorMessage {
  const _AntropicResponseModelsErrorMessage({required this.message, required this.type});
  factory _AntropicResponseModelsErrorMessage.fromJson(Map<String, dynamic> json) => _$AntropicResponseModelsErrorMessageFromJson(json);

@override final  String message;
@override final  String type;

/// Create a copy of AntropicResponseModelsErrorMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AntropicResponseModelsErrorMessageCopyWith<_AntropicResponseModelsErrorMessage> get copyWith => __$AntropicResponseModelsErrorMessageCopyWithImpl<_AntropicResponseModelsErrorMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AntropicResponseModelsErrorMessage&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,type);

@override
String toString() {
  return 'AntropicResponseModelsErrorMessage(message: $message, type: $type)';
}


}

/// @nodoc
abstract mixin class _$AntropicResponseModelsErrorMessageCopyWith<$Res> implements $AntropicResponseModelsErrorMessageCopyWith<$Res> {
  factory _$AntropicResponseModelsErrorMessageCopyWith(_AntropicResponseModelsErrorMessage value, $Res Function(_AntropicResponseModelsErrorMessage) _then) = __$AntropicResponseModelsErrorMessageCopyWithImpl;
@override @useResult
$Res call({
 String message, String type
});




}
/// @nodoc
class __$AntropicResponseModelsErrorMessageCopyWithImpl<$Res>
    implements _$AntropicResponseModelsErrorMessageCopyWith<$Res> {
  __$AntropicResponseModelsErrorMessageCopyWithImpl(this._self, this._then);

  final _AntropicResponseModelsErrorMessage _self;
  final $Res Function(_AntropicResponseModelsErrorMessage) _then;

/// Create a copy of AntropicResponseModelsErrorMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? type = null,}) {
  return _then(_AntropicResponseModelsErrorMessage(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AntropicResponseModels {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntropicResponseModels);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AntropicResponseModels()';
}


}

/// @nodoc
class $AntropicResponseModelsCopyWith<$Res>  {
$AntropicResponseModelsCopyWith(AntropicResponseModels _, $Res Function(AntropicResponseModels) __);
}


/// Adds pattern-matching-related methods to [AntropicResponseModels].
extension AntropicResponseModelsPatterns on AntropicResponseModels {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AntropicResponseModelsData value)?  data,TResult Function( AntropicResponseModelsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AntropicResponseModelsData() when data != null:
return data(_that);case AntropicResponseModelsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AntropicResponseModelsData value)  data,required TResult Function( AntropicResponseModelsError value)  error,}){
final _that = this;
switch (_that) {
case AntropicResponseModelsData():
return data(_that);case AntropicResponseModelsError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AntropicResponseModelsData value)?  data,TResult? Function( AntropicResponseModelsError value)?  error,}){
final _that = this;
switch (_that) {
case AntropicResponseModelsData() when data != null:
return data(_that);case AntropicResponseModelsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<AntropicResponseModelsItem> data,  String firstId,  bool hasMore,  String lastId)?  data,TResult Function( AntropicResponseModelsErrorMessage error,  String requestId,  String type)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AntropicResponseModelsData() when data != null:
return data(_that.data,_that.firstId,_that.hasMore,_that.lastId);case AntropicResponseModelsError() when error != null:
return error(_that.error,_that.requestId,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<AntropicResponseModelsItem> data,  String firstId,  bool hasMore,  String lastId)  data,required TResult Function( AntropicResponseModelsErrorMessage error,  String requestId,  String type)  error,}) {final _that = this;
switch (_that) {
case AntropicResponseModelsData():
return data(_that.data,_that.firstId,_that.hasMore,_that.lastId);case AntropicResponseModelsError():
return error(_that.error,_that.requestId,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<AntropicResponseModelsItem> data,  String firstId,  bool hasMore,  String lastId)?  data,TResult? Function( AntropicResponseModelsErrorMessage error,  String requestId,  String type)?  error,}) {final _that = this;
switch (_that) {
case AntropicResponseModelsData() when data != null:
return data(_that.data,_that.firstId,_that.hasMore,_that.lastId);case AntropicResponseModelsError() when error != null:
return error(_that.error,_that.requestId,_that.type);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class AntropicResponseModelsData implements AntropicResponseModels {
  const AntropicResponseModelsData({required final  List<AntropicResponseModelsItem> data, required this.firstId, required this.hasMore, required this.lastId}): _data = data;
  

 final  List<AntropicResponseModelsItem> _data;
 List<AntropicResponseModelsItem> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

 final  String firstId;
 final  bool hasMore;
 final  String lastId;

/// Create a copy of AntropicResponseModels
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AntropicResponseModelsDataCopyWith<AntropicResponseModelsData> get copyWith => _$AntropicResponseModelsDataCopyWithImpl<AntropicResponseModelsData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntropicResponseModelsData&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.firstId, firstId) || other.firstId == firstId)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.lastId, lastId) || other.lastId == lastId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),firstId,hasMore,lastId);

@override
String toString() {
  return 'AntropicResponseModels.data(data: $data, firstId: $firstId, hasMore: $hasMore, lastId: $lastId)';
}


}

/// @nodoc
abstract mixin class $AntropicResponseModelsDataCopyWith<$Res> implements $AntropicResponseModelsCopyWith<$Res> {
  factory $AntropicResponseModelsDataCopyWith(AntropicResponseModelsData value, $Res Function(AntropicResponseModelsData) _then) = _$AntropicResponseModelsDataCopyWithImpl;
@useResult
$Res call({
 List<AntropicResponseModelsItem> data, String firstId, bool hasMore, String lastId
});




}
/// @nodoc
class _$AntropicResponseModelsDataCopyWithImpl<$Res>
    implements $AntropicResponseModelsDataCopyWith<$Res> {
  _$AntropicResponseModelsDataCopyWithImpl(this._self, this._then);

  final AntropicResponseModelsData _self;
  final $Res Function(AntropicResponseModelsData) _then;

/// Create a copy of AntropicResponseModels
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,Object? firstId = null,Object? hasMore = null,Object? lastId = null,}) {
  return _then(AntropicResponseModelsData(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AntropicResponseModelsItem>,firstId: null == firstId ? _self.firstId : firstId // ignore: cast_nullable_to_non_nullable
as String,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,lastId: null == lastId ? _self.lastId : lastId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class AntropicResponseModelsError implements AntropicResponseModels {
  const AntropicResponseModelsError({required this.error, required this.requestId, required this.type});
  

 final  AntropicResponseModelsErrorMessage error;
 final  String requestId;
 final  String type;

/// Create a copy of AntropicResponseModels
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AntropicResponseModelsErrorCopyWith<AntropicResponseModelsError> get copyWith => _$AntropicResponseModelsErrorCopyWithImpl<AntropicResponseModelsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntropicResponseModelsError&&(identical(other.error, error) || other.error == error)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,error,requestId,type);

@override
String toString() {
  return 'AntropicResponseModels.error(error: $error, requestId: $requestId, type: $type)';
}


}

/// @nodoc
abstract mixin class $AntropicResponseModelsErrorCopyWith<$Res> implements $AntropicResponseModelsCopyWith<$Res> {
  factory $AntropicResponseModelsErrorCopyWith(AntropicResponseModelsError value, $Res Function(AntropicResponseModelsError) _then) = _$AntropicResponseModelsErrorCopyWithImpl;
@useResult
$Res call({
 AntropicResponseModelsErrorMessage error, String requestId, String type
});


$AntropicResponseModelsErrorMessageCopyWith<$Res> get error;

}
/// @nodoc
class _$AntropicResponseModelsErrorCopyWithImpl<$Res>
    implements $AntropicResponseModelsErrorCopyWith<$Res> {
  _$AntropicResponseModelsErrorCopyWithImpl(this._self, this._then);

  final AntropicResponseModelsError _self;
  final $Res Function(AntropicResponseModelsError) _then;

/// Create a copy of AntropicResponseModels
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? requestId = null,Object? type = null,}) {
  return _then(AntropicResponseModelsError(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AntropicResponseModelsErrorMessage,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AntropicResponseModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AntropicResponseModelsErrorMessageCopyWith<$Res> get error {
  
  return $AntropicResponseModelsErrorMessageCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on
