enum QuestionType { multipleChoice, chooseTranslation, typing }

class QuizQuestion {
  final QuestionType type;
  final String prompt; // text shown to user (word or translation)
  final String correctAnswer;
  final List<String> options; // for multiple choice (includes correctAnswer)

  QuizQuestion({
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    this.options = const [],
  });
}
