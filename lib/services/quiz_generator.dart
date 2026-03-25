import 'dart:math';

import '../models/quiz_question.dart';
import '../models/lesson_word.dart';

List<QuizQuestion> generateQuizQuestions(
  List<LessonWord> words, {
  int count = 8,
}) {
  if (words.isEmpty) return [];

  final random = Random();
  final selectedWords = List.generate(count, (i) => words[i % words.length]);
  final allTranslations = words.map((w) => w.translation).toList();

  return selectedWords.map((word) {
    final typeIndex = random.nextInt(3);
    final type = QuestionType.values[typeIndex];

    switch (type) {
      case QuestionType.multipleChoice:
        final correct = word.translation;
        final others = allTranslations.where((t) => t != correct).toList();
        others.shuffle(random);
        final options = [correct] + others.take(3).toList();
        options.shuffle(random);
        return QuizQuestion(
          type: type,
          prompt: word.word,
          correctAnswer: correct,
          options: options,
        );
      case QuestionType.chooseTranslation:
        return QuizQuestion(
          type: type,
          prompt: word.translation,
          correctAnswer: word.word,
          options: [],
        );
      case QuestionType.typing:
        return QuizQuestion(
          type: type,
          prompt: word.translation,
          correctAnswer: word.word,
          options: [],
        );
    }
  }).toList();
}
