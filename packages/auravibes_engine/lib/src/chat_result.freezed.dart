// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatResult<T> {

 T get output; ChatFinishReason get finishReason; LanguageModelUsage? get usage; Map<String, dynamic> get metadata; String? get thinking;
/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatResultCopyWith<T, ChatResult<T>> get copyWith => _$ChatResultCopyWithImpl<T, ChatResult<T>>(this as ChatResult<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatResult<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatResult<T>&&const DeepCollectionEquality().equals(other.output, _this.output)&&(identical(other.finishReason, _this.finishReason) || other.finishReason == _this.finishReason)&&(identical(other.usage, _this.usage) || other.usage == _this.usage)&&const DeepCollectionEquality().equals(other.metadata, _this.metadata)&&(identical(other.thinking, _this.thinking) || other.thinking == _this.thinking));
}


@override
int get hashCode {
  final _this = this as ChatResult<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.output),_this.finishReason,_this.usage,const DeepCollectionEquality().hash(_this.metadata),_this.thinking);
}

@override
String toString() {
  final _this = this as ChatResult<T>;
  return 'ChatResult<$T>(output: ${_this.output}, finishReason: ${_this.finishReason}, usage: ${_this.usage}, metadata: ${_this.metadata}, thinking: ${_this.thinking})';
}


}

/// @nodoc
abstract mixin class $ChatResultCopyWith<T,$Res>  {
  factory $ChatResultCopyWith(ChatResult<T> value, $Res Function(ChatResult<T>) _then) = _$ChatResultCopyWithImpl;
@useResult
$Res call({
 T output, ChatFinishReason finishReason, LanguageModelUsage? usage, Map<String, dynamic> metadata, String? thinking
});


$LanguageModelUsageCopyWith<$Res>? get usage;

}
/// @nodoc
class _$ChatResultCopyWithImpl<T,$Res>
    implements $ChatResultCopyWith<T, $Res> {
  _$ChatResultCopyWithImpl(this._self, this._then);

  final ChatResult<T> _self;
  final $Res Function(ChatResult<T>) _then;

/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? output = freezed,Object? finishReason = null,Object? usage = freezed,Object? metadata = null,Object? thinking = freezed,}) {
  return _then(ChatResult(
output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as T,finishReason: null == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as ChatFinishReason,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as LanguageModelUsage?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LanguageModelUsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $LanguageModelUsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatResult].
extension ChatResultPatterns<T> on ChatResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatResult<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatResult<T> value)  $default,){
final _that = this;
switch (_that) {
case _ChatResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatResult<T> value)?  $default,){
final _that = this;
switch (_that) {
case _ChatResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T output,  ChatFinishReason finishReason,  LanguageModelUsage? usage,  Map<String, dynamic> metadata,  String? thinking)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatResult() when $default != null:
return $default(_that.output,_that.finishReason,_that.usage,_that.metadata,_that.thinking);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T output,  ChatFinishReason finishReason,  LanguageModelUsage? usage,  Map<String, dynamic> metadata,  String? thinking)  $default,) {final _that = this;
switch (_that) {
case _ChatResult():
return $default(_that.output,_that.finishReason,_that.usage,_that.metadata,_that.thinking);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T output,  ChatFinishReason finishReason,  LanguageModelUsage? usage,  Map<String, dynamic> metadata,  String? thinking)?  $default,) {final _that = this;
switch (_that) {
case _ChatResult() when $default != null:
return $default(_that.output,_that.finishReason,_that.usage,_that.metadata,_that.thinking);case _:
  return null;

}
}

}

/// @nodoc


class _ChatResult<T> implements ChatResult<T> {
  const _ChatResult({required this.output, this.finishReason = ChatFinishReason.unspecified, this.usage,  Map<String, dynamic> metadata = const <String, dynamic>{}, this.thinking}): _metadata = metadata;
  

@override final  T output;
@override@JsonKey() final  ChatFinishReason finishReason;
@override final  LanguageModelUsage? usage;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  String? thinking;

/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatResultCopyWith<T, _ChatResult<T>> get copyWith => __$ChatResultCopyWithImpl<T, _ChatResult<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatResult<T>&&const DeepCollectionEquality().equals(other.output, output)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason)&&(identical(other.usage, usage) || other.usage == usage)&&const DeepCollectionEquality().equals(other.metadata, _metadata)&&(identical(other.thinking, thinking) || other.thinking == thinking));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(output),finishReason,usage,const DeepCollectionEquality().hash(_metadata),thinking);
}

@override
String toString() {
    return 'ChatResult<$T>(output: $output, finishReason: $finishReason, usage: $usage, metadata: $metadata, thinking: $thinking)';
}


}

/// @nodoc
abstract mixin class _$ChatResultCopyWith<T,$Res> implements $ChatResultCopyWith<T, $Res> {
  factory _$ChatResultCopyWith(_ChatResult<T> value, $Res Function(_ChatResult<T>) _then) = __$ChatResultCopyWithImpl;
@override @useResult
$Res call({
 T output, ChatFinishReason finishReason, LanguageModelUsage? usage, Map<String, dynamic> metadata, String? thinking
});


@override $LanguageModelUsageCopyWith<$Res>? get usage;

}
/// @nodoc
class __$ChatResultCopyWithImpl<T,$Res>
    implements _$ChatResultCopyWith<T, $Res> {
  __$ChatResultCopyWithImpl(this._self, this._then);

  final _ChatResult<T> _self;
  final $Res Function(_ChatResult<T>) _then;

/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? output = freezed,Object? finishReason = null,Object? usage = freezed,Object? metadata = null,Object? thinking = freezed,}) {
  return _then(_ChatResult<T>(
output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as T,finishReason: null == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as ChatFinishReason,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as LanguageModelUsage?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LanguageModelUsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $LanguageModelUsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc
mixin _$ChatMessage {

 ChatMessageRole get role; String get content; List<Part> get parts; Map<String, dynamic> get metadata;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.content, _this.content) || other.content == _this.content)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.metadata, _this.metadata));
}


@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.role,_this.content,const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.metadata));
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(role: ${_this.role}, content: ${_this.content}, parts: ${_this.parts}, metadata: ${_this.metadata})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 ChatMessageRole role, String content, List<Part> parts, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? content = null,Object? parts = null,Object? metadata = null,}) {
  return _then(ChatMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatMessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<Part>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatMessageRole role,  String content,  List<Part> parts,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.role,_that.content,_that.parts,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatMessageRole role,  String content,  List<Part> parts,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.role,_that.content,_that.parts,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatMessageRole role,  String content,  List<Part> parts,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.role,_that.content,_that.parts,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage extends ChatMessage {
  const _ChatMessage({required this.role, this.content = '',  List<Part> parts = const <Part>[],  Map<String, dynamic> metadata = const <String, dynamic>{}}): _parts = parts,_metadata = metadata,super._();
  

@override final  ChatMessageRole role;
@override@JsonKey() final  String content;
 final  List<Part> _parts;
@override@JsonKey() List<Part> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.metadata, _metadata));
}


@override
int get hashCode {
    return Object.hash(runtimeType,role,content,const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_metadata));
}

@override
String toString() {
    return 'ChatMessage(role: $role, content: $content, parts: $parts, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 ChatMessageRole role, String content, List<Part> parts, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? content = null,Object? parts = null,Object? metadata = null,}) {
  return _then(_ChatMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatMessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<Part>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$LanguageModelUsage {

 int? get promptTokens; int? get responseTokens; int? get totalTokens;
/// Create a copy of LanguageModelUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageModelUsageCopyWith<LanguageModelUsage> get copyWith => _$LanguageModelUsageCopyWithImpl<LanguageModelUsage>(this as LanguageModelUsage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LanguageModelUsage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageModelUsage&&(identical(other.promptTokens, _this.promptTokens) || other.promptTokens == _this.promptTokens)&&(identical(other.responseTokens, _this.responseTokens) || other.responseTokens == _this.responseTokens)&&(identical(other.totalTokens, _this.totalTokens) || other.totalTokens == _this.totalTokens));
}


@override
int get hashCode {
  final _this = this as LanguageModelUsage;
  return Object.hash(runtimeType,_this.promptTokens,_this.responseTokens,_this.totalTokens);
}

@override
String toString() {
  final _this = this as LanguageModelUsage;
  return 'LanguageModelUsage(promptTokens: ${_this.promptTokens}, responseTokens: ${_this.responseTokens}, totalTokens: ${_this.totalTokens})';
}


}

/// @nodoc
abstract mixin class $LanguageModelUsageCopyWith<$Res>  {
  factory $LanguageModelUsageCopyWith(LanguageModelUsage value, $Res Function(LanguageModelUsage) _then) = _$LanguageModelUsageCopyWithImpl;
@useResult
$Res call({
 int? promptTokens, int? responseTokens, int? totalTokens
});




}
/// @nodoc
class _$LanguageModelUsageCopyWithImpl<$Res>
    implements $LanguageModelUsageCopyWith<$Res> {
  _$LanguageModelUsageCopyWithImpl(this._self, this._then);

  final LanguageModelUsage _self;
  final $Res Function(LanguageModelUsage) _then;

/// Create a copy of LanguageModelUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptTokens = freezed,Object? responseTokens = freezed,Object? totalTokens = freezed,}) {
  return _then(LanguageModelUsage(
promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,responseTokens: freezed == responseTokens ? _self.responseTokens : responseTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LanguageModelUsage].
extension LanguageModelUsagePatterns on LanguageModelUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanguageModelUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanguageModelUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanguageModelUsage value)  $default,){
final _that = this;
switch (_that) {
case _LanguageModelUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanguageModelUsage value)?  $default,){
final _that = this;
switch (_that) {
case _LanguageModelUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? promptTokens,  int? responseTokens,  int? totalTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanguageModelUsage() when $default != null:
return $default(_that.promptTokens,_that.responseTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? promptTokens,  int? responseTokens,  int? totalTokens)  $default,) {final _that = this;
switch (_that) {
case _LanguageModelUsage():
return $default(_that.promptTokens,_that.responseTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? promptTokens,  int? responseTokens,  int? totalTokens)?  $default,) {final _that = this;
switch (_that) {
case _LanguageModelUsage() when $default != null:
return $default(_that.promptTokens,_that.responseTokens,_that.totalTokens);case _:
  return null;

}
}

}

/// @nodoc


class _LanguageModelUsage extends LanguageModelUsage {
  const _LanguageModelUsage({this.promptTokens, this.responseTokens, this.totalTokens}): super._();
  

@override final  int? promptTokens;
@override final  int? responseTokens;
@override final  int? totalTokens;

/// Create a copy of LanguageModelUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguageModelUsageCopyWith<_LanguageModelUsage> get copyWith => __$LanguageModelUsageCopyWithImpl<_LanguageModelUsage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanguageModelUsage&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.responseTokens, responseTokens) || other.responseTokens == responseTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens));
}


@override
int get hashCode {
    return Object.hash(runtimeType,promptTokens,responseTokens,totalTokens);
}

@override
String toString() {
    return 'LanguageModelUsage(promptTokens: $promptTokens, responseTokens: $responseTokens, totalTokens: $totalTokens)';
}


}

/// @nodoc
abstract mixin class _$LanguageModelUsageCopyWith<$Res> implements $LanguageModelUsageCopyWith<$Res> {
  factory _$LanguageModelUsageCopyWith(_LanguageModelUsage value, $Res Function(_LanguageModelUsage) _then) = __$LanguageModelUsageCopyWithImpl;
@override @useResult
$Res call({
 int? promptTokens, int? responseTokens, int? totalTokens
});




}
/// @nodoc
class __$LanguageModelUsageCopyWithImpl<$Res>
    implements _$LanguageModelUsageCopyWith<$Res> {
  __$LanguageModelUsageCopyWithImpl(this._self, this._then);

  final _LanguageModelUsage _self;
  final $Res Function(_LanguageModelUsage) _then;

/// Create a copy of LanguageModelUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptTokens = freezed,Object? responseTokens = freezed,Object? totalTokens = freezed,}) {
  return _then(_LanguageModelUsage(
promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,responseTokens: freezed == responseTokens ? _self.responseTokens : responseTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
