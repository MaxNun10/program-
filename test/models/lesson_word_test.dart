import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_5/models/lesson_word.dart';

void main() {
  group('LessonWord', () {
    test('fromMap creates an object from map data', () {
      final mapData = {
        'word': 'Apple',
        'translation': 'Apple translation',
        'example': 'This is an apple.',
        'audioUrl': 'apple.mp3',
      };

      final lessonWord = LessonWord.fromMap(mapData);

      expect(lessonWord.word, 'Apple');
      expect(lessonWord.translation, 'Apple translation');
      expect(lessonWord.example, 'This is an apple.');
      expect(lessonWord.audioUrl, 'apple.mp3');
    });

    test('fromMap uses empty strings for missing data', () {
      final lessonWord = LessonWord.fromMap(<String, dynamic>{});

      expect(lessonWord.word, '');
      expect(lessonWord.translation, '');
      expect(lessonWord.example, '');
      expect(lessonWord.audioUrl, '');
    });

    test('toMap converts the object back to map data', () {
      final lessonWord = LessonWord(
        word: 'Dog',
        translation: 'Dog translation',
        example: 'Good boy.',
        audioUrl: 'dog.mp3',
      );

      final mapResult = lessonWord.toMap();

      expect(mapResult['word'], 'Dog');
      expect(mapResult['translation'], 'Dog translation');
      expect(mapResult['example'], 'Good boy.');
      expect(mapResult['audioUrl'], 'dog.mp3');
    });
  });
}
