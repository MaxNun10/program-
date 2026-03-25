import 'models/lesson.dart';

final List<LessonModel> sampleLessons = [
  LessonModel(
    id: 'lesson_1',
    title: 'Basic Greetings',
    description: 'Learn common greetings and introductions.',
    difficulty: 1,
    order: 1,
    words: [
      LessonWord(
        word: 'Hello',
        translation: 'Hola',
        example: 'Hello, how are you?',
        audioUrl: 'https://example.com/audio/hello.mp3',
      ),
      LessonWord(
        word: 'Goodbye',
        translation: 'Adiós',
        example: 'Goodbye, see you later.',
        audioUrl: 'https://example.com/audio/goodbye.mp3',
      ),
      LessonWord(
        word: 'Thank you',
        translation: 'Gracias',
        example: 'Thank you for your help.',
        audioUrl: 'https://example.com/audio/thankyou.mp3',
      ),
      LessonWord(
        word: 'Please',
        translation: 'Por favor',
        example: 'Please, can you help me?',
        audioUrl: 'https://example.com/audio/please.mp3',
      ),
    ],
  ),
  LessonModel(
    id: 'lesson_2',
    title: 'Family Members',
    description: 'Words for family relationships.',
    difficulty: 1,
    order: 2,
    words: [
      LessonWord(
        word: 'Mother',
        translation: 'Madre',
        example: 'My mother is a teacher.',
        audioUrl: 'https://example.com/audio/mother.mp3',
      ),
      LessonWord(
        word: 'Father',
        translation: 'Padre',
        example: 'My father works in an office.',
        audioUrl: 'https://example.com/audio/father.mp3',
      ),
      LessonWord(
        word: 'Brother',
        translation: 'Hermano',
        example: 'I have a younger brother.',
        audioUrl: 'https://example.com/audio/brother.mp3',
      ),
      LessonWord(
        word: 'Sister',
        translation: 'Hermana',
        example: 'My sister is very kind.',
        audioUrl: 'https://example.com/audio/sister.mp3',
      ),
    ],
  ),
  LessonModel(
    id: 'lesson_3',
    title: 'Food and Drinks',
    description: 'Essential vocabulary for meals.',
    difficulty: 2,
    order: 3,
    words: [
      LessonWord(
        word: 'Water',
        translation: 'Agua',
        example: 'I drink water every day.',
        audioUrl: 'https://example.com/audio/water.mp3',
      ),
      LessonWord(
        word: 'Bread',
        translation: 'Pan',
        example: 'I eat bread for breakfast.',
        audioUrl: 'https://example.com/audio/bread.mp3',
      ),
      LessonWord(
        word: 'Apple',
        translation: 'Manzana',
        example: 'An apple a day keeps the doctor away.',
        audioUrl: 'https://example.com/audio/apple.mp3',
      ),
      LessonWord(
        word: 'Coffee',
        translation: 'Café',
        example: 'I like black coffee.',
        audioUrl: 'https://example.com/audio/coffee.mp3',
      ),
    ],
  ),
];
