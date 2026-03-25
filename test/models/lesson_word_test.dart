import 'package:flutter_test/flutter_test.dart';
// Зверни увагу: тут має бути правильний шлях до твого файлу.
// Зазвичай це виглядає як 'package:назва_твого_проєкту/models/lesson_word.dart'
// Або використовуй відносний шлях, як показано нижче:
import '../../lib/models/lesson_word.dart';

void main() {
  // group() об'єднує пов'язані тести в одну категорію для зручності
  group('Тести для моделі LessonWord:', () {
    test('fromMap має правильно створювати об\'єкт із Map', () {
      // 1. Підготовка даних (Arrange)
      final mapData = {
        'word': 'Apple',
        'translation': 'Яблуко',
        'example': 'This is an apple.',
        'audioUrl': 'apple.mp3',
      };

      // 2. Виконання дії (Act)
      final lessonWord = LessonWord.fromMap(mapData);

      // 3. Перевірка результату (Assert)
      expect(lessonWord.word, 'Apple');
      expect(lessonWord.translation, 'Яблуко');
      expect(lessonWord.example, 'This is an apple.');
      expect(lessonWord.audioUrl, 'apple.mp3');
    });

    test(
      'fromMap має підставляти порожні рядки, якщо даних немає (перевірка ?? \'\')',
      () {
        // Передаємо порожній Map
        final emptyMap = <String, dynamic>{};

        final lessonWord = LessonWord.fromMap(emptyMap);

        // Очікуємо, що замість помилки null, у нас будуть порожні рядки
        expect(lessonWord.word, '');
        expect(lessonWord.translation, '');
        expect(lessonWord.example, '');
        expect(lessonWord.audioUrl, '');
      },
    );

    test('toMap має правильно перетворювати об\'єкт назад у Map', () {
      // Створюємо об'єкт
      final lessonWord = LessonWord(
        word: 'Dog',
        translation: 'Собака',
        example: 'Good boy.',
        audioUrl: 'dog.mp3',
      );

      // Конвертуємо в Map
      final mapResult = lessonWord.toMap();

      // Перевіряємо
      expect(mapResult['word'], 'Dog');
      expect(mapResult['translation'], 'Собака');
      expect(mapResult['example'], 'Good boy.');
      expect(mapResult['audioUrl'], 'dog.mp3');
    });
  });
}
