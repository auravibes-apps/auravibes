// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messages_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToolCallMessageResult {

 bool get success; String get result; String? get error; DateTime get executedAt;
/// Create a copy of ToolCallMessageResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallMessageResultCopyWith<ToolCallMessageResult> get copyWith => _$ToolCallMessageResultCopyWithImpl<ToolCallMessageResult>(this as ToolCallMessageResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallMessageResult&&(identical(other.success, success) || other.success == success)&&(identical(other.result, result) || other.result == result)&&(identical(other.error, error) || other.error == error)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt));
}


@override
int get hashCode => Object.hash(runtimeType,success,result,error,executedAt);

@override
String toString() {
  return 'ToolCallMessageResult(success: $success, result: $result, error: $error, executedAt: $executedAt)';
}


}

/// @nodoc
abstract mixin class $ToolCallMessageResultCopyWith<$Res>  {
  factory $ToolCallMessageResultCopyWith(ToolCallMessageResult value, $Res Function(ToolCallMessageResult) _then) = _$ToolCallMessageResultCopyWithImpl;
@useResult
$Res call({
 bool success, String result, String? error, DateTime executedAt
});




}
/// @nodoc
class _$ToolCallMessageResultCopyWithImpl<$Res>
    implements $ToolCallMessageResultCopyWith<$Res> {
  _$ToolCallMessageResultCopyWithImpl(this._self, this._then);

  final ToolCallMessageResult _self;
  final $Res Function(ToolCallMessageResult) _then;

/// Create a copy of ToolCallMessageResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? result = null,Object? error = freezed,Object? executedAt = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolCallMessageResult].
extension ToolCallMessageResultPatterns on ToolCallMessageResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolCallMessageResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolCallMessageResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolCallMessageResult value)  $default,){
final _that = this;
switch (_that) {
case _ToolCallMessageResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolCallMessageResult value)?  $default,){
final _that = this;
switch (_that) {
case _ToolCallMessageResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String result,  String? error,  DateTime executedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolCallMessageResult() when $default != null:
return $default(_that.success,_that.result,_that.error,_that.executedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String result,  String? error,  DateTime executedAt)  $default,) {final _that = this;
switch (_that) {
case _ToolCallMessageResult():
return $default(_that.success,_that.result,_that.error,_that.executedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String result,  String? error,  DateTime executedAt)?  $default,) {final _that = this;
switch (_that) {
case _ToolCallMessageResult() when $default != null:
return $default(_that.success,_that.result,_that.error,_that.executedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ToolCallMessageResult implements ToolCallMessageResult {
  const _ToolCallMessageResult({required this.success, required this.result, required this.error, required this.executedAt});
  

@override final  bool success;
@override final  String result;
@override final  String? error;
@override final  DateTime executedAt;

/// Create a copy of ToolCallMessageResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolCallMessageResultCopyWith<_ToolCallMessageResult> get copyWith => __$ToolCallMessageResultCopyWithImpl<_ToolCallMessageResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolCallMessageResult&&(identical(other.success, success) || other.success == success)&&(identical(other.result, result) || other.result == result)&&(identical(other.error, error) || other.error == error)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt));
}


@override
int get hashCode => Object.hash(runtimeType,success,result,error,executedAt);

@override
String toString() {
  return 'ToolCallMessageResult(success: $success, result: $result, error: $error, executedAt: $executedAt)';
}


}

/// @nodoc
abstract mixin class _$ToolCallMessageResultCopyWith<$Res> implements $ToolCallMessageResultCopyWith<$Res> {
  factory _$ToolCallMessageResultCopyWith(_ToolCallMessageResult value, $Res Function(_ToolCallMessageResult) _then) = __$ToolCallMessageResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, String result, String? error, DateTime executedAt
});




}
/// @nodoc
class __$ToolCallMessageResultCopyWithImpl<$Res>
    implements _$ToolCallMessageResultCopyWith<$Res> {
  __$ToolCallMessageResultCopyWithImpl(this._self, this._then);

  final _ToolCallMessageResult _self;
  final $Res Function(_ToolCallMessageResult) _then;

/// Create a copy of ToolCallMessageResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? result = null,Object? error = freezed,Object? executedAt = null,}) {
  return _then(_ToolCallMessageResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ToolCallMessageItem {

 String get id; String get name; Map<String, dynamic> get arguments; String get argumentsRaw; ToolCallMessageResult? get result;
/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallMessageItemCopyWith<ToolCallMessageItem> get copyWith => _$ToolCallMessageItemCopyWithImpl<ToolCallMessageItem>(this as ToolCallMessageItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallMessageItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(arguments),argumentsRaw,result);

@override
String toString() {
  return 'ToolCallMessageItem(id: $id, name: $name, arguments: $arguments, argumentsRaw: $argumentsRaw, result: $result)';
}


}

/// @nodoc
abstract mixin class $ToolCallMessageItemCopyWith<$Res>  {
  factory $ToolCallMessageItemCopyWith(ToolCallMessageItem value, $Res Function(ToolCallMessageItem) _then) = _$ToolCallMessageItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, dynamic> arguments, String argumentsRaw, ToolCallMessageResult? result
});


$ToolCallMessageResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$ToolCallMessageItemCopyWithImpl<$Res>
    implements $ToolCallMessageItemCopyWith<$Res> {
  _$ToolCallMessageItemCopyWithImpl(this._self, this._then);

  final ToolCallMessageItem _self;
  final $Res Function(ToolCallMessageItem) _then;

/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? arguments = null,Object? argumentsRaw = null,Object? result = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ToolCallMessageResult?,
  ));
}
/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallMessageResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ToolCallMessageResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [ToolCallMessageItem].
extension ToolCallMessageItemPatterns on ToolCallMessageItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolCallMessageItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolCallMessageItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolCallMessageItem value)  $default,){
final _that = this;
switch (_that) {
case _ToolCallMessageItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolCallMessageItem value)?  $default,){
final _that = this;
switch (_that) {
case _ToolCallMessageItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  ToolCallMessageResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolCallMessageItem() when $default != null:
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  ToolCallMessageResult? result)  $default,) {final _that = this;
switch (_that) {
case _ToolCallMessageItem():
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Map<String, dynamic> arguments,  String argumentsRaw,  ToolCallMessageResult? result)?  $default,) {final _that = this;
switch (_that) {
case _ToolCallMessageItem() when $default != null:
return $default(_that.id,_that.name,_that.arguments,_that.argumentsRaw,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _ToolCallMessageItem implements ToolCallMessageItem {
  const _ToolCallMessageItem({required this.id, required this.name, required final  Map<String, dynamic> arguments, required this.argumentsRaw, this.result}): _arguments = arguments;
  

@override final  String id;
@override final  String name;
 final  Map<String, dynamic> _arguments;
@override Map<String, dynamic> get arguments {
  if (_arguments is EqualUnmodifiableMapView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_arguments);
}

@override final  String argumentsRaw;
@override final  ToolCallMessageResult? result;

/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolCallMessageItemCopyWith<_ToolCallMessageItem> get copyWith => __$ToolCallMessageItemCopyWithImpl<_ToolCallMessageItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolCallMessageItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_arguments),argumentsRaw,result);

@override
String toString() {
  return 'ToolCallMessageItem(id: $id, name: $name, arguments: $arguments, argumentsRaw: $argumentsRaw, result: $result)';
}


}

/// @nodoc
abstract mixin class _$ToolCallMessageItemCopyWith<$Res> implements $ToolCallMessageItemCopyWith<$Res> {
  factory _$ToolCallMessageItemCopyWith(_ToolCallMessageItem value, $Res Function(_ToolCallMessageItem) _then) = __$ToolCallMessageItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Map<String, dynamic> arguments, String argumentsRaw, ToolCallMessageResult? result
});


@override $ToolCallMessageResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$ToolCallMessageItemCopyWithImpl<$Res>
    implements _$ToolCallMessageItemCopyWith<$Res> {
  __$ToolCallMessageItemCopyWithImpl(this._self, this._then);

  final _ToolCallMessageItem _self;
  final $Res Function(_ToolCallMessageItem) _then;

/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? arguments = null,Object? argumentsRaw = null,Object? result = freezed,}) {
  return _then(_ToolCallMessageItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ToolCallMessageResult?,
  ));
}

/// Create a copy of ToolCallMessageItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallMessageResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ToolCallMessageResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
mixin _$StreamingMessage {

 String get messageId; String get conversationId; String get responseMesageId; String get content; DateTime get createdAt; DateTime get updatedAt; StreamingMessageStatus get status; MessageMetadataEntity? get metadata; List<ToolCallMessageItem>? get toolCalls;/// List of MCP server IDs that are being waited on for connection.
/// Used to display which specific tools are connecting in the UI.
 List<String> get pendingMcpServerIds;
/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamingMessageCopyWith<StreamingMessage> get copyWith => _$StreamingMessageCopyWithImpl<StreamingMessage>(this as StreamingMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamingMessage&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.responseMesageId, responseMesageId) || other.responseMesageId == responseMesageId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls)&&const DeepCollectionEquality().equals(other.pendingMcpServerIds, pendingMcpServerIds));
}


@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,responseMesageId,content,createdAt,updatedAt,status,metadata,const DeepCollectionEquality().hash(toolCalls),const DeepCollectionEquality().hash(pendingMcpServerIds));

@override
String toString() {
  return 'StreamingMessage(messageId: $messageId, conversationId: $conversationId, responseMesageId: $responseMesageId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, metadata: $metadata, toolCalls: $toolCalls, pendingMcpServerIds: $pendingMcpServerIds)';
}


}

/// @nodoc
abstract mixin class $StreamingMessageCopyWith<$Res>  {
  factory $StreamingMessageCopyWith(StreamingMessage value, $Res Function(StreamingMessage) _then) = _$StreamingMessageCopyWithImpl;
@useResult
$Res call({
 String messageId, String conversationId, String responseMesageId, String content, DateTime createdAt, DateTime updatedAt, StreamingMessageStatus status, MessageMetadataEntity? metadata, List<ToolCallMessageItem>? toolCalls, List<String> pendingMcpServerIds
});


$MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$StreamingMessageCopyWithImpl<$Res>
    implements $StreamingMessageCopyWith<$Res> {
  _$StreamingMessageCopyWithImpl(this._self, this._then);

  final StreamingMessage _self;
  final $Res Function(StreamingMessage) _then;

/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? conversationId = null,Object? responseMesageId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? metadata = freezed,Object? toolCalls = freezed,Object? pendingMcpServerIds = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,responseMesageId: null == responseMesageId ? _self.responseMesageId : responseMesageId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StreamingMessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,toolCalls: freezed == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<ToolCallMessageItem>?,pendingMcpServerIds: null == pendingMcpServerIds ? _self.pendingMcpServerIds : pendingMcpServerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [StreamingMessage].
extension StreamingMessagePatterns on StreamingMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamingMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamingMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamingMessage value)  $default,){
final _that = this;
switch (_that) {
case _StreamingMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamingMessage value)?  $default,){
final _that = this;
switch (_that) {
case _StreamingMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String responseMesageId,  String content,  DateTime createdAt,  DateTime updatedAt,  StreamingMessageStatus status,  MessageMetadataEntity? metadata,  List<ToolCallMessageItem>? toolCalls,  List<String> pendingMcpServerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamingMessage() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.responseMesageId,_that.content,_that.createdAt,_that.updatedAt,_that.status,_that.metadata,_that.toolCalls,_that.pendingMcpServerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String responseMesageId,  String content,  DateTime createdAt,  DateTime updatedAt,  StreamingMessageStatus status,  MessageMetadataEntity? metadata,  List<ToolCallMessageItem>? toolCalls,  List<String> pendingMcpServerIds)  $default,) {final _that = this;
switch (_that) {
case _StreamingMessage():
return $default(_that.messageId,_that.conversationId,_that.responseMesageId,_that.content,_that.createdAt,_that.updatedAt,_that.status,_that.metadata,_that.toolCalls,_that.pendingMcpServerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String conversationId,  String responseMesageId,  String content,  DateTime createdAt,  DateTime updatedAt,  StreamingMessageStatus status,  MessageMetadataEntity? metadata,  List<ToolCallMessageItem>? toolCalls,  List<String> pendingMcpServerIds)?  $default,) {final _that = this;
switch (_that) {
case _StreamingMessage() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.responseMesageId,_that.content,_that.createdAt,_that.updatedAt,_that.status,_that.metadata,_that.toolCalls,_that.pendingMcpServerIds);case _:
  return null;

}
}

}

/// @nodoc


class _StreamingMessage implements StreamingMessage {
  const _StreamingMessage({required this.messageId, required this.conversationId, required this.responseMesageId, required this.content, required this.createdAt, required this.updatedAt, required this.status, this.metadata, final  List<ToolCallMessageItem>? toolCalls, final  List<String> pendingMcpServerIds = const []}): _toolCalls = toolCalls,_pendingMcpServerIds = pendingMcpServerIds;
  

@override final  String messageId;
@override final  String conversationId;
@override final  String responseMesageId;
@override final  String content;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  StreamingMessageStatus status;
@override final  MessageMetadataEntity? metadata;
 final  List<ToolCallMessageItem>? _toolCalls;
@override List<ToolCallMessageItem>? get toolCalls {
  final value = _toolCalls;
  if (value == null) return null;
  if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// List of MCP server IDs that are being waited on for connection.
/// Used to display which specific tools are connecting in the UI.
 final  List<String> _pendingMcpServerIds;
/// List of MCP server IDs that are being waited on for connection.
/// Used to display which specific tools are connecting in the UI.
@override@JsonKey() List<String> get pendingMcpServerIds {
  if (_pendingMcpServerIds is EqualUnmodifiableListView) return _pendingMcpServerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingMcpServerIds);
}


/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamingMessageCopyWith<_StreamingMessage> get copyWith => __$StreamingMessageCopyWithImpl<_StreamingMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamingMessage&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.responseMesageId, responseMesageId) || other.responseMesageId == responseMesageId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._toolCalls, _toolCalls)&&const DeepCollectionEquality().equals(other._pendingMcpServerIds, _pendingMcpServerIds));
}


@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,responseMesageId,content,createdAt,updatedAt,status,metadata,const DeepCollectionEquality().hash(_toolCalls),const DeepCollectionEquality().hash(_pendingMcpServerIds));

@override
String toString() {
  return 'StreamingMessage(messageId: $messageId, conversationId: $conversationId, responseMesageId: $responseMesageId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, metadata: $metadata, toolCalls: $toolCalls, pendingMcpServerIds: $pendingMcpServerIds)';
}


}

/// @nodoc
abstract mixin class _$StreamingMessageCopyWith<$Res> implements $StreamingMessageCopyWith<$Res> {
  factory _$StreamingMessageCopyWith(_StreamingMessage value, $Res Function(_StreamingMessage) _then) = __$StreamingMessageCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String conversationId, String responseMesageId, String content, DateTime createdAt, DateTime updatedAt, StreamingMessageStatus status, MessageMetadataEntity? metadata, List<ToolCallMessageItem>? toolCalls, List<String> pendingMcpServerIds
});


@override $MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$StreamingMessageCopyWithImpl<$Res>
    implements _$StreamingMessageCopyWith<$Res> {
  __$StreamingMessageCopyWithImpl(this._self, this._then);

  final _StreamingMessage _self;
  final $Res Function(_StreamingMessage) _then;

/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? conversationId = null,Object? responseMesageId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? metadata = freezed,Object? toolCalls = freezed,Object? pendingMcpServerIds = null,}) {
  return _then(_StreamingMessage(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,responseMesageId: null == responseMesageId ? _self.responseMesageId : responseMesageId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StreamingMessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,toolCalls: freezed == toolCalls ? _self._toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<ToolCallMessageItem>?,pendingMcpServerIds: null == pendingMcpServerIds ? _self._pendingMcpServerIds : pendingMcpServerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of StreamingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MessageMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

// dart format on
