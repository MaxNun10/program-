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

  factory LessonWord.fromMap(Map<String, dynamic> m) => LessonWord(
    word: m['word'] ?? '',
    translation: m['translation'] ?? '',
    example: m['example'] ?? '',
    audioUrl: m['audioUrl'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'word': word,
    'translation': translation,
    'example': example,
    'audioUrl': audioUrl,
  };
}
