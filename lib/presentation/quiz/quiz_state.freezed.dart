// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QuizState {
  List<Question> get allQuestions =>
      throw _privateConstructorUsedError; // All questions from category
  List<Question> get questions =>
      throw _privateConstructorUsedError; // Selected 20 questions
  int get currentIndex => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  int get selectedOptionIndex => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  int get remainingSeconds => throw _privateConstructorUsedError;
  bool get isRandomizing => throw _privateConstructorUsedError;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizStateCopyWith<QuizState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizStateCopyWith<$Res> {
  factory $QuizStateCopyWith(QuizState value, $Res Function(QuizState) then) =
      _$QuizStateCopyWithImpl<$Res, QuizState>;
  @useResult
  $Res call({
    List<Question> allQuestions,
    List<Question> questions,
    int currentIndex,
    int score,
    int selectedOptionIndex,
    bool isCompleted,
    int remainingSeconds,
    bool isRandomizing,
  });
}

/// @nodoc
class _$QuizStateCopyWithImpl<$Res, $Val extends QuizState>
    implements $QuizStateCopyWith<$Res> {
  _$QuizStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allQuestions = null,
    Object? questions = null,
    Object? currentIndex = null,
    Object? score = null,
    Object? selectedOptionIndex = null,
    Object? isCompleted = null,
    Object? remainingSeconds = null,
    Object? isRandomizing = null,
  }) {
    return _then(
      _value.copyWith(
            allQuestions: null == allQuestions
                ? _value.allQuestions
                : allQuestions // ignore: cast_nullable_to_non_nullable
                      as List<Question>,
            questions: null == questions
                ? _value.questions
                : questions // ignore: cast_nullable_to_non_nullable
                      as List<Question>,
            currentIndex: null == currentIndex
                ? _value.currentIndex
                : currentIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            selectedOptionIndex: null == selectedOptionIndex
                ? _value.selectedOptionIndex
                : selectedOptionIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            isRandomizing: null == isRandomizing
                ? _value.isRandomizing
                : isRandomizing // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuizStateImplCopyWith<$Res>
    implements $QuizStateCopyWith<$Res> {
  factory _$$QuizStateImplCopyWith(
    _$QuizStateImpl value,
    $Res Function(_$QuizStateImpl) then,
  ) = __$$QuizStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Question> allQuestions,
    List<Question> questions,
    int currentIndex,
    int score,
    int selectedOptionIndex,
    bool isCompleted,
    int remainingSeconds,
    bool isRandomizing,
  });
}

/// @nodoc
class __$$QuizStateImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$QuizStateImpl>
    implements _$$QuizStateImplCopyWith<$Res> {
  __$$QuizStateImplCopyWithImpl(
    _$QuizStateImpl _value,
    $Res Function(_$QuizStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allQuestions = null,
    Object? questions = null,
    Object? currentIndex = null,
    Object? score = null,
    Object? selectedOptionIndex = null,
    Object? isCompleted = null,
    Object? remainingSeconds = null,
    Object? isRandomizing = null,
  }) {
    return _then(
      _$QuizStateImpl(
        allQuestions: null == allQuestions
            ? _value._allQuestions
            : allQuestions // ignore: cast_nullable_to_non_nullable
                  as List<Question>,
        questions: null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<Question>,
        currentIndex: null == currentIndex
            ? _value.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        selectedOptionIndex: null == selectedOptionIndex
            ? _value.selectedOptionIndex
            : selectedOptionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        isRandomizing: null == isRandomizing
            ? _value.isRandomizing
            : isRandomizing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$QuizStateImpl implements _QuizState {
  const _$QuizStateImpl({
    required final List<Question> allQuestions,
    required final List<Question> questions,
    required this.currentIndex,
    required this.score,
    required this.selectedOptionIndex,
    required this.isCompleted,
    required this.remainingSeconds,
    required this.isRandomizing,
  }) : _allQuestions = allQuestions,
       _questions = questions;

  final List<Question> _allQuestions;
  @override
  List<Question> get allQuestions {
    if (_allQuestions is EqualUnmodifiableListView) return _allQuestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allQuestions);
  }

  // All questions from category
  final List<Question> _questions;
  // All questions from category
  @override
  List<Question> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  // Selected 20 questions
  @override
  final int currentIndex;
  @override
  final int score;
  @override
  final int selectedOptionIndex;
  @override
  final bool isCompleted;
  @override
  final int remainingSeconds;
  @override
  final bool isRandomizing;

  @override
  String toString() {
    return 'QuizState(allQuestions: $allQuestions, questions: $questions, currentIndex: $currentIndex, score: $score, selectedOptionIndex: $selectedOptionIndex, isCompleted: $isCompleted, remainingSeconds: $remainingSeconds, isRandomizing: $isRandomizing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizStateImpl &&
            const DeepCollectionEquality().equals(
              other._allQuestions,
              _allQuestions,
            ) &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.selectedOptionIndex, selectedOptionIndex) ||
                other.selectedOptionIndex == selectedOptionIndex) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.isRandomizing, isRandomizing) ||
                other.isRandomizing == isRandomizing));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_allQuestions),
    const DeepCollectionEquality().hash(_questions),
    currentIndex,
    score,
    selectedOptionIndex,
    isCompleted,
    remainingSeconds,
    isRandomizing,
  );

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizStateImplCopyWith<_$QuizStateImpl> get copyWith =>
      __$$QuizStateImplCopyWithImpl<_$QuizStateImpl>(this, _$identity);
}

abstract class _QuizState implements QuizState {
  const factory _QuizState({
    required final List<Question> allQuestions,
    required final List<Question> questions,
    required final int currentIndex,
    required final int score,
    required final int selectedOptionIndex,
    required final bool isCompleted,
    required final int remainingSeconds,
    required final bool isRandomizing,
  }) = _$QuizStateImpl;

  @override
  List<Question> get allQuestions; // All questions from category
  @override
  List<Question> get questions; // Selected 20 questions
  @override
  int get currentIndex;
  @override
  int get score;
  @override
  int get selectedOptionIndex;
  @override
  bool get isCompleted;
  @override
  int get remainingSeconds;
  @override
  bool get isRandomizing;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizStateImplCopyWith<_$QuizStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
