class LessonWord {
  final String word;
  final String translation;
  final String example;
  final String audioUrl;

  LessonWord({
    required this.word,
    required this.translation,
    required this.example,
    required this.audioUrl,
  });

  factory LessonWord.fromMap(Map<String, dynamic> data) {
    return LessonWord(
      word: data['word'] ?? '',
      translation: data['translation'] ?? '',
      example: data['example'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'translation': translation,
      'example': example,
      'audioUrl': audioUrl,
    };
  }
}

class LessonModel {
  final String id;
  final String title;
  final String description;
  final List<LessonWord> words;
  final int difficulty;
  final int order;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    required this.difficulty,
    required this.order,
  });

  factory LessonModel.fromMap(String id, Map<String, dynamic> data) {
    return LessonModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      words:
          (data['words'] as List<dynamic>?)
              ?.map((wordData) => LessonWord.fromMap(wordData))
              .toList() ??
          [],
      difficulty: data['difficulty'] ?? 1,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'words': words.map((word) => word.toMap()).toList(),
      'difficulty': difficulty,
      'order': order,
    };
  }
}

class LessonProgress {
  final String lessonId;
  final bool completed;
  final List<String> learnedWords;
  final int score;

  LessonProgress({
    required this.lessonId,
    required this.completed,
    required this.learnedWords,
    required this.score,
  });

  factory LessonProgress.fromMap(String lessonId, Map<String, dynamic> data) {
    return LessonProgress(
      lessonId: lessonId,
      completed: data['completed'] ?? false,
      learnedWords: List<String>.from(data['learnedWords'] ?? []),
      score: data['score'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'learnedWords': learnedWords,
      'score': score,
    };
  }
}
