import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lesson_model.dart';
import '../../models/progress.dart';
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
  bool isCompleting = false;
  bool isOutOfHearts = false;
  int currentIndex = 0;
  List<bool> isAnswered = [];
  List<bool> isCorrect = [];
  int correctCount = 0;
  UserProgress? userProgress;
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
    if (isCompleting) return;

    setState(() {
      isCompleting = true;
    });

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
      final newProgress = await firestoreService.updateUserProgress(
        xpEarned,
        completedLessonId: lessonId,
      );
      if (mounted && newProgress.shouldCelebrateDailyGoal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Goal Completed!')),
        );
        try {
          await firestoreService.markDailyGoalCelebrated();
        } catch (_) {}
      }
      final levelUp = newProgress.level > currentProgress.level;

      if (mounted) {
        final action = await Navigator.of(context).push<QuizResultAction>(
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

        if (!mounted) return;

        if (action == QuizResultAction.retry) {
          _resetQuiz();
        } else if (action == QuizResultAction.backToLessons) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          setState(() {
            isCompleting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCompleting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save result')));
      }
    }
  }

  void _resetQuiz() {
    if (userProgress != null && userProgress!.hearts <= 0) {
      setState(() {
        isOutOfHearts = true;
        isCompleting = false;
      });
      return;
    }

    setState(() {
      currentIndex = 0;
      isAnswered = List.filled(questions.length, false);
      isCorrect = List.filled(questions.length, false);
      correctCount = 0;
      isCompleting = false;
      controller.clear();
    });
  }

  Future<void> _loadLesson() async {
    final firestoreService = FirestoreService();
    final progress = await firestoreService.getUserProgress();
    if (!mounted) return;

    userProgress = progress;
    if (progress.hearts <= 0) {
      setState(() {
        isOutOfHearts = true;
        isLoading = false;
      });
      return;
    }

    final service = LessonsService();
    final loadedLesson = await service.getLessonById(lessonId);
    if (!mounted) return;
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

  Future<void> _recordAnswer(bool correct) async {
    if (isAnswered[currentIndex]) return;

    setState(() {
      isAnswered[currentIndex] = true;
      isCorrect[currentIndex] = correct;
      if (correct) correctCount++;
    });

    if (!correct) {
      await _loseHeartForWrongAnswer();
    }
  }

  Future<void> _loseHeartForWrongAnswer() async {
    try {
      final progress = await FirestoreService().loseHeart();
      if (!mounted) return;
      setState(() {
        userProgress = progress;
        isOutOfHearts = progress.hearts <= 0;
      });
      if (progress.hearts <= 0) {
        _showOutOfHeartsDialog(progress);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update hearts')),
      );
    }
  }

  void _showOutOfHeartsDialog(UserProgress progress) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Out of Hearts'),
          content: Text(
            'You are out of hearts. Wait for hearts to refill.\n${progress.getHeartRefillText()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
                            _recordAnswer(option == question.correctAnswer);
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
                            _recordAnswer(word == question.correctAnswer);
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
                    _recordAnswer(input == correct);
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

    if (isOutOfHearts) {
      return _buildOutOfHeartsScreen();
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
      appBar: AppBar(
        title: Text('Quiz: ${lesson!.title}'),
        actions: [_buildHeartsIndicator()],
      ),
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
                  onPressed: isCompleting
                          || (userProgress?.hearts ?? 0) <= 0
                      ? null
                      : () {
                          if (currentIndex == questions.length - 1) {
                            _completeQuiz();
                          } else {
                            setState(() {
                              currentIndex++;
                              controller.clear();
                            });
                          }
                        },
                  child: isCompleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          currentIndex == questions.length - 1
                              ? 'Finish'
                              : 'Next',
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartsIndicator() {
    final hearts = userProgress?.hearts ?? UserProgress.defaultMaxHearts;
    final maxHearts = userProgress?.maxHearts ?? UserProgress.defaultMaxHearts;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              '$hearts / $maxHearts',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfHeartsScreen() {
    final refillText = userProgress?.getHeartRefillText() ?? 'Try again soon';

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'You are out of hearts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wait for hearts to refill.\n$refillText',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
