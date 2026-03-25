import 'lesson_word.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final int difficulty;
  final int order;
  final List<LessonWord> words;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.order,
    required this.words,
  });

  factory LessonModel.fromMap(String id, Map<String, dynamic> m) {
    final list = (m['words'] as List<dynamic>? ?? [])
        .map((e) => LessonWord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return LessonModel(
      id: id,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      difficulty: (m['difficulty'] ?? 1) as int,
      order: (m['order'] ?? 0) as int,
      words: list,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'difficulty': difficulty,
    'order': order,
    'words': words.map((w) => w.toMap()).toList(),
  };
}
