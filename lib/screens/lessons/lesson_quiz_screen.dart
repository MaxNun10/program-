import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lesson_model.dart';
import '../../models/quiz_question.dart';
import '../../providers/lesson_provider.dart';
import '../../services/lessons_service.dart';
import '../../services/quiz_generator.dart';
import '../../services/firestore_service.dart';
import 'quiz_result_screen.dart';

class LessonQuizScreen extends StatefulWidget {
  const LessonQuizScreen({super.key});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  LessonModel? lesson;
  List<QuizQuestion> questions = [];
  bool isLoading = true;
  int currentIndex = 0;
  List<bool> isAnswered = [];
  List<bool> isCorrect = [];
  int correctCount = 0;
  late TextEditingController controller;
  late String lessonId;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      lessonId = ModalRoute.of(context)!.settings.arguments as String;
      _loadLesson();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _completeQuiz() async {
    try {
      final service = LessonsService();
      await saveQuizScore(service.userId!, lessonId, correctCount);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      provider.updateLessonProgress(lessonId, {
        'score': correctCount,
        'completed': true,
      });

      final firestoreService = FirestoreService();
      final currentProgress = await firestoreService.getUserProgress();
      final oldStreak = currentProgress.streak;
      final xpEarned = calculateXpEarned(correctCount, questions.length);
      final newProgress = await firestoreService.updateUserProgress(xpEarned);
      final levelUp = newProgress.level > currentProgress.level;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              correctAnswers: correctCount,
              totalQuestions: questions.length,
              xpEarned: xpEarned,
              userProgress: newProgress,
              levelUp: levelUp,
              oldStreak: oldStreak,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save result')));
      }
    }
  }

  Future<void> _loadLesson() async {
    final service = LessonsService();
    final loadedLesson = await service.getLessonById(lessonId);
    if (loadedLesson != null) {
      setState(() {
        lesson = loadedLesson;
        questions = generateQuizQuestions(loadedLesson.words);
        isAnswered = List.filled(questions.length, false);
        isCorrect = List.filled(questions.length, false);
        correctCount = 0;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildQuestionContent() {
    final question = questions[currentIndex];
    if (question.type == QuestionType.multipleChoice) {
      return Column(
        children: [
          Text(question.prompt, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: isAnswered[currentIndex]
                        ? null
                        : () {
                            setState(() {
                              isAnswered[currentIndex] = true;
                              isCorrect[currentIndex] =
                                  option == question.correctAnswer;
                              if (isCorrect[currentIndex]) correctCount++;
                            });
                          },
                    child: Text(option),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (question.type == QuestionType.chooseTranslation) {
      final words = lesson!.words.map((w) => w.word).toList();
      words.shuffle();
      return Column(
        children: [
          Text(question.prompt, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
              ),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: isAnswered[currentIndex]
                        ? null
                        : () {
                            setState(() {
                              isAnswered[currentIndex] = true;
                              isCorrect[currentIndex] =
                                  word == question.correctAnswer;
                              if (isCorrect[currentIndex]) correctCount++;
                            });
                          },
                    child: Text(word),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (question.type == QuestionType.typing) {
      return Column(
        children: [
          Text(question.prompt, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            enabled: !isAnswered[currentIndex],
            decoration: const InputDecoration(hintText: 'Enter the word'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isAnswered[currentIndex]
                ? null
                : () {
                    final input = controller.text.trim().toLowerCase();
                    final correct = question.correctAnswer.toLowerCase();
                    setState(() {
                      isAnswered[currentIndex] = true;
                      isCorrect[currentIndex] = input == correct;
                      if (isCorrect[currentIndex]) correctCount++;
                    });
                  },
            child: const Text('Submit'),
          ),
        ],
      );
    } else {
      return const Column(children: [Text('Question content here')]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (lesson == null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    if (currentIndex == questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Processing Result')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${lesson!.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Question ${currentIndex + 1} / ${questions.length}'),
            const SizedBox(height: 20),
            Expanded(child: _buildQuestionContent()),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0
                      ? () {
                          setState(() {
                            currentIndex--;
                            controller.clear();
                          });
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currentIndex == questions.length - 1) {
                      _completeQuiz();
                    } else {
                      setState(() {
                        currentIndex++;
                        controller.clear();
                      });
                    }
                  },
                  child: Text(
                    currentIndex == questions.length - 1 ? 'Finish' : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
