// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compaction_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompactionSettings {

 bool get autoCompactionEnabled; int get usagePercentageThreshold; int get remainingTokenThreshold; DateTime? get updatedAt;
/// Create a copy of CompactionSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompactionSettingsCopyWith<CompactionSettings> get copyWith => _$CompactionSettingsCopyWithImpl<CompactionSettings>(this as CompactionSettings, _$identity);

  /// Serializes this CompactionSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompactionSettings&&(identical(other.autoCompactionEnabled, autoCompactionEnabled) || other.autoCompactionEnabled == autoCompactionEnabled)&&(identical(other.usagePercentageThreshold, usagePercentageThreshold) || other.usagePercentageThreshold == usagePercentageThreshold)&&(identical(other.remainingTokenThreshold, remainingTokenThreshold) || other.remainingTokenThreshold == remainingTokenThreshold)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoCompactionEnabled,usagePercentageThreshold,remainingTokenThreshold,updatedAt);

@override
String toString() {
  return 'CompactionSettings(autoCompactionEnabled: $autoCompactionEnabled, usagePercentageThreshold: $usagePercentageThreshold, remainingTokenThreshold: $remainingTokenThreshold, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CompactionSettingsCopyWith<$Res>  {
  factory $CompactionSettingsCopyWith(CompactionSettings value, $Res Function(CompactionSettings) _then) = _$CompactionSettingsCopyWithImpl;
@useResult
$Res call({
 bool autoCompactionEnabled, int usagePercentageThreshold, int remainingTokenThreshold, DateTime? updatedAt
});




}
/// @nodoc
class _$CompactionSettingsCopyWithImpl<$Res>
    implements $CompactionSettingsCopyWith<$Res> {
  _$CompactionSettingsCopyWithImpl(this._self, this._then);

  final CompactionSettings _self;
  final $Res Function(CompactionSettings) _then;

/// Create a copy of CompactionSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? autoCompactionEnabled = null,Object? usagePercentageThreshold = null,Object? remainingTokenThreshold = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
autoCompactionEnabled: null == autoCompactionEnabled ? _self.autoCompactionEnabled : autoCompactionEnabled // ignore: cast_nullable_to_non_nullable
as bool,usagePercentageThreshold: null == usagePercentageThreshold ? _self.usagePercentageThreshold : usagePercentageThreshold // ignore: cast_nullable_to_non_nullable
as int,remainingTokenThreshold: null == remainingTokenThreshold ? _self.remainingTokenThreshold : remainingTokenThreshold // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompactionSettings].
extension CompactionSettingsPatterns on CompactionSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompactionSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompactionSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompactionSettings value)  $default,){
final _that = this;
switch (_that) {
case _CompactionSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompactionSettings value)?  $default,){
final _that = this;
switch (_that) {
case _CompactionSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool autoCompactionEnabled,  int usagePercentageThreshold,  int remainingTokenThreshold,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompactionSettings() when $default != null:
return $default(_that.autoCompactionEnabled,_that.usagePercentageThreshold,_that.remainingTokenThreshold,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool autoCompactionEnabled,  int usagePercentageThreshold,  int remainingTokenThreshold,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CompactionSettings():
return $default(_that.autoCompactionEnabled,_that.usagePercentageThreshold,_that.remainingTokenThreshold,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool autoCompactionEnabled,  int usagePercentageThreshold,  int remainingTokenThreshold,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CompactionSettings() when $default != null:
return $default(_that.autoCompactionEnabled,_that.usagePercentageThreshold,_that.remainingTokenThreshold,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompactionSettings extends CompactionSettings {
  const _CompactionSettings({this.autoCompactionEnabled = true, this.usagePercentageThreshold = 80, this.remainingTokenThreshold = 2000, this.updatedAt}): super._();
  factory _CompactionSettings.fromJson(Map<String, dynamic> json) => _$CompactionSettingsFromJson(json);

@override@JsonKey() final  bool autoCompactionEnabled;
@override@JsonKey() final  int usagePercentageThreshold;
@override@JsonKey() final  int remainingTokenThreshold;
@override final  DateTime? updatedAt;

/// Create a copy of CompactionSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompactionSettingsCopyWith<_CompactionSettings> get copyWith => __$CompactionSettingsCopyWithImpl<_CompactionSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompactionSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompactionSettings&&(identical(other.autoCompactionEnabled, autoCompactionEnabled) || other.autoCompactionEnabled == autoCompactionEnabled)&&(identical(other.usagePercentageThreshold, usagePercentageThreshold) || other.usagePercentageThreshold == usagePercentageThreshold)&&(identical(other.remainingTokenThreshold, remainingTokenThreshold) || other.remainingTokenThreshold == remainingTokenThreshold)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoCompactionEnabled,usagePercentageThreshold,remainingTokenThreshold,updatedAt);

@override
String toString() {
  return 'CompactionSettings(autoCompactionEnabled: $autoCompactionEnabled, usagePercentageThreshold: $usagePercentageThreshold, remainingTokenThreshold: $remainingTokenThreshold, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CompactionSettingsCopyWith<$Res> implements $CompactionSettingsCopyWith<$Res> {
  factory _$CompactionSettingsCopyWith(_CompactionSettings value, $Res Function(_CompactionSettings) _then) = __$CompactionSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool autoCompactionEnabled, int usagePercentageThreshold, int remainingTokenThreshold, DateTime? updatedAt
});




}
/// @nodoc
class __$CompactionSettingsCopyWithImpl<$Res>
    implements _$CompactionSettingsCopyWith<$Res> {
  __$CompactionSettingsCopyWithImpl(this._self, this._then);

  final _CompactionSettings _self;
  final $Res Function(_CompactionSettings) _then;

/// Create a copy of CompactionSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? autoCompactionEnabled = null,Object? usagePercentageThreshold = null,Object? remainingTokenThreshold = null,Object? updatedAt = freezed,}) {
  return _then(_CompactionSettings(
autoCompactionEnabled: null == autoCompactionEnabled ? _self.autoCompactionEnabled : autoCompactionEnabled // ignore: cast_nullable_to_non_nullable
as bool,usagePercentageThreshold: null == usagePercentageThreshold ? _self.usagePercentageThreshold : usagePercentageThreshold // ignore: cast_nullable_to_non_nullable
as int,remainingTokenThreshold: null == remainingTokenThreshold ? _self.remainingTokenThreshold : remainingTokenThreshold // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ConversationPromptEstimate {

 String get conversationId; String get selectedModelId; String get selectedProviderId; int get estimatedPromptTokens; int get maxOutputTokens; int? get contextLimit; int? get remainingTokens; double? get usagePercentage;
/// Create a copy of ConversationPromptEstimate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationPromptEstimateCopyWith<ConversationPromptEstimate> get copyWith => _$ConversationPromptEstimateCopyWithImpl<ConversationPromptEstimate>(this as ConversationPromptEstimate, _$identity);

  /// Serializes this ConversationPromptEstimate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationPromptEstimate&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.selectedModelId, selectedModelId) || other.selectedModelId == selectedModelId)&&(identical(other.selectedProviderId, selectedProviderId) || other.selectedProviderId == selectedProviderId)&&(identical(other.estimatedPromptTokens, estimatedPromptTokens) || other.estimatedPromptTokens == estimatedPromptTokens)&&(identical(other.maxOutputTokens, maxOutputTokens) || other.maxOutputTokens == maxOutputTokens)&&(identical(other.contextLimit, contextLimit) || other.contextLimit == contextLimit)&&(identical(other.remainingTokens, remainingTokens) || other.remainingTokens == remainingTokens)&&(identical(other.usagePercentage, usagePercentage) || other.usagePercentage == usagePercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,selectedModelId,selectedProviderId,estimatedPromptTokens,maxOutputTokens,contextLimit,remainingTokens,usagePercentage);

@override
String toString() {
  return 'ConversationPromptEstimate(conversationId: $conversationId, selectedModelId: $selectedModelId, selectedProviderId: $selectedProviderId, estimatedPromptTokens: $estimatedPromptTokens, maxOutputTokens: $maxOutputTokens, contextLimit: $contextLimit, remainingTokens: $remainingTokens, usagePercentage: $usagePercentage)';
}


}

/// @nodoc
abstract mixin class $ConversationPromptEstimateCopyWith<$Res>  {
  factory $ConversationPromptEstimateCopyWith(ConversationPromptEstimate value, $Res Function(ConversationPromptEstimate) _then) = _$ConversationPromptEstimateCopyWithImpl;
@useResult
$Res call({
 String conversationId, String selectedModelId, String selectedProviderId, int estimatedPromptTokens, int maxOutputTokens, int? contextLimit, int? remainingTokens, double? usagePercentage
});




}
/// @nodoc
class _$ConversationPromptEstimateCopyWithImpl<$Res>
    implements $ConversationPromptEstimateCopyWith<$Res> {
  _$ConversationPromptEstimateCopyWithImpl(this._self, this._then);

  final ConversationPromptEstimate _self;
  final $Res Function(ConversationPromptEstimate) _then;

/// Create a copy of ConversationPromptEstimate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? selectedModelId = null,Object? selectedProviderId = null,Object? estimatedPromptTokens = null,Object? maxOutputTokens = null,Object? contextLimit = freezed,Object? remainingTokens = freezed,Object? usagePercentage = freezed,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,selectedModelId: null == selectedModelId ? _self.selectedModelId : selectedModelId // ignore: cast_nullable_to_non_nullable
as String,selectedProviderId: null == selectedProviderId ? _self.selectedProviderId : selectedProviderId // ignore: cast_nullable_to_non_nullable
as String,estimatedPromptTokens: null == estimatedPromptTokens ? _self.estimatedPromptTokens : estimatedPromptTokens // ignore: cast_nullable_to_non_nullable
as int,maxOutputTokens: null == maxOutputTokens ? _self.maxOutputTokens : maxOutputTokens // ignore: cast_nullable_to_non_nullable
as int,contextLimit: freezed == contextLimit ? _self.contextLimit : contextLimit // ignore: cast_nullable_to_non_nullable
as int?,remainingTokens: freezed == remainingTokens ? _self.remainingTokens : remainingTokens // ignore: cast_nullable_to_non_nullable
as int?,usagePercentage: freezed == usagePercentage ? _self.usagePercentage : usagePercentage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationPromptEstimate].
extension ConversationPromptEstimatePatterns on ConversationPromptEstimate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationPromptEstimate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationPromptEstimate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationPromptEstimate value)  $default,){
final _that = this;
switch (_that) {
case _ConversationPromptEstimate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationPromptEstimate value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationPromptEstimate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String selectedModelId,  String selectedProviderId,  int estimatedPromptTokens,  int maxOutputTokens,  int? contextLimit,  int? remainingTokens,  double? usagePercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationPromptEstimate() when $default != null:
return $default(_that.conversationId,_that.selectedModelId,_that.selectedProviderId,_that.estimatedPromptTokens,_that.maxOutputTokens,_that.contextLimit,_that.remainingTokens,_that.usagePercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String selectedModelId,  String selectedProviderId,  int estimatedPromptTokens,  int maxOutputTokens,  int? contextLimit,  int? remainingTokens,  double? usagePercentage)  $default,) {final _that = this;
switch (_that) {
case _ConversationPromptEstimate():
return $default(_that.conversationId,_that.selectedModelId,_that.selectedProviderId,_that.estimatedPromptTokens,_that.maxOutputTokens,_that.contextLimit,_that.remainingTokens,_that.usagePercentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String selectedModelId,  String selectedProviderId,  int estimatedPromptTokens,  int maxOutputTokens,  int? contextLimit,  int? remainingTokens,  double? usagePercentage)?  $default,) {final _that = this;
switch (_that) {
case _ConversationPromptEstimate() when $default != null:
return $default(_that.conversationId,_that.selectedModelId,_that.selectedProviderId,_that.estimatedPromptTokens,_that.maxOutputTokens,_that.contextLimit,_that.remainingTokens,_that.usagePercentage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationPromptEstimate extends ConversationPromptEstimate {
  const _ConversationPromptEstimate({required this.conversationId, required this.selectedModelId, required this.selectedProviderId, required this.estimatedPromptTokens, required this.maxOutputTokens, this.contextLimit, this.remainingTokens, this.usagePercentage}): super._();
  factory _ConversationPromptEstimate.fromJson(Map<String, dynamic> json) => _$ConversationPromptEstimateFromJson(json);

@override final  String conversationId;
@override final  String selectedModelId;
@override final  String selectedProviderId;
@override final  int estimatedPromptTokens;
@override final  int maxOutputTokens;
@override final  int? contextLimit;
@override final  int? remainingTokens;
@override final  double? usagePercentage;

/// Create a copy of ConversationPromptEstimate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationPromptEstimateCopyWith<_ConversationPromptEstimate> get copyWith => __$ConversationPromptEstimateCopyWithImpl<_ConversationPromptEstimate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationPromptEstimateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationPromptEstimate&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.selectedModelId, selectedModelId) || other.selectedModelId == selectedModelId)&&(identical(other.selectedProviderId, selectedProviderId) || other.selectedProviderId == selectedProviderId)&&(identical(other.estimatedPromptTokens, estimatedPromptTokens) || other.estimatedPromptTokens == estimatedPromptTokens)&&(identical(other.maxOutputTokens, maxOutputTokens) || other.maxOutputTokens == maxOutputTokens)&&(identical(other.contextLimit, contextLimit) || other.contextLimit == contextLimit)&&(identical(other.remainingTokens, remainingTokens) || other.remainingTokens == remainingTokens)&&(identical(other.usagePercentage, usagePercentage) || other.usagePercentage == usagePercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,selectedModelId,selectedProviderId,estimatedPromptTokens,maxOutputTokens,contextLimit,remainingTokens,usagePercentage);

@override
String toString() {
  return 'ConversationPromptEstimate(conversationId: $conversationId, selectedModelId: $selectedModelId, selectedProviderId: $selectedProviderId, estimatedPromptTokens: $estimatedPromptTokens, maxOutputTokens: $maxOutputTokens, contextLimit: $contextLimit, remainingTokens: $remainingTokens, usagePercentage: $usagePercentage)';
}


}

/// @nodoc
abstract mixin class _$ConversationPromptEstimateCopyWith<$Res> implements $ConversationPromptEstimateCopyWith<$Res> {
  factory _$ConversationPromptEstimateCopyWith(_ConversationPromptEstimate value, $Res Function(_ConversationPromptEstimate) _then) = __$ConversationPromptEstimateCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String selectedModelId, String selectedProviderId, int estimatedPromptTokens, int maxOutputTokens, int? contextLimit, int? remainingTokens, double? usagePercentage
});




}
/// @nodoc
class __$ConversationPromptEstimateCopyWithImpl<$Res>
    implements _$ConversationPromptEstimateCopyWith<$Res> {
  __$ConversationPromptEstimateCopyWithImpl(this._self, this._then);

  final _ConversationPromptEstimate _self;
  final $Res Function(_ConversationPromptEstimate) _then;

/// Create a copy of ConversationPromptEstimate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? selectedModelId = null,Object? selectedProviderId = null,Object? estimatedPromptTokens = null,Object? maxOutputTokens = null,Object? contextLimit = freezed,Object? remainingTokens = freezed,Object? usagePercentage = freezed,}) {
  return _then(_ConversationPromptEstimate(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,selectedModelId: null == selectedModelId ? _self.selectedModelId : selectedModelId // ignore: cast_nullable_to_non_nullable
as String,selectedProviderId: null == selectedProviderId ? _self.selectedProviderId : selectedProviderId // ignore: cast_nullable_to_non_nullable
as String,estimatedPromptTokens: null == estimatedPromptTokens ? _self.estimatedPromptTokens : estimatedPromptTokens // ignore: cast_nullable_to_non_nullable
as int,maxOutputTokens: null == maxOutputTokens ? _self.maxOutputTokens : maxOutputTokens // ignore: cast_nullable_to_non_nullable
as int,contextLimit: freezed == contextLimit ? _self.contextLimit : contextLimit // ignore: cast_nullable_to_non_nullable
as int?,remainingTokens: freezed == remainingTokens ? _self.remainingTokens : remainingTokens // ignore: cast_nullable_to_non_nullable
as int?,usagePercentage: freezed == usagePercentage ? _self.usagePercentage : usagePercentage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$CompactionDecision {

 bool get shouldCompact; CompactionDecisionReason get reason; CompactionTrigger get trigger; ConversationPromptEstimate? get estimate; CompactionSettings? get settings;
/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompactionDecisionCopyWith<CompactionDecision> get copyWith => _$CompactionDecisionCopyWithImpl<CompactionDecision>(this as CompactionDecision, _$identity);

  /// Serializes this CompactionDecision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompactionDecision&&(identical(other.shouldCompact, shouldCompact) || other.shouldCompact == shouldCompact)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.estimate, estimate) || other.estimate == estimate)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shouldCompact,reason,trigger,estimate,settings);

@override
String toString() {
  return 'CompactionDecision(shouldCompact: $shouldCompact, reason: $reason, trigger: $trigger, estimate: $estimate, settings: $settings)';
}


}

/// @nodoc
abstract mixin class $CompactionDecisionCopyWith<$Res>  {
  factory $CompactionDecisionCopyWith(CompactionDecision value, $Res Function(CompactionDecision) _then) = _$CompactionDecisionCopyWithImpl;
@useResult
$Res call({
 bool shouldCompact, CompactionDecisionReason reason, CompactionTrigger trigger, ConversationPromptEstimate? estimate, CompactionSettings? settings
});


$ConversationPromptEstimateCopyWith<$Res>? get estimate;$CompactionSettingsCopyWith<$Res>? get settings;

}
/// @nodoc
class _$CompactionDecisionCopyWithImpl<$Res>
    implements $CompactionDecisionCopyWith<$Res> {
  _$CompactionDecisionCopyWithImpl(this._self, this._then);

  final CompactionDecision _self;
  final $Res Function(CompactionDecision) _then;

/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shouldCompact = null,Object? reason = null,Object? trigger = null,Object? estimate = freezed,Object? settings = freezed,}) {
  return _then(_self.copyWith(
shouldCompact: null == shouldCompact ? _self.shouldCompact : shouldCompact // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CompactionDecisionReason,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as CompactionTrigger,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as ConversationPromptEstimate?,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompactionSettings?,
  ));
}
/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationPromptEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $ConversationPromptEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompactionSettingsCopyWith<$Res>? get settings {
    if (_self.settings == null) {
    return null;
  }

  return $CompactionSettingsCopyWith<$Res>(_self.settings!, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompactionDecision].
extension CompactionDecisionPatterns on CompactionDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompactionDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompactionDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompactionDecision value)  $default,){
final _that = this;
switch (_that) {
case _CompactionDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompactionDecision value)?  $default,){
final _that = this;
switch (_that) {
case _CompactionDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool shouldCompact,  CompactionDecisionReason reason,  CompactionTrigger trigger,  ConversationPromptEstimate? estimate,  CompactionSettings? settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompactionDecision() when $default != null:
return $default(_that.shouldCompact,_that.reason,_that.trigger,_that.estimate,_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool shouldCompact,  CompactionDecisionReason reason,  CompactionTrigger trigger,  ConversationPromptEstimate? estimate,  CompactionSettings? settings)  $default,) {final _that = this;
switch (_that) {
case _CompactionDecision():
return $default(_that.shouldCompact,_that.reason,_that.trigger,_that.estimate,_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool shouldCompact,  CompactionDecisionReason reason,  CompactionTrigger trigger,  ConversationPromptEstimate? estimate,  CompactionSettings? settings)?  $default,) {final _that = this;
switch (_that) {
case _CompactionDecision() when $default != null:
return $default(_that.shouldCompact,_that.reason,_that.trigger,_that.estimate,_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompactionDecision extends CompactionDecision {
  const _CompactionDecision({required this.shouldCompact, required this.reason, required this.trigger, this.estimate, this.settings}): super._();
  factory _CompactionDecision.fromJson(Map<String, dynamic> json) => _$CompactionDecisionFromJson(json);

@override final  bool shouldCompact;
@override final  CompactionDecisionReason reason;
@override final  CompactionTrigger trigger;
@override final  ConversationPromptEstimate? estimate;
@override final  CompactionSettings? settings;

/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompactionDecisionCopyWith<_CompactionDecision> get copyWith => __$CompactionDecisionCopyWithImpl<_CompactionDecision>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompactionDecisionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompactionDecision&&(identical(other.shouldCompact, shouldCompact) || other.shouldCompact == shouldCompact)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.estimate, estimate) || other.estimate == estimate)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shouldCompact,reason,trigger,estimate,settings);

@override
String toString() {
  return 'CompactionDecision(shouldCompact: $shouldCompact, reason: $reason, trigger: $trigger, estimate: $estimate, settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$CompactionDecisionCopyWith<$Res> implements $CompactionDecisionCopyWith<$Res> {
  factory _$CompactionDecisionCopyWith(_CompactionDecision value, $Res Function(_CompactionDecision) _then) = __$CompactionDecisionCopyWithImpl;
@override @useResult
$Res call({
 bool shouldCompact, CompactionDecisionReason reason, CompactionTrigger trigger, ConversationPromptEstimate? estimate, CompactionSettings? settings
});


@override $ConversationPromptEstimateCopyWith<$Res>? get estimate;@override $CompactionSettingsCopyWith<$Res>? get settings;

}
/// @nodoc
class __$CompactionDecisionCopyWithImpl<$Res>
    implements _$CompactionDecisionCopyWith<$Res> {
  __$CompactionDecisionCopyWithImpl(this._self, this._then);

  final _CompactionDecision _self;
  final $Res Function(_CompactionDecision) _then;

/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shouldCompact = null,Object? reason = null,Object? trigger = null,Object? estimate = freezed,Object? settings = freezed,}) {
  return _then(_CompactionDecision(
shouldCompact: null == shouldCompact ? _self.shouldCompact : shouldCompact // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CompactionDecisionReason,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as CompactionTrigger,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as ConversationPromptEstimate?,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompactionSettings?,
  ));
}

/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationPromptEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $ConversationPromptEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}/// Create a copy of CompactionDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompactionSettingsCopyWith<$Res>? get settings {
    if (_self.settings == null) {
    return null;
  }

  return $CompactionSettingsCopyWith<$Res>(_self.settings!, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// @nodoc
mixin _$CompactionRange {

 String get fromMessageId; String get throughMessageId; List<String> get messageIds; List<String> get keptTailMessageIds;
/// Create a copy of CompactionRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompactionRangeCopyWith<CompactionRange> get copyWith => _$CompactionRangeCopyWithImpl<CompactionRange>(this as CompactionRange, _$identity);

  /// Serializes this CompactionRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompactionRange&&(identical(other.fromMessageId, fromMessageId) || other.fromMessageId == fromMessageId)&&(identical(other.throughMessageId, throughMessageId) || other.throughMessageId == throughMessageId)&&const DeepCollectionEquality().equals(other.messageIds, messageIds)&&const DeepCollectionEquality().equals(other.keptTailMessageIds, keptTailMessageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromMessageId,throughMessageId,const DeepCollectionEquality().hash(messageIds),const DeepCollectionEquality().hash(keptTailMessageIds));

@override
String toString() {
  return 'CompactionRange(fromMessageId: $fromMessageId, throughMessageId: $throughMessageId, messageIds: $messageIds, keptTailMessageIds: $keptTailMessageIds)';
}


}

/// @nodoc
abstract mixin class $CompactionRangeCopyWith<$Res>  {
  factory $CompactionRangeCopyWith(CompactionRange value, $Res Function(CompactionRange) _then) = _$CompactionRangeCopyWithImpl;
@useResult
$Res call({
 String fromMessageId, String throughMessageId, List<String> messageIds, List<String> keptTailMessageIds
});




}
/// @nodoc
class _$CompactionRangeCopyWithImpl<$Res>
    implements $CompactionRangeCopyWith<$Res> {
  _$CompactionRangeCopyWithImpl(this._self, this._then);

  final CompactionRange _self;
  final $Res Function(CompactionRange) _then;

/// Create a copy of CompactionRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromMessageId = null,Object? throughMessageId = null,Object? messageIds = null,Object? keptTailMessageIds = null,}) {
  return _then(_self.copyWith(
fromMessageId: null == fromMessageId ? _self.fromMessageId : fromMessageId // ignore: cast_nullable_to_non_nullable
as String,throughMessageId: null == throughMessageId ? _self.throughMessageId : throughMessageId // ignore: cast_nullable_to_non_nullable
as String,messageIds: null == messageIds ? _self.messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,keptTailMessageIds: null == keptTailMessageIds ? _self.keptTailMessageIds : keptTailMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompactionRange].
extension CompactionRangePatterns on CompactionRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompactionRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompactionRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompactionRange value)  $default,){
final _that = this;
switch (_that) {
case _CompactionRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompactionRange value)?  $default,){
final _that = this;
switch (_that) {
case _CompactionRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fromMessageId,  String throughMessageId,  List<String> messageIds,  List<String> keptTailMessageIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompactionRange() when $default != null:
return $default(_that.fromMessageId,_that.throughMessageId,_that.messageIds,_that.keptTailMessageIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fromMessageId,  String throughMessageId,  List<String> messageIds,  List<String> keptTailMessageIds)  $default,) {final _that = this;
switch (_that) {
case _CompactionRange():
return $default(_that.fromMessageId,_that.throughMessageId,_that.messageIds,_that.keptTailMessageIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fromMessageId,  String throughMessageId,  List<String> messageIds,  List<String> keptTailMessageIds)?  $default,) {final _that = this;
switch (_that) {
case _CompactionRange() when $default != null:
return $default(_that.fromMessageId,_that.throughMessageId,_that.messageIds,_that.keptTailMessageIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompactionRange extends CompactionRange {
  const _CompactionRange({required this.fromMessageId, required this.throughMessageId, required final  List<String> messageIds, required final  List<String> keptTailMessageIds}): _messageIds = messageIds,_keptTailMessageIds = keptTailMessageIds,super._();
  factory _CompactionRange.fromJson(Map<String, dynamic> json) => _$CompactionRangeFromJson(json);

@override final  String fromMessageId;
@override final  String throughMessageId;
 final  List<String> _messageIds;
@override List<String> get messageIds {
  if (_messageIds is EqualUnmodifiableListView) return _messageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageIds);
}

 final  List<String> _keptTailMessageIds;
@override List<String> get keptTailMessageIds {
  if (_keptTailMessageIds is EqualUnmodifiableListView) return _keptTailMessageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keptTailMessageIds);
}


/// Create a copy of CompactionRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompactionRangeCopyWith<_CompactionRange> get copyWith => __$CompactionRangeCopyWithImpl<_CompactionRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompactionRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompactionRange&&(identical(other.fromMessageId, fromMessageId) || other.fromMessageId == fromMessageId)&&(identical(other.throughMessageId, throughMessageId) || other.throughMessageId == throughMessageId)&&const DeepCollectionEquality().equals(other._messageIds, _messageIds)&&const DeepCollectionEquality().equals(other._keptTailMessageIds, _keptTailMessageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromMessageId,throughMessageId,const DeepCollectionEquality().hash(_messageIds),const DeepCollectionEquality().hash(_keptTailMessageIds));

@override
String toString() {
  return 'CompactionRange(fromMessageId: $fromMessageId, throughMessageId: $throughMessageId, messageIds: $messageIds, keptTailMessageIds: $keptTailMessageIds)';
}


}

/// @nodoc
abstract mixin class _$CompactionRangeCopyWith<$Res> implements $CompactionRangeCopyWith<$Res> {
  factory _$CompactionRangeCopyWith(_CompactionRange value, $Res Function(_CompactionRange) _then) = __$CompactionRangeCopyWithImpl;
@override @useResult
$Res call({
 String fromMessageId, String throughMessageId, List<String> messageIds, List<String> keptTailMessageIds
});




}
/// @nodoc
class __$CompactionRangeCopyWithImpl<$Res>
    implements _$CompactionRangeCopyWith<$Res> {
  __$CompactionRangeCopyWithImpl(this._self, this._then);

  final _CompactionRange _self;
  final $Res Function(_CompactionRange) _then;

/// Create a copy of CompactionRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromMessageId = null,Object? throughMessageId = null,Object? messageIds = null,Object? keptTailMessageIds = null,}) {
  return _then(_CompactionRange(
fromMessageId: null == fromMessageId ? _self.fromMessageId : fromMessageId // ignore: cast_nullable_to_non_nullable
as String,throughMessageId: null == throughMessageId ? _self.throughMessageId : throughMessageId // ignore: cast_nullable_to_non_nullable
as String,messageIds: null == messageIds ? _self._messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,keptTailMessageIds: null == keptTailMessageIds ? _self._keptTailMessageIds : keptTailMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$CompactionExecutionState {

 String get conversationId; CompactionTrigger get trigger; DateTime get startedAt; CompactionExecutionStatus get status;
/// Create a copy of CompactionExecutionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompactionExecutionStateCopyWith<CompactionExecutionState> get copyWith => _$CompactionExecutionStateCopyWithImpl<CompactionExecutionState>(this as CompactionExecutionState, _$identity);

  /// Serializes this CompactionExecutionState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompactionExecutionState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,trigger,startedAt,status);

@override
String toString() {
  return 'CompactionExecutionState(conversationId: $conversationId, trigger: $trigger, startedAt: $startedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $CompactionExecutionStateCopyWith<$Res>  {
  factory $CompactionExecutionStateCopyWith(CompactionExecutionState value, $Res Function(CompactionExecutionState) _then) = _$CompactionExecutionStateCopyWithImpl;
@useResult
$Res call({
 String conversationId, CompactionTrigger trigger, DateTime startedAt, CompactionExecutionStatus status
});




}
/// @nodoc
class _$CompactionExecutionStateCopyWithImpl<$Res>
    implements $CompactionExecutionStateCopyWith<$Res> {
  _$CompactionExecutionStateCopyWithImpl(this._self, this._then);

  final CompactionExecutionState _self;
  final $Res Function(CompactionExecutionState) _then;

/// Create a copy of CompactionExecutionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? trigger = null,Object? startedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as CompactionTrigger,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CompactionExecutionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CompactionExecutionState].
extension CompactionExecutionStatePatterns on CompactionExecutionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompactionExecutionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompactionExecutionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompactionExecutionState value)  $default,){
final _that = this;
switch (_that) {
case _CompactionExecutionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompactionExecutionState value)?  $default,){
final _that = this;
switch (_that) {
case _CompactionExecutionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  CompactionTrigger trigger,  DateTime startedAt,  CompactionExecutionStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompactionExecutionState() when $default != null:
return $default(_that.conversationId,_that.trigger,_that.startedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  CompactionTrigger trigger,  DateTime startedAt,  CompactionExecutionStatus status)  $default,) {final _that = this;
switch (_that) {
case _CompactionExecutionState():
return $default(_that.conversationId,_that.trigger,_that.startedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  CompactionTrigger trigger,  DateTime startedAt,  CompactionExecutionStatus status)?  $default,) {final _that = this;
switch (_that) {
case _CompactionExecutionState() when $default != null:
return $default(_that.conversationId,_that.trigger,_that.startedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompactionExecutionState extends CompactionExecutionState {
  const _CompactionExecutionState({required this.conversationId, required this.trigger, required this.startedAt, required this.status}): super._();
  factory _CompactionExecutionState.fromJson(Map<String, dynamic> json) => _$CompactionExecutionStateFromJson(json);

@override final  String conversationId;
@override final  CompactionTrigger trigger;
@override final  DateTime startedAt;
@override final  CompactionExecutionStatus status;

/// Create a copy of CompactionExecutionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompactionExecutionStateCopyWith<_CompactionExecutionState> get copyWith => __$CompactionExecutionStateCopyWithImpl<_CompactionExecutionState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompactionExecutionStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompactionExecutionState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,trigger,startedAt,status);

@override
String toString() {
  return 'CompactionExecutionState(conversationId: $conversationId, trigger: $trigger, startedAt: $startedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CompactionExecutionStateCopyWith<$Res> implements $CompactionExecutionStateCopyWith<$Res> {
  factory _$CompactionExecutionStateCopyWith(_CompactionExecutionState value, $Res Function(_CompactionExecutionState) _then) = __$CompactionExecutionStateCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, CompactionTrigger trigger, DateTime startedAt, CompactionExecutionStatus status
});




}
/// @nodoc
class __$CompactionExecutionStateCopyWithImpl<$Res>
    implements _$CompactionExecutionStateCopyWith<$Res> {
  __$CompactionExecutionStateCopyWithImpl(this._self, this._then);

  final _CompactionExecutionState _self;
  final $Res Function(_CompactionExecutionState) _then;

/// Create a copy of CompactionExecutionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? trigger = null,Object? startedAt = null,Object? status = null,}) {
  return _then(_CompactionExecutionState(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as CompactionTrigger,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CompactionExecutionStatus,
  ));
}


}


/// @nodoc
mixin _$ContextOverflowRetryState {

 String get conversationId; String get assistantRequestId; bool get hasRetriedAfterCompaction;
/// Create a copy of ContextOverflowRetryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextOverflowRetryStateCopyWith<ContextOverflowRetryState> get copyWith => _$ContextOverflowRetryStateCopyWithImpl<ContextOverflowRetryState>(this as ContextOverflowRetryState, _$identity);

  /// Serializes this ContextOverflowRetryState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextOverflowRetryState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.assistantRequestId, assistantRequestId) || other.assistantRequestId == assistantRequestId)&&(identical(other.hasRetriedAfterCompaction, hasRetriedAfterCompaction) || other.hasRetriedAfterCompaction == hasRetriedAfterCompaction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,assistantRequestId,hasRetriedAfterCompaction);

@override
String toString() {
  return 'ContextOverflowRetryState(conversationId: $conversationId, assistantRequestId: $assistantRequestId, hasRetriedAfterCompaction: $hasRetriedAfterCompaction)';
}


}

/// @nodoc
abstract mixin class $ContextOverflowRetryStateCopyWith<$Res>  {
  factory $ContextOverflowRetryStateCopyWith(ContextOverflowRetryState value, $Res Function(ContextOverflowRetryState) _then) = _$ContextOverflowRetryStateCopyWithImpl;
@useResult
$Res call({
 String conversationId, String assistantRequestId, bool hasRetriedAfterCompaction
});




}
/// @nodoc
class _$ContextOverflowRetryStateCopyWithImpl<$Res>
    implements $ContextOverflowRetryStateCopyWith<$Res> {
  _$ContextOverflowRetryStateCopyWithImpl(this._self, this._then);

  final ContextOverflowRetryState _self;
  final $Res Function(ContextOverflowRetryState) _then;

/// Create a copy of ContextOverflowRetryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? assistantRequestId = null,Object? hasRetriedAfterCompaction = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,assistantRequestId: null == assistantRequestId ? _self.assistantRequestId : assistantRequestId // ignore: cast_nullable_to_non_nullable
as String,hasRetriedAfterCompaction: null == hasRetriedAfterCompaction ? _self.hasRetriedAfterCompaction : hasRetriedAfterCompaction // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ContextOverflowRetryState].
extension ContextOverflowRetryStatePatterns on ContextOverflowRetryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextOverflowRetryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextOverflowRetryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextOverflowRetryState value)  $default,){
final _that = this;
switch (_that) {
case _ContextOverflowRetryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextOverflowRetryState value)?  $default,){
final _that = this;
switch (_that) {
case _ContextOverflowRetryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String assistantRequestId,  bool hasRetriedAfterCompaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextOverflowRetryState() when $default != null:
return $default(_that.conversationId,_that.assistantRequestId,_that.hasRetriedAfterCompaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String assistantRequestId,  bool hasRetriedAfterCompaction)  $default,) {final _that = this;
switch (_that) {
case _ContextOverflowRetryState():
return $default(_that.conversationId,_that.assistantRequestId,_that.hasRetriedAfterCompaction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String assistantRequestId,  bool hasRetriedAfterCompaction)?  $default,) {final _that = this;
switch (_that) {
case _ContextOverflowRetryState() when $default != null:
return $default(_that.conversationId,_that.assistantRequestId,_that.hasRetriedAfterCompaction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextOverflowRetryState extends ContextOverflowRetryState {
  const _ContextOverflowRetryState({required this.conversationId, required this.assistantRequestId, this.hasRetriedAfterCompaction = false}): super._();
  factory _ContextOverflowRetryState.fromJson(Map<String, dynamic> json) => _$ContextOverflowRetryStateFromJson(json);

@override final  String conversationId;
@override final  String assistantRequestId;
@override@JsonKey() final  bool hasRetriedAfterCompaction;

/// Create a copy of ContextOverflowRetryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextOverflowRetryStateCopyWith<_ContextOverflowRetryState> get copyWith => __$ContextOverflowRetryStateCopyWithImpl<_ContextOverflowRetryState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextOverflowRetryStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextOverflowRetryState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.assistantRequestId, assistantRequestId) || other.assistantRequestId == assistantRequestId)&&(identical(other.hasRetriedAfterCompaction, hasRetriedAfterCompaction) || other.hasRetriedAfterCompaction == hasRetriedAfterCompaction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,assistantRequestId,hasRetriedAfterCompaction);

@override
String toString() {
  return 'ContextOverflowRetryState(conversationId: $conversationId, assistantRequestId: $assistantRequestId, hasRetriedAfterCompaction: $hasRetriedAfterCompaction)';
}


}

/// @nodoc
abstract mixin class _$ContextOverflowRetryStateCopyWith<$Res> implements $ContextOverflowRetryStateCopyWith<$Res> {
  factory _$ContextOverflowRetryStateCopyWith(_ContextOverflowRetryState value, $Res Function(_ContextOverflowRetryState) _then) = __$ContextOverflowRetryStateCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String assistantRequestId, bool hasRetriedAfterCompaction
});




}
/// @nodoc
class __$ContextOverflowRetryStateCopyWithImpl<$Res>
    implements _$ContextOverflowRetryStateCopyWith<$Res> {
  __$ContextOverflowRetryStateCopyWithImpl(this._self, this._then);

  final _ContextOverflowRetryState _self;
  final $Res Function(_ContextOverflowRetryState) _then;

/// Create a copy of ContextOverflowRetryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? assistantRequestId = null,Object? hasRetriedAfterCompaction = null,}) {
  return _then(_ContextOverflowRetryState(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,assistantRequestId: null == assistantRequestId ? _self.assistantRequestId : assistantRequestId // ignore: cast_nullable_to_non_nullable
as String,hasRetriedAfterCompaction: null == hasRetriedAfterCompaction ? _self.hasRetriedAfterCompaction : hasRetriedAfterCompaction // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
