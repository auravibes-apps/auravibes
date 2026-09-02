// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_tool_call_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageToolCallEntity {

 String get id; String get name; String get argumentsRaw;@JsonKey(includeIfNull: false) String? get argumentsDigest;@JsonKey(includeIfNull: false) String? get turnId;@JsonKey(includeIfNull: false) int? get turnRevision;/// The raw response from tool execution, if successful.
 String? get responseRaw;/// The result status of this tool call.
///
/// Null means the tool is awaiting approval. A non-null value means the
/// tool is running or completed with this result status.
@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? get resultStatus;
/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageToolCallEntityCopyWith<MessageToolCallEntity> get copyWith => _$MessageToolCallEntityCopyWithImpl<MessageToolCallEntity>(this as MessageToolCallEntity, _$identity);

  /// Serializes this MessageToolCallEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MessageToolCallEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageToolCallEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.argumentsRaw, _this.argumentsRaw) || other.argumentsRaw == _this.argumentsRaw)&&(identical(other.argumentsDigest, _this.argumentsDigest) || other.argumentsDigest == _this.argumentsDigest)&&(identical(other.turnId, _this.turnId) || other.turnId == _this.turnId)&&(identical(other.turnRevision, _this.turnRevision) || other.turnRevision == _this.turnRevision)&&(identical(other.responseRaw, _this.responseRaw) || other.responseRaw == _this.responseRaw)&&(identical(other.resultStatus, _this.resultStatus) || other.resultStatus == _this.resultStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MessageToolCallEntity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.argumentsRaw,_this.argumentsDigest,_this.turnId,_this.turnRevision,_this.responseRaw,_this.resultStatus);
}



}

/// @nodoc
abstract mixin class $MessageToolCallEntityCopyWith<$Res>  {
  factory $MessageToolCallEntityCopyWith(MessageToolCallEntity value, $Res Function(MessageToolCallEntity) _then) = _$MessageToolCallEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String argumentsRaw,@JsonKey(includeIfNull: false) String? argumentsDigest,@JsonKey(includeIfNull: false) String? turnId,@JsonKey(includeIfNull: false) int? turnRevision, String? responseRaw,@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class _$MessageToolCallEntityCopyWithImpl<$Res>
    implements $MessageToolCallEntityCopyWith<$Res> {
  _$MessageToolCallEntityCopyWithImpl(this._self, this._then);

  final MessageToolCallEntity _self;
  final $Res Function(MessageToolCallEntity) _then;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? argumentsRaw = null,Object? argumentsDigest = freezed,Object? turnId = freezed,Object? turnRevision = freezed,Object? responseRaw = freezed,Object? resultStatus = freezed,}) {
  return _then(MessageToolCallEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,argumentsDigest: freezed == argumentsDigest ? _self.argumentsDigest : argumentsDigest // ignore: cast_nullable_to_non_nullable
as String?,turnId: freezed == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String?,turnRevision: freezed == turnRevision ? _self.turnRevision : turnRevision // ignore: cast_nullable_to_non_nullable
as int?,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageToolCallEntity].
extension MessageToolCallEntityPatterns on MessageToolCallEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageToolCallEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageToolCallEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageToolCallEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageToolCallEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String argumentsRaw, @JsonKey(includeIfNull: false)  String? argumentsDigest, @JsonKey(includeIfNull: false)  String? turnId, @JsonKey(includeIfNull: false)  int? turnRevision,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that.id,_that.name,_that.argumentsRaw,_that.argumentsDigest,_that.turnId,_that.turnRevision,_that.responseRaw,_that.resultStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String argumentsRaw, @JsonKey(includeIfNull: false)  String? argumentsDigest, @JsonKey(includeIfNull: false)  String? turnId, @JsonKey(includeIfNull: false)  int? turnRevision,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)  $default,) {final _that = this;
switch (_that) {
case _MessageToolCallEntity():
return $default(_that.id,_that.name,_that.argumentsRaw,_that.argumentsDigest,_that.turnId,_that.turnRevision,_that.responseRaw,_that.resultStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String argumentsRaw, @JsonKey(includeIfNull: false)  String? argumentsDigest, @JsonKey(includeIfNull: false)  String? turnId, @JsonKey(includeIfNull: false)  int? turnRevision,  String? responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson)  ToolCallResultStatus? resultStatus)?  $default,) {final _that = this;
switch (_that) {
case _MessageToolCallEntity() when $default != null:
return $default(_that.id,_that.name,_that.argumentsRaw,_that.argumentsDigest,_that.turnId,_that.turnRevision,_that.responseRaw,_that.resultStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageToolCallEntity extends MessageToolCallEntity {
  const _MessageToolCallEntity({required this.id, required this.name, required this.argumentsRaw, @JsonKey(includeIfNull: false) this.argumentsDigest, @JsonKey(includeIfNull: false) this.turnId, @JsonKey(includeIfNull: false) this.turnRevision, this.responseRaw, @JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) this.resultStatus}): super._();
  factory _MessageToolCallEntity.fromJson(Map<String, dynamic> json) => _$MessageToolCallEntityFromJson(json);

@override final  String id;
@override final  String name;
@override final  String argumentsRaw;
@override@JsonKey(includeIfNull: false) final  String? argumentsDigest;
@override@JsonKey(includeIfNull: false) final  String? turnId;
@override@JsonKey(includeIfNull: false) final  int? turnRevision;
/// The raw response from tool execution, if successful.
@override final  String? responseRaw;
/// The result status of this tool call.
///
/// Null means the tool is awaiting approval. A non-null value means the
/// tool is running or completed with this result status.
@override@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) final  ToolCallResultStatus? resultStatus;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageToolCallEntityCopyWith<_MessageToolCallEntity> get copyWith => __$MessageToolCallEntityCopyWithImpl<_MessageToolCallEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToolCallEntityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageToolCallEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw)&&(identical(other.argumentsDigest, argumentsDigest) || other.argumentsDigest == argumentsDigest)&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.turnRevision, turnRevision) || other.turnRevision == turnRevision)&&(identical(other.responseRaw, responseRaw) || other.responseRaw == responseRaw)&&(identical(other.resultStatus, resultStatus) || other.resultStatus == resultStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,argumentsRaw,argumentsDigest,turnId,turnRevision,responseRaw,resultStatus);
}



}

/// @nodoc
abstract mixin class _$MessageToolCallEntityCopyWith<$Res> implements $MessageToolCallEntityCopyWith<$Res> {
  factory _$MessageToolCallEntityCopyWith(_MessageToolCallEntity value, $Res Function(_MessageToolCallEntity) _then) = __$MessageToolCallEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String argumentsRaw,@JsonKey(includeIfNull: false) String? argumentsDigest,@JsonKey(includeIfNull: false) String? turnId,@JsonKey(includeIfNull: false) int? turnRevision, String? responseRaw,@JsonKey(fromJson: _toolCallResultStatusFromJson, toJson: _toolCallResultStatusToJson) ToolCallResultStatus? resultStatus
});




}
/// @nodoc
class __$MessageToolCallEntityCopyWithImpl<$Res>
    implements _$MessageToolCallEntityCopyWith<$Res> {
  __$MessageToolCallEntityCopyWithImpl(this._self, this._then);

  final _MessageToolCallEntity _self;
  final $Res Function(_MessageToolCallEntity) _then;

/// Create a copy of MessageToolCallEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? argumentsRaw = null,Object? argumentsDigest = freezed,Object? turnId = freezed,Object? turnRevision = freezed,Object? responseRaw = freezed,Object? resultStatus = freezed,}) {
  return _then(_MessageToolCallEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,argumentsDigest: freezed == argumentsDigest ? _self.argumentsDigest : argumentsDigest // ignore: cast_nullable_to_non_nullable
as String?,turnId: freezed == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String?,turnRevision: freezed == turnRevision ? _self.turnRevision : turnRevision // ignore: cast_nullable_to_non_nullable
as int?,responseRaw: freezed == responseRaw ? _self.responseRaw : responseRaw // ignore: cast_nullable_to_non_nullable
as String?,resultStatus: freezed == resultStatus ? _self.resultStatus : resultStatus // ignore: cast_nullable_to_non_nullable
as ToolCallResultStatus?,
  ));
}


}

/// @nodoc
mixin _$MessageAttachmentEntity {

 String get id; String get messageId; String get localPath; String get fileName; String get displayName; String get mimeType; MessageAttachmentModality get modality; int get sizeBytes; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of MessageAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentEntityCopyWith<MessageAttachmentEntity> get copyWith => _$MessageAttachmentEntityCopyWithImpl<MessageAttachmentEntity>(this as MessageAttachmentEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessageAttachmentEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachmentEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.messageId, _this.messageId) || other.messageId == _this.messageId)&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.modality, _this.modality) || other.modality == _this.modality)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as MessageAttachmentEntity;
  return Object.hash(runtimeType,_this.id,_this.messageId,_this.localPath,_this.fileName,_this.displayName,_this.mimeType,_this.modality,_this.sizeBytes,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as MessageAttachmentEntity;
  return 'MessageAttachmentEntity(id: ${_this.id}, messageId: ${_this.messageId}, localPath: ${_this.localPath}, fileName: ${_this.fileName}, displayName: ${_this.displayName}, mimeType: ${_this.mimeType}, modality: ${_this.modality}, sizeBytes: ${_this.sizeBytes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentEntityCopyWith<$Res>  {
  factory $MessageAttachmentEntityCopyWith(MessageAttachmentEntity value, $Res Function(MessageAttachmentEntity) _then) = _$MessageAttachmentEntityCopyWithImpl;
@useResult
$Res call({
 String id, String messageId, String localPath, String fileName, String displayName, String mimeType, MessageAttachmentModality modality, int sizeBytes, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$MessageAttachmentEntityCopyWithImpl<$Res>
    implements $MessageAttachmentEntityCopyWith<$Res> {
  _$MessageAttachmentEntityCopyWithImpl(this._self, this._then);

  final MessageAttachmentEntity _self;
  final $Res Function(MessageAttachmentEntity) _then;

/// Create a copy of MessageAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? messageId = null,Object? localPath = null,Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? sizeBytes = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(MessageAttachmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachmentEntity].
extension MessageAttachmentEntityPatterns on MessageAttachmentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachmentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachmentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachmentEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachmentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String messageId,  String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachmentEntity() when $default != null:
return $default(_that.id,_that.messageId,_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String messageId,  String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentEntity():
return $default(_that.id,_that.messageId,_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String messageId,  String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentEntity() when $default != null:
return $default(_that.id,_that.messageId,_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MessageAttachmentEntity implements MessageAttachmentEntity {
  const _MessageAttachmentEntity({required this.id, required this.messageId, required this.localPath, required this.fileName, required this.displayName, required this.mimeType, required this.modality, required this.sizeBytes, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String messageId;
@override final  String localPath;
@override final  String fileName;
@override final  String displayName;
@override final  String mimeType;
@override final  MessageAttachmentModality modality;
@override final  int sizeBytes;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of MessageAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentEntityCopyWith<_MessageAttachmentEntity> get copyWith => __$MessageAttachmentEntityCopyWithImpl<_MessageAttachmentEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachmentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.modality, modality) || other.modality == modality)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,messageId,localPath,fileName,displayName,mimeType,modality,sizeBytes,createdAt,updatedAt);
}

@override
String toString() {
    return 'MessageAttachmentEntity(id: $id, messageId: $messageId, localPath: $localPath, fileName: $fileName, displayName: $displayName, mimeType: $mimeType, modality: $modality, sizeBytes: $sizeBytes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentEntityCopyWith<$Res> implements $MessageAttachmentEntityCopyWith<$Res> {
  factory _$MessageAttachmentEntityCopyWith(_MessageAttachmentEntity value, $Res Function(_MessageAttachmentEntity) _then) = __$MessageAttachmentEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String messageId, String localPath, String fileName, String displayName, String mimeType, MessageAttachmentModality modality, int sizeBytes, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$MessageAttachmentEntityCopyWithImpl<$Res>
    implements _$MessageAttachmentEntityCopyWith<$Res> {
  __$MessageAttachmentEntityCopyWithImpl(this._self, this._then);

  final _MessageAttachmentEntity _self;
  final $Res Function(_MessageAttachmentEntity) _then;

/// Create a copy of MessageAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? messageId = null,Object? localPath = null,Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? sizeBytes = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MessageAttachmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$MessageAttachmentToCreate {

 String get localPath; String get fileName; String get displayName; String get mimeType; MessageAttachmentModality get modality; int get sizeBytes;
/// Create a copy of MessageAttachmentToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentToCreateCopyWith<MessageAttachmentToCreate> get copyWith => _$MessageAttachmentToCreateCopyWithImpl<MessageAttachmentToCreate>(this as MessageAttachmentToCreate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessageAttachmentToCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachmentToCreate&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.modality, _this.modality) || other.modality == _this.modality)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes));
}


@override
int get hashCode {
  final _this = this as MessageAttachmentToCreate;
  return Object.hash(runtimeType,_this.localPath,_this.fileName,_this.displayName,_this.mimeType,_this.modality,_this.sizeBytes);
}

@override
String toString() {
  final _this = this as MessageAttachmentToCreate;
  return 'MessageAttachmentToCreate(localPath: ${_this.localPath}, fileName: ${_this.fileName}, displayName: ${_this.displayName}, mimeType: ${_this.mimeType}, modality: ${_this.modality}, sizeBytes: ${_this.sizeBytes})';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentToCreateCopyWith<$Res>  {
  factory $MessageAttachmentToCreateCopyWith(MessageAttachmentToCreate value, $Res Function(MessageAttachmentToCreate) _then) = _$MessageAttachmentToCreateCopyWithImpl;
@useResult
$Res call({
 String localPath, String fileName, String displayName, String mimeType, MessageAttachmentModality modality, int sizeBytes
});




}
/// @nodoc
class _$MessageAttachmentToCreateCopyWithImpl<$Res>
    implements $MessageAttachmentToCreateCopyWith<$Res> {
  _$MessageAttachmentToCreateCopyWithImpl(this._self, this._then);

  final MessageAttachmentToCreate _self;
  final $Res Function(MessageAttachmentToCreate) _then;

/// Create a copy of MessageAttachmentToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localPath = null,Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? sizeBytes = null,}) {
  return _then(MessageAttachmentToCreate(
localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachmentToCreate].
extension MessageAttachmentToCreatePatterns on MessageAttachmentToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachmentToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachmentToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachmentToCreate value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachmentToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachmentToCreate() when $default != null:
return $default(_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentToCreate():
return $default(_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localPath,  String fileName,  String displayName,  String mimeType,  MessageAttachmentModality modality,  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentToCreate() when $default != null:
return $default(_that.localPath,_that.fileName,_that.displayName,_that.mimeType,_that.modality,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc


class _MessageAttachmentToCreate implements MessageAttachmentToCreate {
  const _MessageAttachmentToCreate({required this.localPath, required this.fileName, required this.displayName, required this.mimeType, required this.modality, required this.sizeBytes});
  

@override final  String localPath;
@override final  String fileName;
@override final  String displayName;
@override final  String mimeType;
@override final  MessageAttachmentModality modality;
@override final  int sizeBytes;

/// Create a copy of MessageAttachmentToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentToCreateCopyWith<_MessageAttachmentToCreate> get copyWith => __$MessageAttachmentToCreateCopyWithImpl<_MessageAttachmentToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachmentToCreate&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.modality, modality) || other.modality == modality)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,localPath,fileName,displayName,mimeType,modality,sizeBytes);
}

@override
String toString() {
    return 'MessageAttachmentToCreate(localPath: $localPath, fileName: $fileName, displayName: $displayName, mimeType: $mimeType, modality: $modality, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentToCreateCopyWith<$Res> implements $MessageAttachmentToCreateCopyWith<$Res> {
  factory _$MessageAttachmentToCreateCopyWith(_MessageAttachmentToCreate value, $Res Function(_MessageAttachmentToCreate) _then) = __$MessageAttachmentToCreateCopyWithImpl;
@override @useResult
$Res call({
 String localPath, String fileName, String displayName, String mimeType, MessageAttachmentModality modality, int sizeBytes
});




}
/// @nodoc
class __$MessageAttachmentToCreateCopyWithImpl<$Res>
    implements _$MessageAttachmentToCreateCopyWith<$Res> {
  __$MessageAttachmentToCreateCopyWithImpl(this._self, this._then);

  final _MessageAttachmentToCreate _self;
  final $Res Function(_MessageAttachmentToCreate) _then;

/// Create a copy of MessageAttachmentToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localPath = null,Object? fileName = null,Object? displayName = null,Object? mimeType = null,Object? modality = null,Object? sizeBytes = null,}) {
  return _then(_MessageAttachmentToCreate(
localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,modality: null == modality ? _self.modality : modality // ignore: cast_nullable_to_non_nullable
as MessageAttachmentModality,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MessageMetadataEntity {

 List<MessageToolCallEntity> get toolCalls; int? get promptTokens; int? get completionTokens; int? get totalTokens; String? get thinking; Map<String, Object?> get modelMetadata; int get metadataVersion; bool get isCompactionSummary; CompactionKind? get compactionKind; String? get compactedFromMessageId; String? get compactedThroughMessageId; List<String> get compactedMessageIds; DateTime? get compactionCreatedAt;
/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageMetadataEntityCopyWith<MessageMetadataEntity> get copyWith => _$MessageMetadataEntityCopyWithImpl<MessageMetadataEntity>(this as MessageMetadataEntity, _$identity);

  /// Serializes this MessageMetadataEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MessageMetadataEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageMetadataEntity&&const DeepCollectionEquality().equals(other.toolCalls, _this.toolCalls)&&(identical(other.promptTokens, _this.promptTokens) || other.promptTokens == _this.promptTokens)&&(identical(other.completionTokens, _this.completionTokens) || other.completionTokens == _this.completionTokens)&&(identical(other.totalTokens, _this.totalTokens) || other.totalTokens == _this.totalTokens)&&(identical(other.thinking, _this.thinking) || other.thinking == _this.thinking)&&const DeepCollectionEquality().equals(other.modelMetadata, _this.modelMetadata)&&(identical(other.metadataVersion, _this.metadataVersion) || other.metadataVersion == _this.metadataVersion)&&(identical(other.isCompactionSummary, _this.isCompactionSummary) || other.isCompactionSummary == _this.isCompactionSummary)&&(identical(other.compactionKind, _this.compactionKind) || other.compactionKind == _this.compactionKind)&&(identical(other.compactedFromMessageId, _this.compactedFromMessageId) || other.compactedFromMessageId == _this.compactedFromMessageId)&&(identical(other.compactedThroughMessageId, _this.compactedThroughMessageId) || other.compactedThroughMessageId == _this.compactedThroughMessageId)&&const DeepCollectionEquality().equals(other.compactedMessageIds, _this.compactedMessageIds)&&(identical(other.compactionCreatedAt, _this.compactionCreatedAt) || other.compactionCreatedAt == _this.compactionCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MessageMetadataEntity;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.toolCalls),_this.promptTokens,_this.completionTokens,_this.totalTokens,_this.thinking,const DeepCollectionEquality().hash(_this.modelMetadata),_this.metadataVersion,_this.isCompactionSummary,_this.compactionKind,_this.compactedFromMessageId,_this.compactedThroughMessageId,const DeepCollectionEquality().hash(_this.compactedMessageIds),_this.compactionCreatedAt);
}

@override
String toString() {
  final _this = this as MessageMetadataEntity;
  return 'MessageMetadataEntity(toolCalls: ${_this.toolCalls}, promptTokens: ${_this.promptTokens}, completionTokens: ${_this.completionTokens}, totalTokens: ${_this.totalTokens}, thinking: ${_this.thinking}, modelMetadata: ${_this.modelMetadata}, metadataVersion: ${_this.metadataVersion}, isCompactionSummary: ${_this.isCompactionSummary}, compactionKind: ${_this.compactionKind}, compactedFromMessageId: ${_this.compactedFromMessageId}, compactedThroughMessageId: ${_this.compactedThroughMessageId}, compactedMessageIds: ${_this.compactedMessageIds}, compactionCreatedAt: ${_this.compactionCreatedAt})';
}


}

/// @nodoc
abstract mixin class $MessageMetadataEntityCopyWith<$Res>  {
  factory $MessageMetadataEntityCopyWith(MessageMetadataEntity value, $Res Function(MessageMetadataEntity) _then) = _$MessageMetadataEntityCopyWithImpl;
@useResult
$Res call({
 List<MessageToolCallEntity> toolCalls, int? promptTokens, int? completionTokens, int? totalTokens, String? thinking, Map<String, Object?> modelMetadata, int metadataVersion, bool isCompactionSummary, CompactionKind? compactionKind, String? compactedFromMessageId, String? compactedThroughMessageId, List<String> compactedMessageIds, DateTime? compactionCreatedAt
});




}
/// @nodoc
class _$MessageMetadataEntityCopyWithImpl<$Res>
    implements $MessageMetadataEntityCopyWith<$Res> {
  _$MessageMetadataEntityCopyWithImpl(this._self, this._then);

  final MessageMetadataEntity _self;
  final $Res Function(MessageMetadataEntity) _then;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolCalls = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? thinking = freezed,Object? modelMetadata = null,Object? metadataVersion = null,Object? isCompactionSummary = null,Object? compactionKind = freezed,Object? compactedFromMessageId = freezed,Object? compactedThroughMessageId = freezed,Object? compactedMessageIds = null,Object? compactionCreatedAt = freezed,}) {
  return _then(MessageMetadataEntity(
toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<MessageToolCallEntity>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,modelMetadata: null == modelMetadata ? _self.modelMetadata : modelMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,metadataVersion: null == metadataVersion ? _self.metadataVersion : metadataVersion // ignore: cast_nullable_to_non_nullable
as int,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageId: freezed == compactedFromMessageId ? _self.compactedFromMessageId : compactedFromMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedThroughMessageId: freezed == compactedThroughMessageId ? _self.compactedThroughMessageId : compactedThroughMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedMessageIds: null == compactedMessageIds ? _self.compactedMessageIds : compactedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageMetadataEntity].
extension MessageMetadataEntityPatterns on MessageMetadataEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageMetadataEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageMetadataEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageMetadataEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageMetadataEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageMetadataEntity():
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MessageToolCallEntity> toolCalls,  int? promptTokens,  int? completionTokens,  int? totalTokens,  String? thinking,  Map<String, Object?> modelMetadata,  int metadataVersion,  bool isCompactionSummary,  CompactionKind? compactionKind,  String? compactedFromMessageId,  String? compactedThroughMessageId,  List<String> compactedMessageIds,  DateTime? compactionCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageMetadataEntity() when $default != null:
return $default(_that.toolCalls,_that.promptTokens,_that.completionTokens,_that.totalTokens,_that.thinking,_that.modelMetadata,_that.metadataVersion,_that.isCompactionSummary,_that.compactionKind,_that.compactedFromMessageId,_that.compactedThroughMessageId,_that.compactedMessageIds,_that.compactionCreatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageMetadataEntity extends MessageMetadataEntity {
  const _MessageMetadataEntity({ List<MessageToolCallEntity> toolCalls = const <MessageToolCallEntity>[], this.promptTokens, this.completionTokens, this.totalTokens, this.thinking,  Map<String, Object?> modelMetadata = const <String, Object?>{}, this.metadataVersion = 1, this.isCompactionSummary = false, this.compactionKind, this.compactedFromMessageId, this.compactedThroughMessageId,  List<String> compactedMessageIds = const <String>[], this.compactionCreatedAt}): _toolCalls = toolCalls,_modelMetadata = modelMetadata,_compactedMessageIds = compactedMessageIds,super._();
  factory _MessageMetadataEntity.fromJson(Map<String, dynamic> json) => _$MessageMetadataEntityFromJson(json);

 final  List<MessageToolCallEntity> _toolCalls;
@override@JsonKey() List<MessageToolCallEntity> get toolCalls {
  if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toolCalls);
}

@override final  int? promptTokens;
@override final  int? completionTokens;
@override final  int? totalTokens;
@override final  String? thinking;
 final  Map<String, Object?> _modelMetadata;
@override@JsonKey() Map<String, Object?> get modelMetadata {
  if (_modelMetadata is EqualUnmodifiableMapView) return _modelMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_modelMetadata);
}

@override@JsonKey() final  int metadataVersion;
@override@JsonKey() final  bool isCompactionSummary;
@override final  CompactionKind? compactionKind;
@override final  String? compactedFromMessageId;
@override final  String? compactedThroughMessageId;
 final  List<String> _compactedMessageIds;
@override@JsonKey() List<String> get compactedMessageIds {
  if (_compactedMessageIds is EqualUnmodifiableListView) return _compactedMessageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compactedMessageIds);
}

@override final  DateTime? compactionCreatedAt;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageMetadataEntityCopyWith<_MessageMetadataEntity> get copyWith => __$MessageMetadataEntityCopyWithImpl<_MessageMetadataEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageMetadataEntityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageMetadataEntity&&const DeepCollectionEquality().equals(other.toolCalls, _toolCalls)&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&const DeepCollectionEquality().equals(other.modelMetadata, _modelMetadata)&&(identical(other.metadataVersion, metadataVersion) || other.metadataVersion == metadataVersion)&&(identical(other.isCompactionSummary, isCompactionSummary) || other.isCompactionSummary == isCompactionSummary)&&(identical(other.compactionKind, compactionKind) || other.compactionKind == compactionKind)&&(identical(other.compactedFromMessageId, compactedFromMessageId) || other.compactedFromMessageId == compactedFromMessageId)&&(identical(other.compactedThroughMessageId, compactedThroughMessageId) || other.compactedThroughMessageId == compactedThroughMessageId)&&const DeepCollectionEquality().equals(other.compactedMessageIds, _compactedMessageIds)&&(identical(other.compactionCreatedAt, compactionCreatedAt) || other.compactionCreatedAt == compactionCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_toolCalls),promptTokens,completionTokens,totalTokens,thinking,const DeepCollectionEquality().hash(_modelMetadata),metadataVersion,isCompactionSummary,compactionKind,compactedFromMessageId,compactedThroughMessageId,const DeepCollectionEquality().hash(_compactedMessageIds),compactionCreatedAt);
}

@override
String toString() {
    return 'MessageMetadataEntity(toolCalls: $toolCalls, promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens, thinking: $thinking, modelMetadata: $modelMetadata, metadataVersion: $metadataVersion, isCompactionSummary: $isCompactionSummary, compactionKind: $compactionKind, compactedFromMessageId: $compactedFromMessageId, compactedThroughMessageId: $compactedThroughMessageId, compactedMessageIds: $compactedMessageIds, compactionCreatedAt: $compactionCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageMetadataEntityCopyWith<$Res> implements $MessageMetadataEntityCopyWith<$Res> {
  factory _$MessageMetadataEntityCopyWith(_MessageMetadataEntity value, $Res Function(_MessageMetadataEntity) _then) = __$MessageMetadataEntityCopyWithImpl;
@override @useResult
$Res call({
 List<MessageToolCallEntity> toolCalls, int? promptTokens, int? completionTokens, int? totalTokens, String? thinking, Map<String, Object?> modelMetadata, int metadataVersion, bool isCompactionSummary, CompactionKind? compactionKind, String? compactedFromMessageId, String? compactedThroughMessageId, List<String> compactedMessageIds, DateTime? compactionCreatedAt
});




}
/// @nodoc
class __$MessageMetadataEntityCopyWithImpl<$Res>
    implements _$MessageMetadataEntityCopyWith<$Res> {
  __$MessageMetadataEntityCopyWithImpl(this._self, this._then);

  final _MessageMetadataEntity _self;
  final $Res Function(_MessageMetadataEntity) _then;

/// Create a copy of MessageMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolCalls = null,Object? promptTokens = freezed,Object? completionTokens = freezed,Object? totalTokens = freezed,Object? thinking = freezed,Object? modelMetadata = null,Object? metadataVersion = null,Object? isCompactionSummary = null,Object? compactionKind = freezed,Object? compactedFromMessageId = freezed,Object? compactedThroughMessageId = freezed,Object? compactedMessageIds = null,Object? compactionCreatedAt = freezed,}) {
  return _then(_MessageMetadataEntity(
toolCalls: null == toolCalls ? _self._toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<MessageToolCallEntity>,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,thinking: freezed == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String?,modelMetadata: null == modelMetadata ? _self._modelMetadata : modelMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,metadataVersion: null == metadataVersion ? _self.metadataVersion : metadataVersion // ignore: cast_nullable_to_non_nullable
as int,isCompactionSummary: null == isCompactionSummary ? _self.isCompactionSummary : isCompactionSummary // ignore: cast_nullable_to_non_nullable
as bool,compactionKind: freezed == compactionKind ? _self.compactionKind : compactionKind // ignore: cast_nullable_to_non_nullable
as CompactionKind?,compactedFromMessageId: freezed == compactedFromMessageId ? _self.compactedFromMessageId : compactedFromMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedThroughMessageId: freezed == compactedThroughMessageId ? _self.compactedThroughMessageId : compactedThroughMessageId // ignore: cast_nullable_to_non_nullable
as String?,compactedMessageIds: null == compactedMessageIds ? _self._compactedMessageIds : compactedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,compactionCreatedAt: freezed == compactionCreatedAt ? _self.compactionCreatedAt : compactionCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MessageEntity {

/// Unique identifier for the message.
 String get id;/// ID of the conversation this message belongs to.
 String get conversationId;/// Content of the message (JSON structure based on message type).
 String get content;/// Type of the message.
 MessageType get messageType;/// Whether this message was sent by the user.
 bool get isUser;/// Status of the message.
 MessageStatus get status;/// Timestamp when the message was created.
 DateTime get createdAt;/// Timestamp when the message was last updated.
 DateTime get updatedAt;/// Additional metadata for the message (JSON).
 MessageMetadataEntity? get metadata; List<MessageAttachmentEntity> get attachments;
/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageEntityCopyWith<MessageEntity> get copyWith => _$MessageEntityCopyWithImpl<MessageEntity>(this as MessageEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessageEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.conversationId, _this.conversationId) || other.conversationId == _this.conversationId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.messageType, _this.messageType) || other.messageType == _this.messageType)&&(identical(other.isUser, _this.isUser) || other.isUser == _this.isUser)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments));
}


@override
int get hashCode {
  final _this = this as MessageEntity;
  return Object.hash(runtimeType,_this.id,_this.conversationId,_this.content,_this.messageType,_this.isUser,_this.status,_this.createdAt,_this.updatedAt,_this.metadata,const DeepCollectionEquality().hash(_this.attachments));
}

@override
String toString() {
  final _this = this as MessageEntity;
  return 'MessageEntity(id: ${_this.id}, conversationId: ${_this.conversationId}, content: ${_this.content}, messageType: ${_this.messageType}, isUser: ${_this.isUser}, status: ${_this.status}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, metadata: ${_this.metadata}, attachments: ${_this.attachments})';
}


}

/// @nodoc
abstract mixin class $MessageEntityCopyWith<$Res>  {
  factory $MessageEntityCopyWith(MessageEntity value, $Res Function(MessageEntity) _then) = _$MessageEntityCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, DateTime updatedAt, MessageMetadataEntity? metadata, List<MessageAttachmentEntity> attachments
});


$MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$MessageEntityCopyWithImpl<$Res>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._self, this._then);

  final MessageEntity _self;
  final $Res Function(MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? metadata = freezed,Object? attachments = null,}) {
  return _then(MessageEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentEntity>,
  ));
}
/// Create a copy of MessageEntity
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


/// Adds pattern-matching-related methods to [MessageEntity].
extension MessageEntityPatterns on MessageEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata,  List<MessageAttachmentEntity> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata,  List<MessageAttachmentEntity> attachments)  $default,) {final _that = this;
switch (_that) {
case _MessageEntity():
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  DateTime createdAt,  DateTime updatedAt,  MessageMetadataEntity? metadata,  List<MessageAttachmentEntity> attachments)?  $default,) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.createdAt,_that.updatedAt,_that.metadata,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc


class _MessageEntity extends MessageEntity {
  const _MessageEntity({required this.id, required this.conversationId, required this.content, required this.messageType, required this.isUser, required this.status, required this.createdAt, required this.updatedAt, this.metadata,  List<MessageAttachmentEntity> attachments = const <MessageAttachmentEntity>[]}): _attachments = attachments,super._();
  

/// Unique identifier for the message.
@override final  String id;
/// ID of the conversation this message belongs to.
@override final  String conversationId;
/// Content of the message (JSON structure based on message type).
@override final  String content;
/// Type of the message.
@override final  MessageType messageType;
/// Whether this message was sent by the user.
@override final  bool isUser;
/// Status of the message.
@override final  MessageStatus status;
/// Timestamp when the message was created.
@override final  DateTime createdAt;
/// Timestamp when the message was last updated.
@override final  DateTime updatedAt;
/// Additional metadata for the message (JSON).
@override final  MessageMetadataEntity? metadata;
 final  List<MessageAttachmentEntity> _attachments;
@override@JsonKey() List<MessageAttachmentEntity> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageEntityCopyWith<_MessageEntity> get copyWith => __$MessageEntityCopyWithImpl<_MessageEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.attachments, _attachments));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,conversationId,content,messageType,isUser,status,createdAt,updatedAt,metadata,const DeepCollectionEquality().hash(_attachments));
}

@override
String toString() {
    return 'MessageEntity(id: $id, conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, metadata: $metadata, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$MessageEntityCopyWith<$Res> implements $MessageEntityCopyWith<$Res> {
  factory _$MessageEntityCopyWith(_MessageEntity value, $Res Function(_MessageEntity) _then) = __$MessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, DateTime createdAt, DateTime updatedAt, MessageMetadataEntity? metadata, List<MessageAttachmentEntity> attachments
});


@override $MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$MessageEntityCopyWithImpl<$Res>
    implements _$MessageEntityCopyWith<$Res> {
  __$MessageEntityCopyWithImpl(this._self, this._then);

  final _MessageEntity _self;
  final $Res Function(_MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? metadata = freezed,Object? attachments = null,}) {
  return _then(_MessageEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentEntity>,
  ));
}

/// Create a copy of MessageEntity
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

/// @nodoc
mixin _$MessageToCreate {

/// ID of the conversation this message belongs to.
 String get conversationId;/// Content of the message (JSON structure based on message type).
 String get content;/// Type of the message.
 MessageType get messageType;/// Whether this message was sent by the user.
 bool get isUser; MessageStatus get status;/// Additional metadata for the message (JSON).
 String? get metadata; List<MessageAttachmentToCreate> get attachments;
/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageToCreateCopyWith<MessageToCreate> get copyWith => _$MessageToCreateCopyWithImpl<MessageToCreate>(this as MessageToCreate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessageToCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageToCreate&&(identical(other.conversationId, _this.conversationId) || other.conversationId == _this.conversationId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.messageType, _this.messageType) || other.messageType == _this.messageType)&&(identical(other.isUser, _this.isUser) || other.isUser == _this.isUser)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments));
}


@override
int get hashCode {
  final _this = this as MessageToCreate;
  return Object.hash(runtimeType,_this.conversationId,_this.content,_this.messageType,_this.isUser,_this.status,_this.metadata,const DeepCollectionEquality().hash(_this.attachments));
}

@override
String toString() {
  final _this = this as MessageToCreate;
  return 'MessageToCreate(conversationId: ${_this.conversationId}, content: ${_this.content}, messageType: ${_this.messageType}, isUser: ${_this.isUser}, status: ${_this.status}, metadata: ${_this.metadata}, attachments: ${_this.attachments})';
}


}

/// @nodoc
abstract mixin class $MessageToCreateCopyWith<$Res>  {
  factory $MessageToCreateCopyWith(MessageToCreate value, $Res Function(MessageToCreate) _then) = _$MessageToCreateCopyWithImpl;
@useResult
$Res call({
 String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, String? metadata, List<MessageAttachmentToCreate> attachments
});




}
/// @nodoc
class _$MessageToCreateCopyWithImpl<$Res>
    implements $MessageToCreateCopyWith<$Res> {
  _$MessageToCreateCopyWithImpl(this._self, this._then);

  final MessageToCreate _self;
  final $Res Function(MessageToCreate) _then;

/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? metadata = freezed,Object? attachments = null,}) {
  return _then(MessageToCreate(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as String?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentToCreate>,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageToCreate].
extension MessageToCreatePatterns on MessageToCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageToCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageToCreate value)  $default,){
final _that = this;
switch (_that) {
case _MessageToCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageToCreate value)?  $default,){
final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata,  List<MessageAttachmentToCreate> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata,  List<MessageAttachmentToCreate> attachments)  $default,) {final _that = this;
switch (_that) {
case _MessageToCreate():
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String content,  MessageType messageType,  bool isUser,  MessageStatus status,  String? metadata,  List<MessageAttachmentToCreate> attachments)?  $default,) {final _that = this;
switch (_that) {
case _MessageToCreate() when $default != null:
return $default(_that.conversationId,_that.content,_that.messageType,_that.isUser,_that.status,_that.metadata,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc


class _MessageToCreate extends MessageToCreate {
  const _MessageToCreate({required this.conversationId, required this.content, required this.messageType, required this.isUser, required this.status, this.metadata,  List<MessageAttachmentToCreate> attachments = const <MessageAttachmentToCreate>[]}): _attachments = attachments,super._();
  

/// ID of the conversation this message belongs to.
@override final  String conversationId;
/// Content of the message (JSON structure based on message type).
@override final  String content;
/// Type of the message.
@override final  MessageType messageType;
/// Whether this message was sent by the user.
@override final  bool isUser;
@override final  MessageStatus status;
/// Additional metadata for the message (JSON).
@override final  String? metadata;
 final  List<MessageAttachmentToCreate> _attachments;
@override@JsonKey() List<MessageAttachmentToCreate> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageToCreateCopyWith<_MessageToCreate> get copyWith => __$MessageToCreateCopyWithImpl<_MessageToCreate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageToCreate&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.isUser, isUser) || other.isUser == isUser)&&(identical(other.status, status) || other.status == status)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.attachments, _attachments));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversationId,content,messageType,isUser,status,metadata,const DeepCollectionEquality().hash(_attachments));
}

@override
String toString() {
    return 'MessageToCreate(conversationId: $conversationId, content: $content, messageType: $messageType, isUser: $isUser, status: $status, metadata: $metadata, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$MessageToCreateCopyWith<$Res> implements $MessageToCreateCopyWith<$Res> {
  factory _$MessageToCreateCopyWith(_MessageToCreate value, $Res Function(_MessageToCreate) _then) = __$MessageToCreateCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String content, MessageType messageType, bool isUser, MessageStatus status, String? metadata, List<MessageAttachmentToCreate> attachments
});




}
/// @nodoc
class __$MessageToCreateCopyWithImpl<$Res>
    implements _$MessageToCreateCopyWith<$Res> {
  __$MessageToCreateCopyWithImpl(this._self, this._then);

  final _MessageToCreate _self;
  final $Res Function(_MessageToCreate) _then;

/// Create a copy of MessageToCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? content = null,Object? messageType = null,Object? isUser = null,Object? status = null,Object? metadata = freezed,Object? attachments = null,}) {
  return _then(_MessageToCreate(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,isUser: null == isUser ? _self.isUser : isUser // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as String?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentToCreate>,
  ));
}


}

/// @nodoc
mixin _$MessagePatch {

/// Content of the message (JSON structure based on message type).
 String? get content;/// Additional metadata for the message (JSON).
 MessageMetadataEntity? get metadata; MessageStatus? get status;
/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagePatchCopyWith<MessagePatch> get copyWith => _$MessagePatchCopyWithImpl<MessagePatch>(this as MessagePatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessagePatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagePatch&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.status, _this.status) || other.status == _this.status));
}


@override
int get hashCode {
  final _this = this as MessagePatch;
  return Object.hash(runtimeType,_this.content,_this.metadata,_this.status);
}

@override
String toString() {
  final _this = this as MessagePatch;
  return 'MessagePatch(content: ${_this.content}, metadata: ${_this.metadata}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $MessagePatchCopyWith<$Res>  {
  factory $MessagePatchCopyWith(MessagePatch value, $Res Function(MessagePatch) _then) = _$MessagePatchCopyWithImpl;
@useResult
$Res call({
 String? content, MessageMetadataEntity? metadata, MessageStatus? status
});


$MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$MessagePatchCopyWithImpl<$Res>
    implements $MessagePatchCopyWith<$Res> {
  _$MessagePatchCopyWithImpl(this._self, this._then);

  final MessagePatch _self;
  final $Res Function(MessagePatch) _then;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = freezed,Object? metadata = freezed,Object? status = freezed,}) {
  return _then(MessagePatch(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus?,
  ));
}
/// Create a copy of MessagePatch
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


/// Adds pattern-matching-related methods to [MessagePatch].
extension MessagePatchPatterns on MessagePatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessagePatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessagePatch value)  $default,){
final _that = this;
switch (_that) {
case _MessagePatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessagePatch value)?  $default,){
final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that.content,_that.metadata,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)  $default,) {final _that = this;
switch (_that) {
case _MessagePatch():
return $default(_that.content,_that.metadata,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? content,  MessageMetadataEntity? metadata,  MessageStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _MessagePatch() when $default != null:
return $default(_that.content,_that.metadata,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _MessagePatch extends MessagePatch {
  const _MessagePatch({this.content, this.metadata, this.status}): super._();
  

/// Content of the message (JSON structure based on message type).
@override final  String? content;
/// Additional metadata for the message (JSON).
@override final  MessageMetadataEntity? metadata;
@override final  MessageStatus? status;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagePatchCopyWith<_MessagePatch> get copyWith => __$MessagePatchCopyWithImpl<_MessagePatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagePatch&&(identical(other.content, content) || other.content == content)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode {
    return Object.hash(runtimeType,content,metadata,status);
}

@override
String toString() {
    return 'MessagePatch(content: $content, metadata: $metadata, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MessagePatchCopyWith<$Res> implements $MessagePatchCopyWith<$Res> {
  factory _$MessagePatchCopyWith(_MessagePatch value, $Res Function(_MessagePatch) _then) = __$MessagePatchCopyWithImpl;
@override @useResult
$Res call({
 String? content, MessageMetadataEntity? metadata, MessageStatus? status
});


@override $MessageMetadataEntityCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$MessagePatchCopyWithImpl<$Res>
    implements _$MessagePatchCopyWith<$Res> {
  __$MessagePatchCopyWithImpl(this._self, this._then);

  final _MessagePatch _self;
  final $Res Function(_MessagePatch) _then;

/// Create a copy of MessagePatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = freezed,Object? metadata = freezed,Object? status = freezed,}) {
  return _then(_MessagePatch(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MessageMetadataEntity?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus?,
  ));
}

/// Create a copy of MessagePatch
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

/// @nodoc
mixin _$ToolToCall {

 ResolvedTool get tool; String get id; String get argumentsRaw;
/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolToCallCopyWith<ToolToCall> get copyWith => _$ToolToCallCopyWithImpl<ToolToCall>(this as ToolToCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ToolToCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolToCall&&(identical(other.tool, _this.tool) || other.tool == _this.tool)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.argumentsRaw, _this.argumentsRaw) || other.argumentsRaw == _this.argumentsRaw));
}


@override
int get hashCode {
  final _this = this as ToolToCall;
  return Object.hash(runtimeType,_this.tool,_this.id,_this.argumentsRaw);
}



}

/// @nodoc
abstract mixin class $ToolToCallCopyWith<$Res>  {
  factory $ToolToCallCopyWith(ToolToCall value, $Res Function(ToolToCall) _then) = _$ToolToCallCopyWithImpl;
@useResult
$Res call({
 ResolvedTool tool, String id, String argumentsRaw
});




}
/// @nodoc
class _$ToolToCallCopyWithImpl<$Res>
    implements $ToolToCallCopyWith<$Res> {
  _$ToolToCallCopyWithImpl(this._self, this._then);

  final ToolToCall _self;
  final $Res Function(ToolToCall) _then;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? id = null,Object? argumentsRaw = null,}) {
  return _then(ToolToCall(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ResolvedTool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolToCall].
extension ToolToCallPatterns on ToolToCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolToCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolToCall value)  $default,){
final _that = this;
switch (_that) {
case _ToolToCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolToCall value)?  $default,){
final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTool tool,  String id,  String argumentsRaw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTool tool,  String id,  String argumentsRaw)  $default,) {final _that = this;
switch (_that) {
case _ToolToCall():
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTool tool,  String id,  String argumentsRaw)?  $default,) {final _that = this;
switch (_that) {
case _ToolToCall() when $default != null:
return $default(_that.tool,_that.id,_that.argumentsRaw);case _:
  return null;

}
}

}

/// @nodoc


class _ToolToCall extends ToolToCall {
  const _ToolToCall({required this.tool, required this.id, required this.argumentsRaw}): super._();
  

@override final  ResolvedTool tool;
@override final  String id;
@override final  String argumentsRaw;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolToCallCopyWith<_ToolToCall> get copyWith => __$ToolToCallCopyWithImpl<_ToolToCall>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolToCall&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.id, id) || other.id == id)&&(identical(other.argumentsRaw, argumentsRaw) || other.argumentsRaw == argumentsRaw));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tool,id,argumentsRaw);
}



}

/// @nodoc
abstract mixin class _$ToolToCallCopyWith<$Res> implements $ToolToCallCopyWith<$Res> {
  factory _$ToolToCallCopyWith(_ToolToCall value, $Res Function(_ToolToCall) _then) = __$ToolToCallCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTool tool, String id, String argumentsRaw
});




}
/// @nodoc
class __$ToolToCallCopyWithImpl<$Res>
    implements _$ToolToCallCopyWith<$Res> {
  __$ToolToCallCopyWithImpl(this._self, this._then);

  final _ToolToCall _self;
  final $Res Function(_ToolToCall) _then;

/// Create a copy of ToolToCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? id = null,Object? argumentsRaw = null,}) {
  return _then(_ToolToCall(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as ResolvedTool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,argumentsRaw: null == argumentsRaw ? _self.argumentsRaw : argumentsRaw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
