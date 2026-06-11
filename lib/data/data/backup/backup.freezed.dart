// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackupData {

/// Bump when the backup shape changes; restore refuses newer versions.
 int get schemaVersion; String get app;/// Epoch millis when this backup was written.
 int get lastModified; UserData get user;/// App-level settings worth restoring (currency symbol, etc.).
 Map<String, String> get settings;/// Deleted expense ids -> epoch millis of deletion. Lets a sync delete
/// records on other devices instead of resurrecting them.
 Map<String, int> get tombstones; List<ExpenseData> get expenses;
/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupDataCopyWith<BackupData> get copyWith => _$BackupDataCopyWithImpl<BackupData>(this as BackupData, _$identity);

  /// Serializes this BackupData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupData&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.app, app) || other.app == app)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.settings, settings)&&const DeepCollectionEquality().equals(other.tombstones, tombstones)&&const DeepCollectionEquality().equals(other.expenses, expenses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,app,lastModified,user,const DeepCollectionEquality().hash(settings),const DeepCollectionEquality().hash(tombstones),const DeepCollectionEquality().hash(expenses));

@override
String toString() {
  return 'BackupData(schemaVersion: $schemaVersion, app: $app, lastModified: $lastModified, user: $user, settings: $settings, tombstones: $tombstones, expenses: $expenses)';
}


}

/// @nodoc
abstract mixin class $BackupDataCopyWith<$Res>  {
  factory $BackupDataCopyWith(BackupData value, $Res Function(BackupData) _then) = _$BackupDataCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, String app, int lastModified, UserData user, Map<String, String> settings, Map<String, int> tombstones, List<ExpenseData> expenses
});


$UserDataCopyWith<$Res> get user;

}
/// @nodoc
class _$BackupDataCopyWithImpl<$Res>
    implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._self, this._then);

  final BackupData _self;
  final $Res Function(BackupData) _then;

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? app = null,Object? lastModified = null,Object? user = null,Object? settings = null,Object? tombstones = null,Object? expenses = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as int,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserData,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, String>,tombstones: null == tombstones ? _self.tombstones : tombstones // ignore: cast_nullable_to_non_nullable
as Map<String, int>,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<ExpenseData>,
  ));
}
/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res> get user {
  
  return $UserDataCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [BackupData].
extension BackupDataPatterns on BackupData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackupData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackupData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackupData value)  $default,){
final _that = this;
switch (_that) {
case _BackupData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackupData value)?  $default,){
final _that = this;
switch (_that) {
case _BackupData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  String app,  int lastModified,  UserData user,  Map<String, String> settings,  Map<String, int> tombstones,  List<ExpenseData> expenses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackupData() when $default != null:
return $default(_that.schemaVersion,_that.app,_that.lastModified,_that.user,_that.settings,_that.tombstones,_that.expenses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  String app,  int lastModified,  UserData user,  Map<String, String> settings,  Map<String, int> tombstones,  List<ExpenseData> expenses)  $default,) {final _that = this;
switch (_that) {
case _BackupData():
return $default(_that.schemaVersion,_that.app,_that.lastModified,_that.user,_that.settings,_that.tombstones,_that.expenses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  String app,  int lastModified,  UserData user,  Map<String, String> settings,  Map<String, int> tombstones,  List<ExpenseData> expenses)?  $default,) {final _that = this;
switch (_that) {
case _BackupData() when $default != null:
return $default(_that.schemaVersion,_that.app,_that.lastModified,_that.user,_that.settings,_that.tombstones,_that.expenses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackupData extends BackupData {
  const _BackupData({required this.schemaVersion, required this.app, required this.lastModified, required this.user, required final  Map<String, String> settings, required final  Map<String, int> tombstones, required final  List<ExpenseData> expenses}): _settings = settings,_tombstones = tombstones,_expenses = expenses,super._();
  factory _BackupData.fromJson(Map<String, dynamic> json) => _$BackupDataFromJson(json);

/// Bump when the backup shape changes; restore refuses newer versions.
@override final  int schemaVersion;
@override final  String app;
/// Epoch millis when this backup was written.
@override final  int lastModified;
@override final  UserData user;
/// App-level settings worth restoring (currency symbol, etc.).
 final  Map<String, String> _settings;
/// App-level settings worth restoring (currency symbol, etc.).
@override Map<String, String> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}

/// Deleted expense ids -> epoch millis of deletion. Lets a sync delete
/// records on other devices instead of resurrecting them.
 final  Map<String, int> _tombstones;
/// Deleted expense ids -> epoch millis of deletion. Lets a sync delete
/// records on other devices instead of resurrecting them.
@override Map<String, int> get tombstones {
  if (_tombstones is EqualUnmodifiableMapView) return _tombstones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tombstones);
}

 final  List<ExpenseData> _expenses;
@override List<ExpenseData> get expenses {
  if (_expenses is EqualUnmodifiableListView) return _expenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenses);
}


/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackupDataCopyWith<_BackupData> get copyWith => __$BackupDataCopyWithImpl<_BackupData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackupDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackupData&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.app, app) || other.app == app)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other._settings, _settings)&&const DeepCollectionEquality().equals(other._tombstones, _tombstones)&&const DeepCollectionEquality().equals(other._expenses, _expenses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,app,lastModified,user,const DeepCollectionEquality().hash(_settings),const DeepCollectionEquality().hash(_tombstones),const DeepCollectionEquality().hash(_expenses));

@override
String toString() {
  return 'BackupData(schemaVersion: $schemaVersion, app: $app, lastModified: $lastModified, user: $user, settings: $settings, tombstones: $tombstones, expenses: $expenses)';
}


}

/// @nodoc
abstract mixin class _$BackupDataCopyWith<$Res> implements $BackupDataCopyWith<$Res> {
  factory _$BackupDataCopyWith(_BackupData value, $Res Function(_BackupData) _then) = __$BackupDataCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, String app, int lastModified, UserData user, Map<String, String> settings, Map<String, int> tombstones, List<ExpenseData> expenses
});


@override $UserDataCopyWith<$Res> get user;

}
/// @nodoc
class __$BackupDataCopyWithImpl<$Res>
    implements _$BackupDataCopyWith<$Res> {
  __$BackupDataCopyWithImpl(this._self, this._then);

  final _BackupData _self;
  final $Res Function(_BackupData) _then;

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? app = null,Object? lastModified = null,Object? user = null,Object? settings = null,Object? tombstones = null,Object? expenses = null,}) {
  return _then(_BackupData(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as int,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserData,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, String>,tombstones: null == tombstones ? _self._tombstones : tombstones // ignore: cast_nullable_to_non_nullable
as Map<String, int>,expenses: null == expenses ? _self._expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<ExpenseData>,
  ));
}

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res> get user {
  
  return $UserDataCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
