// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_list_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AgentListState {

 List<AgentListItem> get agents; String get search; AgentListType? get type; AgentListStatus? get status; String? get nextCursor; bool get isRefreshing; bool get isLoadingMore; bool get refreshFailed; bool get loadMoreFailed;
/// Create a copy of AgentListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentListStateCopyWith<AgentListState> get copyWith => _$AgentListStateCopyWithImpl<AgentListState>(this as AgentListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AgentListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentListState&&const DeepCollectionEquality().equals(other.agents, _this.agents)&&(identical(other.search, _this.search) || other.search == _this.search)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.isRefreshing, _this.isRefreshing) || other.isRefreshing == _this.isRefreshing)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.refreshFailed, _this.refreshFailed) || other.refreshFailed == _this.refreshFailed)&&(identical(other.loadMoreFailed, _this.loadMoreFailed) || other.loadMoreFailed == _this.loadMoreFailed));
}


@override
int get hashCode {
  final _this = this as AgentListState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.agents),_this.search,_this.type,_this.status,_this.nextCursor,_this.isRefreshing,_this.isLoadingMore,_this.refreshFailed,_this.loadMoreFailed);
}

@override
String toString() {
  final _this = this as AgentListState;
  return 'AgentListState(agents: ${_this.agents}, search: ${_this.search}, type: ${_this.type}, status: ${_this.status}, nextCursor: ${_this.nextCursor}, isRefreshing: ${_this.isRefreshing}, isLoadingMore: ${_this.isLoadingMore}, refreshFailed: ${_this.refreshFailed}, loadMoreFailed: ${_this.loadMoreFailed})';
}


}

/// @nodoc
abstract mixin class $AgentListStateCopyWith<$Res>  {
  factory $AgentListStateCopyWith(AgentListState value, $Res Function(AgentListState) _then) = _$AgentListStateCopyWithImpl;
@useResult
$Res call({
 List<AgentListItem> agents, String search, AgentListType? type, AgentListStatus? status, String? nextCursor, bool isRefreshing, bool isLoadingMore, bool refreshFailed, bool loadMoreFailed
});




}
/// @nodoc
class _$AgentListStateCopyWithImpl<$Res>
    implements $AgentListStateCopyWith<$Res> {
  _$AgentListStateCopyWithImpl(this._self, this._then);

  final AgentListState _self;
  final $Res Function(AgentListState) _then;

/// Create a copy of AgentListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agents = null,Object? search = null,Object? type = freezed,Object? status = freezed,Object? nextCursor = freezed,Object? isRefreshing = null,Object? isLoadingMore = null,Object? refreshFailed = null,Object? loadMoreFailed = null,}) {
  return _then(AgentListState(
agents: null == agents ? _self.agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentListItem>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AgentListType?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentListStatus?,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentListState].
extension AgentListStatePatterns on AgentListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentListState value)  $default,){
final _that = this;
switch (_that) {
case _AgentListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentListState value)?  $default,){
final _that = this;
switch (_that) {
case _AgentListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AgentListItem> agents,  String search,  AgentListType? type,  AgentListStatus? status,  String? nextCursor,  bool isRefreshing,  bool isLoadingMore,  bool refreshFailed,  bool loadMoreFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentListState() when $default != null:
return $default(_that.agents,_that.search,_that.type,_that.status,_that.nextCursor,_that.isRefreshing,_that.isLoadingMore,_that.refreshFailed,_that.loadMoreFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AgentListItem> agents,  String search,  AgentListType? type,  AgentListStatus? status,  String? nextCursor,  bool isRefreshing,  bool isLoadingMore,  bool refreshFailed,  bool loadMoreFailed)  $default,) {final _that = this;
switch (_that) {
case _AgentListState():
return $default(_that.agents,_that.search,_that.type,_that.status,_that.nextCursor,_that.isRefreshing,_that.isLoadingMore,_that.refreshFailed,_that.loadMoreFailed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AgentListItem> agents,  String search,  AgentListType? type,  AgentListStatus? status,  String? nextCursor,  bool isRefreshing,  bool isLoadingMore,  bool refreshFailed,  bool loadMoreFailed)?  $default,) {final _that = this;
switch (_that) {
case _AgentListState() when $default != null:
return $default(_that.agents,_that.search,_that.type,_that.status,_that.nextCursor,_that.isRefreshing,_that.isLoadingMore,_that.refreshFailed,_that.loadMoreFailed);case _:
  return null;

}
}

}

/// @nodoc


class _AgentListState extends AgentListState {
  const _AgentListState({ List<AgentListItem> agents = const [], this.search = '', this.type, this.status, this.nextCursor, this.isRefreshing = false, this.isLoadingMore = false, this.refreshFailed = false, this.loadMoreFailed = false}): _agents = agents,super._();
  

 final  List<AgentListItem> _agents;
@override@JsonKey() List<AgentListItem> get agents {
  if (_agents is EqualUnmodifiableListView) return _agents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agents);
}

@override@JsonKey() final  String search;
@override final  AgentListType? type;
@override final  AgentListStatus? status;
@override final  String? nextCursor;
@override@JsonKey() final  bool isRefreshing;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool refreshFailed;
@override@JsonKey() final  bool loadMoreFailed;

/// Create a copy of AgentListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentListStateCopyWith<_AgentListState> get copyWith => __$AgentListStateCopyWithImpl<_AgentListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentListState&&const DeepCollectionEquality().equals(other.agents, _agents)&&(identical(other.search, search) || other.search == search)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.refreshFailed, refreshFailed) || other.refreshFailed == refreshFailed)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_agents),search,type,status,nextCursor,isRefreshing,isLoadingMore,refreshFailed,loadMoreFailed);
}

@override
String toString() {
    return 'AgentListState(agents: $agents, search: $search, type: $type, status: $status, nextCursor: $nextCursor, isRefreshing: $isRefreshing, isLoadingMore: $isLoadingMore, refreshFailed: $refreshFailed, loadMoreFailed: $loadMoreFailed)';
}


}

/// @nodoc
abstract mixin class _$AgentListStateCopyWith<$Res> implements $AgentListStateCopyWith<$Res> {
  factory _$AgentListStateCopyWith(_AgentListState value, $Res Function(_AgentListState) _then) = __$AgentListStateCopyWithImpl;
@override @useResult
$Res call({
 List<AgentListItem> agents, String search, AgentListType? type, AgentListStatus? status, String? nextCursor, bool isRefreshing, bool isLoadingMore, bool refreshFailed, bool loadMoreFailed
});




}
/// @nodoc
class __$AgentListStateCopyWithImpl<$Res>
    implements _$AgentListStateCopyWith<$Res> {
  __$AgentListStateCopyWithImpl(this._self, this._then);

  final _AgentListState _self;
  final $Res Function(_AgentListState) _then;

/// Create a copy of AgentListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agents = null,Object? search = null,Object? type = freezed,Object? status = freezed,Object? nextCursor = freezed,Object? isRefreshing = null,Object? isLoadingMore = null,Object? refreshFailed = null,Object? loadMoreFailed = null,}) {
  return _then(_AgentListState(
agents: null == agents ? _self._agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentListItem>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AgentListType?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgentListStatus?,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
