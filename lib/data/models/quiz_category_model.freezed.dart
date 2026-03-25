// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuizCategoryModel _$QuizCategoryModelFromJson(Map<String, dynamic> json) {
  return _QuizCategoryModel.fromJson(json);
}

/// @nodoc
mixin _$QuizCategoryModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<QuestionModel> get questions => throw _privateConstructorUsedError;

  /// Serializes this QuizCategoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizCategoryModelCopyWith<QuizCategoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizCategoryModelCopyWith<$Res> {
  factory $QuizCategoryModelCopyWith(
    QuizCategoryModel value,
    $Res Function(QuizCategoryModel) then,
  ) = _$QuizCategoryModelCopyWithImpl<$Res, QuizCategoryModel>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    List<QuestionModel> questions,
  });
}

/// @nodoc
class _$QuizCategoryModelCopyWithImpl<$Res, $Val extends QuizCategoryModel>
    implements $QuizCategoryModelCopyWith<$Res> {
  _$QuizCategoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? questions = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            questions: null == questions
                ? _value.questions
                : questions // ignore: cast_nullable_to_non_nullable
                      as List<QuestionModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuizCategoryModelImplCopyWith<$Res>
    implements $QuizCategoryModelCopyWith<$Res> {
  factory _$$QuizCategoryModelImplCopyWith(
    _$QuizCategoryModelImpl value,
    $Res Function(_$QuizCategoryModelImpl) then,
  ) = __$$QuizCategoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    List<QuestionModel> questions,
  });
}

/// @nodoc
class __$$QuizCategoryModelImplCopyWithImpl<$Res>
    extends _$QuizCategoryModelCopyWithImpl<$Res, _$QuizCategoryModelImpl>
    implements _$$QuizCategoryModelImplCopyWith<$Res> {
  __$$QuizCategoryModelImplCopyWithImpl(
    _$QuizCategoryModelImpl _value,
    $Res Function(_$QuizCategoryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? questions = null,
  }) {
    return _then(
      _$QuizCategoryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        questions: null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<QuestionModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizCategoryModelImpl implements _QuizCategoryModel {
  const _$QuizCategoryModelImpl({
    required this.id,
    required this.title,
    required this.description,
    required final List<QuestionModel> questions,
  }) : _questions = questions;

  factory _$QuizCategoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizCategoryModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  final List<QuestionModel> _questions;
  @override
  List<QuestionModel> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  String toString() {
    return 'QuizCategoryModel(id: $id, title: $title, description: $description, questions: $questions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizCategoryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    const DeepCollectionEquality().hash(_questions),
  );

  /// Create a copy of QuizCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizCategoryModelImplCopyWith<_$QuizCategoryModelImpl> get copyWith =>
      __$$QuizCategoryModelImplCopyWithImpl<_$QuizCategoryModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizCategoryModelImplToJson(this);
  }
}

abstract class _QuizCategoryModel implements QuizCategoryModel {
  const factory _QuizCategoryModel({
    required final String id,
    required final String title,
    required final String description,
    required final List<QuestionModel> questions,
  }) = _$QuizCategoryModelImpl;

  factory _QuizCategoryModel.fromJson(Map<String, dynamic> json) =
      _$QuizCategoryModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  List<QuestionModel> get questions;

  /// Create a copy of QuizCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizCategoryModelImplCopyWith<_$QuizCategoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
