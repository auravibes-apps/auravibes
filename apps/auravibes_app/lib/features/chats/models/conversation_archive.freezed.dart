// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_archive.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationArchive {

 String get title; DateTime get createdAt; DateTime get updatedAt; List<ConversationArchiveMessage> get messages; String? get modelLabel;
/// Create a copy of ConversationArchive
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationArchiveCopyWith<ConversationArchive> get copyWith => _$ConversationArchiveCopyWithImpl<ConversationArchive>(this as ConversationArchive, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationArchive;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationArchive&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.modelLabel, _this.modelLabel) || other.modelLabel == _this.modelLabel));
}


@override
int get hashCode {
  final _this = this as ConversationArchive;
  return Object.hash(runtimeType,_this.title,_this.createdAt,_this.updatedAt,const DeepCollectionEquality().hash(_this.messages),_this.modelLabel);
}

@override
String toString() {
  final _this = this as ConversationArchive;
  return 'ConversationArchive(title: ${_this.title}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, messages: ${_this.messages}, modelLabel: ${_this.modelLabel})';
}


}

/// @nodoc
abstract mixin class $ConversationArchiveCopyWith<$Res>  {
  factory $ConversationArchiveCopyWith(ConversationArchive value, $Res Function(ConversationArchive) _then) = _$ConversationArchiveCopyWithImpl;
@useResult
$Res call({
 String title, DateTime createdAt, DateTime updatedAt, List<ConversationArchiveMessage> messages, String? modelLabel
});




}
/// @nodoc
class _$ConversationArchiveCopyWithImpl<$Res>
    implements $ConversationArchiveCopyWith<$Res> {
  _$ConversationArchiveCopyWithImpl(this._self, this._then);

  final ConversationArchive _self;
  final $Res Function(ConversationArchive) _then;

/// Create a copy of ConversationArchive
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? messages = null,Object? modelLabel = freezed,}) {
  return _then(ConversationArchive(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveMessage>,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationArchive].
extension ConversationArchivePatterns on ConversationArchive {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationArchive value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationArchive() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationArchive value)  $default,){
final _that = this;
switch (_that) {
case _ConversationArchive():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationArchive value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationArchive() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  DateTime createdAt,  DateTime updatedAt,  List<ConversationArchiveMessage> messages,  String? modelLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationArchive() when $default != null:
return $default(_that.title,_that.createdAt,_that.updatedAt,_that.messages,_that.modelLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  DateTime createdAt,  DateTime updatedAt,  List<ConversationArchiveMessage> messages,  String? modelLabel)  $default,) {final _that = this;
switch (_that) {
case _ConversationArchive():
return $default(_that.title,_that.createdAt,_that.updatedAt,_that.messages,_that.modelLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  DateTime createdAt,  DateTime updatedAt,  List<ConversationArchiveMessage> messages,  String? modelLabel)?  $default,) {final _that = this;
switch (_that) {
case _ConversationArchive() when $default != null:
return $default(_that.title,_that.createdAt,_that.updatedAt,_that.messages,_that.modelLabel);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationArchive implements ConversationArchive {
  const _ConversationArchive({required this.title, required this.createdAt, required this.updatedAt, required  List<ConversationArchiveMessage> messages, this.modelLabel}): _messages = messages;
  

@override final  String title;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
 final  List<ConversationArchiveMessage> _messages;
@override List<ConversationArchiveMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override final  String? modelLabel;

/// Create a copy of ConversationArchive
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationArchiveCopyWith<_ConversationArchive> get copyWith => __$ConversationArchiveCopyWithImpl<_ConversationArchive>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationArchive&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.modelLabel, modelLabel) || other.modelLabel == modelLabel));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,createdAt,updatedAt,const DeepCollectionEquality().hash(_messages),modelLabel);
}

@override
String toString() {
    return 'ConversationArchive(title: $title, createdAt: $createdAt, updatedAt: $updatedAt, messages: $messages, modelLabel: $modelLabel)';
}


}

/// @nodoc
abstract mixin class _$ConversationArchiveCopyWith<$Res> implements $ConversationArchiveCopyWith<$Res> {
  factory _$ConversationArchiveCopyWith(_ConversationArchive value, $Res Function(_ConversationArchive) _then) = __$ConversationArchiveCopyWithImpl;
@override @useResult
$Res call({
 String title, DateTime createdAt, DateTime updatedAt, List<ConversationArchiveMessage> messages, String? modelLabel
});




}
/// @nodoc
class __$ConversationArchiveCopyWithImpl<$Res>
    implements _$ConversationArchiveCopyWith<$Res> {
  __$ConversationArchiveCopyWithImpl(this._self, this._then);

  final _ConversationArchive _self;
  final $Res Function(_ConversationArchive) _then;

/// Create a copy of ConversationArchive
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? messages = null,Object? modelLabel = freezed,}) {
  return _then(_ConversationArchive(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveMessage>,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ConversationArchiveMessage {

 String get content; MessageType get messageType; bool get isUser; MessageStatus get status; DateTime get createdAt; ConversationArchiveMetadata get metadata; List<ConversationArchiveAttachment> get attachments;
/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationArchiveMessageCopyWith<ConversationArchiveMessage> get copyWith => _$ConversationArchiveMessageCopyWithImpl<ConversationArchiveMessage>(this as ConversationArchiveMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationArchiveMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationArchiveMessage&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.messageType, _this.messageType) || other.messageType == _this.messageType)&&(identical(other.isUser, _this.isUser) || other.isUser == _this.isUser)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments));
}


@override
int get hashCode {
  final _this = this as ConversationArchiveMessage;
  return Object.hash(runtimeType,_this.content,_this.messageType,_this.isUser,_this.status,_this.createdAt,_this.metadata,const DeepCollectionEquality().hash(_this.attachments));
}

@override
String toString() {
  final _this = this as ConversationArchiveMessage;
  return 'ConversationArchiveMessage(content: ${_this.content}, messageType: ${_this.messageType}, isUser: ${_this.isUser}, status: ${_this.status}, createdAt: ${_this.createdAt}, metadata: ${_this.metadata}, attachments: ${_this.attachments})';
}


}

/// @nodoc
abstract mixin class $ConversationArchiveMessageCopyWith<$Res>  {
  factory $ConversationArchiveMessageCopyWith(ConversationArchiveMessage value, $Res Function(ConversationArchiveMessage) _then) = _$ConversationArchiveMessageCopyWithImpl;
@useResult
$Res call({
 String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, ConversationArchiveMetadata metadata, List<ConversationArchiveAttachment> attachments
});


$ConversationArchiveMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$ConversationArchiveMessageCopyWithImpl<$Res>
    implements $ConversationArchiveMessageCopyWith<$Res> {
  _$ConversationArchiveMessageCopyWithImpl(this._self, this._then);

  final ConversationArchiveMessage _self;
  final $Res Function(ConversationArchiveMessage) _then;

/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? metadata = null,Object? attachments = null,}) {
  return _then(ConversationArchiveMessage(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ConversationArchiveMetadata,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveAttachment>,
  ));
}
/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationArchiveMetadataCopyWith<$Res> get metadata {
  
  return $ConversationArchiveMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationArchiveMessage].
extension ConversationArchiveMessagePatterns on ConversationArchiveMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationArchiveMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationArchiveMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationArchiveMessage value)  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationArchiveMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  ConversationArchiveMetadata metadata,  List<ConversationArchiveAttachment> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationArchiveMessage() when $default != null:
return $default(_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  ConversationArchiveMetadata metadata,  List<ConversationArchiveAttachment> attachments)  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveMessage():
return $default(_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  ConversationArchiveMetadata metadata,  List<ConversationArchiveAttachment> attachments)?  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveMessage() when $default != null:
return $default(_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.metadata,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationArchiveMessage implements ConversationArchiveMessage {
  const _ConversationArchiveMessage({required this.content, required this.messageType, required this.isUser, required this.status, required this.createdAt, required this.metadata, required  List<ConversationArchiveAttachment> attachments}): _attachments = attachments;
  

@override final  String content;
@override final  MessageType messageType;
@override final  bool isUser;
@override final  MessageStatus status;
@override final  DateTime createdAt;
@override final  ConversationArchiveMetadata metadata;
 final  List<ConversationArchiveAttachment> _attachments;
@override List<ConversationArchiveAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationArchiveMessageCopyWith<_ConversationArchiveMessage> get copyWith => __$ConversationArchiveMessageCopyWithImpl<_ConversationArchiveMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationArchiveMessage&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.attachments, _attachments));
}


@override
int get hashCode {
    return Object.hash(runtimeType,content,messageType,isUser,status,createdAt,metadata,const DeepCollectionEquality().hash(_attachments));
}

@override
String toString() {
    return 'ConversationArchiveMessage(content: $content, messageType: $messageType, isUser: $isUser, status: $status, createdAt: $createdAt, metadata: $metadata, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$ConversationArchiveMessageCopyWith<$Res> implements $ConversationArchiveMessageCopyWith<$Res> {
  factory _$ConversationArchiveMessageCopyWith(_ConversationArchiveMessage value, $Res Function(_ConversationArchiveMessage) _then) = __$ConversationArchiveMessageCopyWithImpl;
@override @useResult
$Res call({
 String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, ConversationArchiveMetadata metadata, List<ConversationArchiveAttachment> attachments
});


@override $ConversationArchiveMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$ConversationArchiveMessageCopyWithImpl<$Res>
    implements _$ConversationArchiveMessageCopyWith<$Res> {
  __$ConversationArchiveMessageCopyWithImpl(this._self, this._then);

  final _ConversationArchiveMessage _self;
  final $Res Function(_ConversationArchiveMessage) _then;

/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? metadata = null,Object? attachments = null,}) {
  return _then(_ConversationArchiveMessage(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ConversationArchiveMetadata,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveAttachment>,
  ));
}

/// Create a copy of ConversationArchiveMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationArchiveMetadataCopyWith<$Res> get metadata {
  
  return $ConversationArchiveMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$ConversationArchiveMetadata {

 List<ConversationArchiveToolCall> get toolCalls; List<String> get a2uiMessages; bool get isCompactionSummary; List<int> get compactedMessageIndexes; int? get promptTokens; int? get completionTokens; int? get totalTokens; bool? get providerError; bool? get a2uiRequiresUserAction; CompactionKind? get compactionKind; int? get compactedFromMessageIndex; int? get compactedThroughMessageIndex; DateTime? get compactionCreatedAt;
/// Create a copy of ConversationArchiveMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationArchiveMetadataCopyWith<ConversationArchiveMetadata> get copyWith => _$ConversationArchiveMetadataCopyWithImpl<ConversationArchiveMetadata>(this as ConversationArchiveMetadata, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationArchiveMetadata;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationArchiveMetadata&&const DeepCollectionEquality().equals(other.toolCalls, _this.toolCalls)&&const DeepCollectionEquality().equals(other.a2uiMessages, _this.a2uiMessages)&&(identical(other.isCompactionSummary, _this.isCompactionSummary) || other.isCompactionSummary == _this.isCompactionSummary)&&const DeepCollectionEquality().equals(other.compactedMessageIndexes, _this.compactedMessageIndexes)&&(identical(other.promptTokens, _this.promptTokens) || other.promptTokens == _this.promptTokens)&&(identical(other.completionTokens, _this.completionTokens) || other.completionTokens == _this.completionTokens)&&(identical(other.totalTokens, _this.totalTokens) || other.totalTokens == _this.totalTokens)&&(identical(other.providerError, _this.providerError) || other.providerError == _this.providerError)&&(identical(other.a2uiRequiresUserAction, _this.a2uiRequiresUserAction) || other.a2uiRequiresUserAction == _this.a2uiRequiresUserAction)&&(identical(other.compactionKind, _this.compactionKind) || other.compactionKind == _this.compactionKind)&&(identical(other.compactedFromMessageIndex, _this.compactedFromMessageIndex) || other.compactedFromMessageIndex == _this.compactedFromMessageIndex)&&(identical(other.compactedThroughMessageIndex, _this.compactedThroughMessageIndex) || other.compactedThroughMessageIndex == _this.compactedThroughMessageIndex)&&(identical(other.compactionCreatedAt, _this.compactionCreatedAt) || other.compactionCreatedAt == _this.compactionCreatedAt));
}


@override
int get hashCode {
  final _this = this as ConversationArchiveMetadata;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.toolCalls),const DeepCollectionEquality().hash(_this.a2uiMessages),_this.isCompactionSummary,const DeepCollectionEquality().hash(_this.compactedMessageIndexes),_this.promptTokens,_this.completionTokens,_this.totalTokens,_this.providerError,_this.a2uiRequiresUserAction,_this.compactionKind,_this.compactedFromMessageIndex,_this.compactedThroughMessageIndex,_this.compactionCreatedAt);
}

@override
String toString() {
  final _this = this as ConversationArchiveMetadata;
  return 'ConversationArchiveMetadata(toolCalls: ${_this.toolCalls}, a2uiMessages: ${_this.a2uiMessages}, isCompactionSummary: ${_this.isCompactionSummary}, compactedMessageIndexes: ${_this.compactedMessageIndexes}, promptTokens: ${_this.promptTokens}, completionTokens: ${_this.completionTokens}, totalTokens: ${_this.totalTokens}, providerError: ${_this.providerError}, a2uiRequiresUserAction: ${_this.a2uiRequiresUserAction}, compactionKind: ${_this.compactionKind}, compactedFromMessageIndex: ${_this.compactedFromMessageIndex}, compactedThroughMessageIndex: ${_this.compactedThroughMessageIndex}, compactionCreatedAt: ${_this.compactionCreatedAt})';
}


}

/// @nodoc
abstract mixin class $ConversationArchiveMetadataCopyWith<$Res>  {
  factory $ConversationArchiveMetadataCopyWith(ConversationArchiveMetadata value, $Res Function(ConversationArchiveMetadata) _then) = _$ConversationArchiveMetadataCopyWithImpl;
@useResult
$Res call({
 List<ConversationArchiveToolCall> toolCalls, List<String> a2uiMessages, bool isCompactionSummary, List<int> compactedMessageIndexes, int? promptTokens, int? completionTokens, int? totalTokens, bool? providerError, bool? a2uiRequiresUserAction, CompactionKind? compactionKind, int? compactedFromMessageIndex, int? compactedThroughMessageIndex, DateTime? compactionCreatedAt
});




}
/// @nodoc
class _$ConversationArchiveMetadataCopyWithImpl<$Res>
    implements $ConversationArchiveMetadataCopyWith<$Res> {
  _$ConversationArchiveMetadataCopyWithImpl(this._self, this._then);

  final ConversationArchiveMetadata _self;
  final $Res Function(ConversationArchiveMetadata) _then;

/// Create a copy of ConversationArchiveMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolCalls = null,Object? a2uiMessages = null,Object? isCompactionSummary = null,Object? compactedMessageIndexes = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? providerError = freezed,Object? a2uiRequiresUserAction = freezed,Object? compactionKind = freezed,Object? compactedFromMessageIndex = freezed,Object? compactedThroughMessageIndex = freezed,Object? compactionCreatedAt = freezed,}) {
  return _then(ConversationArchiveMetadata(
toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveToolCall>,a2uiMessages: null == a2uiMessages ? _self.a2uiMessages : a2uiMessages // ignore: cast_nullable_to_non_nullable
as List<String>,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactedMessageIndexes: null == compactedMessageIndexes ? _self.compactedMessageIndexes : compactedMessageIndexes // ignore: cast_nullable_to_non_nullable
as List<int>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,providerError: freezed == providerError ? _self.providerError : providerError // ignore: cast_nullable_to_non_nullable
as bool?,a2uiRequiresUserAction: freezed == a2uiRequiresUserAction ? _self.a2uiRequiresUserAction : a2uiRequiresUserAction // ignore: cast_nullable_to_non_nullable
as bool?,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageIndex: freezed == compactedFromMessageIndex ? _self.compactedFromMessageIndex : compactedFromMessageIndex // ignore: cast_nullable_to_non_nullable
as int?,compactedThroughMessageIndex: freezed == compactedThroughMessageIndex ? _self.compactedThroughMessageIndex : compactedThroughMessageIndex // ignore: cast_nullable_to_non_nullable
as int?,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationArchiveMetadata].
extension ConversationArchiveMetadataPatterns on ConversationArchiveMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationArchiveMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationArchiveMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationArchiveMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationArchiveMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ConversationArchiveToolCall> toolCalls,  List<String> a2uiMessages,  bool isCompactionSummary,  List<int> compactedMessageIndexes,  int? promptTokens,  int? completionTokens,  int? totalTokens,  bool? providerError,  bool? a2uiRequiresUserAction,  CompactionKind? compactionKind,  int? compactedFromMessageIndex,  int? compactedThroughMessageIndex,  DateTime? compactionCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationArchiveMetadata() when $default != null:
return $default(_that.toolCalls,_that.a2uiMessages,_that.isCompactionSummary,_that.compactedMessageIndexes,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.providerError,_that.a2uiRequiresUserAction,_that.compactionKind,_that.compactedFromMessageIndex,_that.compactedThroughMessageIndex,_that.compactionCreatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ConversationArchiveToolCall> toolCalls,  List<String> a2uiMessages,  bool isCompactionSummary,  List<int> compactedMessageIndexes,  int? promptTokens,  int? completionTokens,  int? totalTokens,  bool? providerError,  bool? a2uiRequiresUserAction,  CompactionKind? compactionKind,  int? compactedFromMessageIndex,  int? compactedThroughMessageIndex,  DateTime? compactionCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveMetadata():
return $default(_that.toolCalls,_that.a2uiMessages,_that.isCompactionSummary,_that.compactedMessageIndexes,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.providerError,_that.a2uiRequiresUserAction,_that.compactionKind,_that.compactedFromMessageIndex,_that.compactedThroughMessageIndex,_that.compactionCreatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ConversationArchiveToolCall> toolCalls,  List<String> a2uiMessages,  bool isCompactionSummary,  List<int> compactedMessageIndexes,  int? promptTokens,  int? completionTokens,  int? totalTokens,  bool? providerError,  bool? a2uiRequiresUserAction,  CompactionKind? compactionKind,  int? compactedFromMessageIndex,  int? compactedThroughMessageIndex,  DateTime? compactionCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveMetadata() when $default != null:
return $default(_that.toolCalls,_that.a2uiMessages,_that.isCompactionSummary,_that.compactedMessageIndexes,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.providerError,_that.a2uiRequiresUserAction,_that.compactionKind,_that.compactedFromMessageIndex,_that.compactedThroughMessageIndex,_that.compactionCreatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationArchiveMetadata implements ConversationArchiveMetadata {
  const _ConversationArchiveMetadata({ List<ConversationArchiveToolCall> toolCalls = const <ConversationArchiveToolCall>[],  List<String> a2uiMessages = const <String>[], this.isCompactionSummary = false,  List<int> compactedMessageIndexes = const <int>[], this.promptTokens, this.completionTokens, this.totalTokens, this.providerError, this.a2uiRequiresUserAction, this.compactionKind, this.compactedFromMessageIndex, this.compactedThroughMessageIndex, this.compactionCreatedAt}): _toolCalls = toolCalls,_a2uiMessages = a2uiMessages,_compactedMessageIndexes = compactedMessageIndexes;
  

 final  List<ConversationArchiveToolCall> _toolCalls;
@override@JsonKey() List<ConversationArchiveToolCall> get toolCalls {
  if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolCalls);
}

 final  List<String> _a2uiMessages;
@override@JsonKey() List<String> get a2uiMessages {
  if (_a2uiMessages is EqualUnmodifiableListView) return _a2uiMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_a2uiMessages);
}

@override@JsonKey() final  bool isCompactionSummary;
 final  List<int> _compactedMessageIndexes;
@override@JsonKey() List<int> get compactedMessageIndexes {
  if (_compactedMessageIndexes is EqualUnmodifiableListView) return _compactedMessageIndexes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compactedMessageIndexes);
}

@override final  int? promptTokens;
@override final  int? completionTokens;
@override final  int? totalTokens;
@override final  bool? providerError;
@override final  bool? a2uiRequiresUserAction;
@override final  CompactionKind? compactionKind;
@override final  int? compactedFromMessageIndex;
@override final  int? compactedThroughMessageIndex;
@override final  DateTime? compactionCreatedAt;

/// Create a copy of ConversationArchiveMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationArchiveMetadataCopyWith<_ConversationArchiveMetadata> get copyWith => __$ConversationArchiveMetadataCopyWithImpl<_ConversationArchiveMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationArchiveMetadata&&const DeepCollectionEquality().equals(other.toolCalls, _toolCalls)&&const DeepCollectionEquality().equals(other.a2uiMessages, _a2uiMessages)&&(identical(other.isCompactionSummary, isCompactionSummary) || other.isCompactionSummary == isCompactionSummary)&&const DeepCollectionEquality().equals(other.compactedMessageIndexes, _compactedMessageIndexes)&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.providerError, providerError) || other.providerError == providerError)&&(identical(other.a2uiRequiresUserAction, a2uiRequiresUserAction) || other.a2uiRequiresUserAction == a2uiRequiresUserAction)&&(identical(other.compactionKind, compactionKind) || other.compactionKind == compactionKind)&&(identical(other.compactedFromMessageIndex, compactedFromMessageIndex) || other.compactedFromMessageIndex == compactedFromMessageIndex)&&(identical(other.compactedThroughMessageIndex, compactedThroughMessageIndex) || other.compactedThroughMessageIndex == compactedThroughMessageIndex)&&(identical(other.compactionCreatedAt, compactionCreatedAt) || other.compactionCreatedAt == compactionCreatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_toolCalls),const DeepCollectionEquality().hash(_a2uiMessages),isCompactionSummary,const DeepCollectionEquality().hash(_compactedMessageIndexes),promptTokens,completionTokens,totalTokens,providerError,a2uiRequiresUserAction,compactionKind,compactedFromMessageIndex,compactedThroughMessageIndex,compactionCreatedAt);
}

@override
String toString() {
    return 'ConversationArchiveMetadata(toolCalls: $toolCalls, a2uiMessages: $a2uiMessages, isCompactionSummary: $isCompactionSummary, compactedMessageIndexes: $compactedMessageIndexes, promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens, providerError: $providerError, a2uiRequiresUserAction: $a2uiRequiresUserAction, compactionKind: $compactionKind, compactedFromMessageIndex: $compactedFromMessageIndex, compactedThroughMessageIndex: $compactedThroughMessageIndex, compactionCreatedAt: $compactionCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationArchiveMetadataCopyWith<$Res> implements $ConversationArchiveMetadataCopyWith<$Res> {
  factory _$ConversationArchiveMetadataCopyWith(_ConversationArchiveMetadata value, $Res Function(_ConversationArchiveMetadata) _then) = __$ConversationArchiveMetadataCopyWithImpl;
@override @useResult
$Res call({
 List<ConversationArchiveToolCall> toolCalls, List<String> a2uiMessages, bool isCompactionSummary, List<int> compactedMessageIndexes, int? promptTokens, int? completionTokens, int? totalTokens, bool? providerError, bool? a2uiRequiresUserAction, CompactionKind? compactionKind, int? compactedFromMessageIndex, int? compactedThroughMessageIndex, DateTime? compactionCreatedAt
});




}
/// @nodoc
class __$ConversationArchiveMetadataCopyWithImpl<$Res>
    implements _$ConversationArchiveMetadataCopyWith<$Res> {
  __$ConversationArchiveMetadataCopyWithImpl(this._self, this._then);

  final _ConversationArchiveMetadata _self;
  final $Res Function(_ConversationArchiveMetadata) _then;

/// Create a copy of ConversationArchiveMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolCalls = null,Object? a2uiMessages = null,Object? isCompactionSummary = null,Object? compactedMessageIndexes = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? providerError = freezed,Object? a2uiRequiresUserAction = freezed,Object? compactionKind = freezed,Object? compactedFromMessageIndex = freezed,Object? compactedThroughMessageIndex = freezed,Object? compactionCreatedAt = freezed,}) {
  return _then(_ConversationArchiveMetadata(
toolCalls: null == toolCalls ? _self._toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<ConversationArchiveToolCall>,a2uiMessages: null == a2uiMessages ? _self._a2uiMessages : a2uiMessages // ignore: cast_nullable_to_non_nullable
as List<String>,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactedMessageIndexes: null == compactedMessageIndexes ? _self._compactedMessageIndexes : compactedMessageIndexes // ignore: cast_nullable_to_non_nullable
as List<int>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,providerError: freezed == providerError ? _self.providerError : providerError // ignore: cast_nullable_to_non_nullable
as bool?,a2uiRequiresUserAction: freezed == a2uiRequiresUserAction ? _self.a2uiRequiresUserAction : a2uiRequiresUserAction // ignore: cast_nullable_to_non_nullable
as bool?,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageIndex: freezed == compactedFromMessageIndex ? _self.compactedFromMessageIndex : compactedFromMessageIndex // ignore: cast_nullable_to_non_nullable
as int?,compactedThroughMessageIndex: freezed == compactedThroughMessageIndex ? _self.compactedThroughMessageIndex : compactedThroughMessageIndex // ignore: cast_nullable_to_non_nullable
as int?,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$ConversationArchiveToolCall {

 String? get displayName; ToolCallResultStatus? get resultStatus;
/// Create a copy of ConversationArchiveToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationArchiveToolCallCopyWith<ConversationArchiveToolCall> get copyWith => _$ConversationArchiveToolCallCopyWithImpl<ConversationArchiveToolCall>(this as ConversationArchiveToolCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationArchiveToolCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationArchiveToolCall&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.resultStatus, _this.resultStatus) || other.resultStatus == _this.resultStatus));
}


@override
int get hashCode {
  final _this = this as ConversationArchiveToolCall;
  return Object.hash(runtimeType,_this.displayName,_this.resultStatus);
}

@override
String toString() {
  final _this = this as ConversationArchiveToolCall;
  return 'ConversationArchiveToolCall(displayName: ${_this.displayName}, resultStatus: ${_this.resultStatus})';
}


}

/// @nodoc
abstract mixin class $ConversationArchiveToolCallCopyWith<$Res>  {
  factory $ConversationArchiveToolCallCopyWith(ConversationArchiveToolCall value, $Res Function(ConversationArchiveToolCall) _then) = _$ConversationArchiveToolCallCopyWithImpl;
@useResult
$Res call({
 String? displayName, ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class _$ConversationArchiveToolCallCopyWithImpl<$Res>
    implements $ConversationArchiveToolCallCopyWith<$Res> {
  _$ConversationArchiveToolCallCopyWithImpl(this._self, this._then);

  final ConversationArchiveToolCall _self;
  final $Res Function(ConversationArchiveToolCall) _then;

/// Create a copy of ConversationArchiveToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = freezed,Object? resultStatus = freezed,}) {
  return _then(ConversationArchiveToolCall(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationArchiveToolCall].
extension ConversationArchiveToolCallPatterns on ConversationArchiveToolCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationArchiveToolCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationArchiveToolCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationArchiveToolCall value)  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveToolCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationArchiveToolCall value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveToolCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? displayName,  ToolCallResultStatus? resultStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationArchiveToolCall() when $default != null:
return $default(_that.displayName,_that.resultStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? displayName,  ToolCallResultStatus? resultStatus)  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveToolCall():
return $default(_that.displayName,_that.resultStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? displayName,  ToolCallResultStatus? resultStatus)?  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveToolCall() when $default != null:
return $default(_that.displayName,_that.resultStatus);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationArchiveToolCall implements ConversationArchiveToolCall {
  const _ConversationArchiveToolCall({this.displayName, this.resultStatus});
  

@override final  String? displayName;
@override final  ToolCallResultStatus? resultStatus;

/// Create a copy of ConversationArchiveToolCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationArchiveToolCallCopyWith<_ConversationArchiveToolCall> get copyWith => __$ConversationArchiveToolCallCopyWithImpl<_ConversationArchiveToolCall>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationArchiveToolCall&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.resultStatus, resultStatus) || other.resultStatus == resultStatus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,displayName,resultStatus);
}

@override
String toString() {
    return 'ConversationArchiveToolCall(displayName: $displayName, resultStatus: $resultStatus)';
}


}

/// @nodoc
abstract mixin class _$ConversationArchiveToolCallCopyWith<$Res> implements $ConversationArchiveToolCallCopyWith<$Res> {
  factory _$ConversationArchiveToolCallCopyWith(_ConversationArchiveToolCall value, $Res Function(_ConversationArchiveToolCall) _then) = __$ConversationArchiveToolCallCopyWithImpl;
@override @useResult
$Res call({
 String? displayName, ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class __$ConversationArchiveToolCallCopyWithImpl<$Res>
    implements _$ConversationArchiveToolCallCopyWith<$Res> {
  __$ConversationArchiveToolCallCopyWithImpl(this._self, this._then);

  final _ConversationArchiveToolCall _self;
  final $Res Function(_ConversationArchiveToolCall) _then;

/// Create a copy of ConversationArchiveToolCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = freezed,Object? resultStatus = freezed,}) {
  return _then(_ConversationArchiveToolCall(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}


}

/// @nodoc
mixin _$ConversationArchiveAttachment {

 String get fileName; String get displayName; String get mimeType; MessageAttachmentModality get modality; Uint8List get bytes;
/// Create a copy of ConversationArchiveAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationArchiveAttachmentCopyWith<ConversationArchiveAttachment> get copyWith => _$ConversationArchiveAttachmentCopyWithImpl<ConversationArchiveAttachment>(this as ConversationArchiveAttachment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationArchiveAttachment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationArchiveAttachment&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.modality, _this.modality) || other.modality == _this.modality)&&const DeepCollectionEquality().equals(other.bytes, _this.bytes));
}


@override
int get hashCode {
  final _this = this as ConversationArchiveAttachment;
  return Object.hash(runtimeType,_this.fileName,_this.displayName,_this.mimeType,_this.modality,const DeepCollectionEquality().hash(_this.bytes));
}

@override
String toString() {
  final _this = this as ConversationArchiveAttachment;
  return 'ConversationArchiveAttachment(fileName: ${_this.fileName}, displayName: ${_this.displayName}, mimeType: ${_this.mimeType}, modality: ${_this.modality}, bytes: ${_this.bytes})';
}


}

/// @nodoc
abstract mixin class $ConversationArchiveAttachmentCopyWith<$Res>  {
  factory $ConversationArchiveAttachmentCopyWith(ConversationArchiveAttachment value, $Res Function(ConversationArchiveAttachment) _then) = _$ConversationArchiveAttachmentCopyWithImpl;
@useResult
$Res call({
 String fileName, String displayName, String mimeType, MessageAttachmentModality modality, Uint8List bytes
});




}
/// @nodoc
class _$ConversationArchiveAttachmentCopyWithImpl<$Res>
    implements $ConversationArchiveAttachmentCopyWith<$Res> {
  _$ConversationArchiveAttachmentCopyWithImpl(this._self, this._then);

  final ConversationArchiveAttachment _self;
  final $Res Function(ConversationArchiveAttachment) _then;

/// Create a copy of ConversationArchiveAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? bytes = null,}) {
  return _then(ConversationArchiveAttachment(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationArchiveAttachment].
extension ConversationArchiveAttachmentPatterns on ConversationArchiveAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationArchiveAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationArchiveAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationArchiveAttachment value)  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationArchiveAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationArchiveAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  Uint8List bytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationArchiveAttachment() when $default != null:
return $default(_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.bytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  Uint8List bytes)  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveAttachment():
return $default(_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.bytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  Uint8List bytes)?  $default,) {final _that = this;
switch (_that) {
case _ConversationArchiveAttachment() when $default != null:
return $default(_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.bytes);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationArchiveAttachment implements ConversationArchiveAttachment {
  const _ConversationArchiveAttachment({required this.fileName, required this.displayName, required this.mimeType, required this.modality, required this.bytes});
  

@override final  String fileName;
@override final  String displayName;
@override final  String mimeType;
@override final  MessageAttachmentModality modality;
@override final  Uint8List bytes;

/// Create a copy of ConversationArchiveAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationArchiveAttachmentCopyWith<_ConversationArchiveAttachment> get copyWith => __$ConversationArchiveAttachmentCopyWithImpl<_ConversationArchiveAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationArchiveAttachment&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.modality, modality) || other.modality == modality)&&const DeepCollectionEquality().equals(other.bytes, bytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fileName,displayName,mimeType,modality,const DeepCollectionEquality().hash(bytes));
}

@override
String toString() {
    return 'ConversationArchiveAttachment(fileName: $fileName, displayName: $displayName, mimeType: $mimeType, modality: $modality, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class _$ConversationArchiveAttachmentCopyWith<$Res> implements $ConversationArchiveAttachmentCopyWith<$Res> {
  factory _$ConversationArchiveAttachmentCopyWith(_ConversationArchiveAttachment value, $Res Function(_ConversationArchiveAttachment) _then) = __$ConversationArchiveAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String displayName, String mimeType, MessageAttachmentModality modality, Uint8List bytes
});




}
/// @nodoc
class __$ConversationArchiveAttachmentCopyWithImpl<$Res>
    implements _$ConversationArchiveAttachmentCopyWith<$Res> {
  __$ConversationArchiveAttachmentCopyWithImpl(this._self, this._then);

  final _ConversationArchiveAttachment _self;
  final $Res Function(_ConversationArchiveAttachment) _then;

/// Create a copy of ConversationArchiveAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? bytes = null,}) {
  return _then(_ConversationArchiveAttachment(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$MalformedConversationArchiveException {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedConversationArchiveException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'MalformedConversationArchiveException()';
}


}

/// @nodoc
class $MalformedConversationArchiveExceptionCopyWith<$Res>  {
$MalformedConversationArchiveExceptionCopyWith(MalformedConversationArchiveException _, $Res Function(MalformedConversationArchiveException) __);
}


/// Adds pattern-matching-related methods to [MalformedConversationArchiveException].
extension MalformedConversationArchiveExceptionPatterns on MalformedConversationArchiveException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MalformedConversationArchiveException value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MalformedConversationArchiveException() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MalformedConversationArchiveException value)  $default,){
final _that = this;
switch (_that) {
case _MalformedConversationArchiveException():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MalformedConversationArchiveException value)?  $default,){
final _that = this;
switch (_that) {
case _MalformedConversationArchiveException() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function()?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MalformedConversationArchiveException() when $default != null:
return $default();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function()  $default,) {final _that = this;
switch (_that) {
case _MalformedConversationArchiveException():
return $default();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function()?  $default,) {final _that = this;
switch (_that) {
case _MalformedConversationArchiveException() when $default != null:
return $default();case _:
  return null;

}
}

}

/// @nodoc


class _MalformedConversationArchiveException extends MalformedConversationArchiveException {
  const _MalformedConversationArchiveException(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MalformedConversationArchiveException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'MalformedConversationArchiveException()';
}


}




/// @nodoc
mixin _$UnsupportedArchiveVersionException {

 int get version;
/// Create a copy of UnsupportedArchiveVersionException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnsupportedArchiveVersionExceptionCopyWith<UnsupportedArchiveVersionException> get copyWith => _$UnsupportedArchiveVersionExceptionCopyWithImpl<UnsupportedArchiveVersionException>(this as UnsupportedArchiveVersionException, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UnsupportedArchiveVersionException;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnsupportedArchiveVersionException&&(identical(other.version, _this.version) || other.version == _this.version));
}


@override
int get hashCode {
  final _this = this as UnsupportedArchiveVersionException;
  return Object.hash(runtimeType,_this.version);
}

@override
String toString() {
  final _this = this as UnsupportedArchiveVersionException;
  return 'UnsupportedArchiveVersionException(version: ${_this.version})';
}


}

/// @nodoc
abstract mixin class $UnsupportedArchiveVersionExceptionCopyWith<$Res>  {
  factory $UnsupportedArchiveVersionExceptionCopyWith(UnsupportedArchiveVersionException value, $Res Function(UnsupportedArchiveVersionException) _then) = _$UnsupportedArchiveVersionExceptionCopyWithImpl;
@useResult
$Res call({
 int version
});




}
/// @nodoc
class _$UnsupportedArchiveVersionExceptionCopyWithImpl<$Res>
    implements $UnsupportedArchiveVersionExceptionCopyWith<$Res> {
  _$UnsupportedArchiveVersionExceptionCopyWithImpl(this._self, this._then);

  final UnsupportedArchiveVersionException _self;
  final $Res Function(UnsupportedArchiveVersionException) _then;

/// Create a copy of UnsupportedArchiveVersionException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,}) {
  return _then(UnsupportedArchiveVersionException(
null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UnsupportedArchiveVersionException].
extension UnsupportedArchiveVersionExceptionPatterns on UnsupportedArchiveVersionException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnsupportedArchiveVersionException value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnsupportedArchiveVersionException value)  $default,){
final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnsupportedArchiveVersionException value)?  $default,){
final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException() when $default != null:
return $default(_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version)  $default,) {final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException():
return $default(_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version)?  $default,) {final _that = this;
switch (_that) {
case _UnsupportedArchiveVersionException() when $default != null:
return $default(_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _UnsupportedArchiveVersionException extends UnsupportedArchiveVersionException {
  const _UnsupportedArchiveVersionException(this.version): super._();
  

@override final  int version;

/// Create a copy of UnsupportedArchiveVersionException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnsupportedArchiveVersionExceptionCopyWith<_UnsupportedArchiveVersionException> get copyWith => __$UnsupportedArchiveVersionExceptionCopyWithImpl<_UnsupportedArchiveVersionException>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnsupportedArchiveVersionException&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode {
    return Object.hash(runtimeType,version);
}

@override
String toString() {
    return 'UnsupportedArchiveVersionException(version: $version)';
}


}

/// @nodoc
abstract mixin class _$UnsupportedArchiveVersionExceptionCopyWith<$Res> implements $UnsupportedArchiveVersionExceptionCopyWith<$Res> {
  factory _$UnsupportedArchiveVersionExceptionCopyWith(_UnsupportedArchiveVersionException value, $Res Function(_UnsupportedArchiveVersionException) _then) = __$UnsupportedArchiveVersionExceptionCopyWithImpl;
@override @useResult
$Res call({
 int version
});




}
/// @nodoc
class __$UnsupportedArchiveVersionExceptionCopyWithImpl<$Res>
    implements _$UnsupportedArchiveVersionExceptionCopyWith<$Res> {
  __$UnsupportedArchiveVersionExceptionCopyWithImpl(this._self, this._then);

  final _UnsupportedArchiveVersionException _self;
  final $Res Function(_UnsupportedArchiveVersionException) _then;

/// Create a copy of UnsupportedArchiveVersionException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,}) {
  return _then(_UnsupportedArchiveVersionException(
null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
