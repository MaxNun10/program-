class Word {
  final String id;
  final String original;
  final String translation;
  final String category;
  final int difficulty; // 1-5
  final DateTime createdAt;
  final int correctCount;
  final int incorrectCount;

  Word({
    required this.id,
    required this.original,
    required this.translation,
    required this.category,
    this.difficulty = 1,
    required this.createdAt,
    this.correctCount = 0,
    this.incorrectCount = 0,
  });

  factory Word.fromMap(String id, Map<String, dynamic> data) {
    return Word(
      id: id,
      original: data['original'] ?? '',
      translation: data['translation'] ?? '',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? 1,
      createdAt: data['createdAt'] is String
          ? DateTime.parse(data['createdAt'])
          : data['createdAt'] ?? DateTime.now(),
      correctCount: data['correctCount'] ?? 0,
      incorrectCount: data['incorrectCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'original': original,
      'translation': translation,
      'category': category,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
    };
  }

  Word copyWith({
    String? id,
    String? original,
    String? translation,
    String? category,
    int? difficulty,
    DateTime? createdAt,
    int? correctCount,
    int? incorrectCount,
  }) {
    return Word(
      id: id ?? this.id,
      original: original ?? this.original,
      translation: translation ?? this.translation,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }
}
