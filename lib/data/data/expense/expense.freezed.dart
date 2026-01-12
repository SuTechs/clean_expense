// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseData {

 String get id; double get amount; String get category; DateTime get date; TransactionType get type; String get note;
/// Create a copy of ExpenseData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseDataCopyWith<ExpenseData> get copyWith => _$ExpenseDataCopyWithImpl<ExpenseData>(this as ExpenseData, _$identity);

  /// Serializes this ExpenseData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseData&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,category,date,type,note);

@override
String toString() {
  return 'ExpenseData(id: $id, amount: $amount, category: $category, date: $date, type: $type, note: $note)';
}


}

/// @nodoc
abstract mixin class $ExpenseDataCopyWith<$Res>  {
  factory $ExpenseDataCopyWith(ExpenseData value, $Res Function(ExpenseData) _then) = _$ExpenseDataCopyWithImpl;
@useResult
$Res call({
 String id, double amount, String category, DateTime date, TransactionType type, String note
});




}
/// @nodoc
class _$ExpenseDataCopyWithImpl<$Res>
    implements $ExpenseDataCopyWith<$Res> {
  _$ExpenseDataCopyWithImpl(this._self, this._then);

  final ExpenseData _self;
  final $Res Function(ExpenseData) _then;

/// Create a copy of ExpenseData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? category = null,Object? date = null,Object? type = null,Object? note = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseData].
extension ExpenseDataPatterns on ExpenseData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseData value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseData value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double amount,  String category,  DateTime date,  TransactionType type,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseData() when $default != null:
return $default(_that.id,_that.amount,_that.category,_that.date,_that.type,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double amount,  String category,  DateTime date,  TransactionType type,  String note)  $default,) {final _that = this;
switch (_that) {
case _ExpenseData():
return $default(_that.id,_that.amount,_that.category,_that.date,_that.type,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double amount,  String category,  DateTime date,  TransactionType type,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseData() when $default != null:
return $default(_that.id,_that.amount,_that.category,_that.date,_that.type,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseData extends ExpenseData {
  const _ExpenseData({required this.id, required this.amount, required this.category, required this.date, required this.type, required this.note}): super._();
  factory _ExpenseData.fromJson(Map<String, dynamic> json) => _$ExpenseDataFromJson(json);

@override final  String id;
@override final  double amount;
@override final  String category;
@override final  DateTime date;
@override final  TransactionType type;
@override final  String note;

/// Create a copy of ExpenseData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseDataCopyWith<_ExpenseData> get copyWith => __$ExpenseDataCopyWithImpl<_ExpenseData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseData&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,category,date,type,note);

@override
String toString() {
  return 'ExpenseData(id: $id, amount: $amount, category: $category, date: $date, type: $type, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ExpenseDataCopyWith<$Res> implements $ExpenseDataCopyWith<$Res> {
  factory _$ExpenseDataCopyWith(_ExpenseData value, $Res Function(_ExpenseData) _then) = __$ExpenseDataCopyWithImpl;
@override @useResult
$Res call({
 String id, double amount, String category, DateTime date, TransactionType type, String note
});




}
/// @nodoc
class __$ExpenseDataCopyWithImpl<$Res>
    implements _$ExpenseDataCopyWith<$Res> {
  __$ExpenseDataCopyWithImpl(this._self, this._then);

  final _ExpenseData _self;
  final $Res Function(_ExpenseData) _then;

/// Create a copy of ExpenseData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? category = null,Object? date = null,Object? type = null,Object? note = null,}) {
  return _then(_ExpenseData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
