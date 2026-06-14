import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/progress.dart';
import '../../providers/word_provider.dart';
import '../../services/firestore_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _allWords = [];
  List<Map<String, dynamic>> _remainingWords = [];
  Map<String, dynamic>? _currentWord;
  List<String> _options = [];
  int _correctIndex = 0;
  int _selectedIndex = -1;
  bool _answered = false;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _isSavingResult = false;
  bool _isOutOfHearts = false;
  UserProgress? _userProgress;
  String? _lessonId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _lessonId = args?['lessonId'];
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);

    final firestoreService = FirestoreService();
    final progress = await firestoreService.getUserProgress();
    if (!mounted) return;

    _userProgress = progress;
    if (progress.hearts <= 0) {
      setState(() {
        _isOutOfHearts = true;
        _isLoading = false;
      });
      return;
    }

    if (_lessonId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .doc(_lessonId)
          .collection('words')
          .get();

      _allWords = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'en': data['word'] ?? '',
          'ua': data['translation'] ?? '',
        };
      }).toList();

      _remainingWords = List.from(_allWords);
      _remainingWords.shuffle();
      if (_remainingWords.isNotEmpty) {
        await _loadNextQuestion();
      }
    } else {
      final words = Provider.of<WordProvider>(context, listen: false).words;

      _allWords = words
          .where(
            (word) =>
                word.original.trim().isNotEmpty &&
                word.translation.trim().isNotEmpty,
          )
          .map(
            (word) => {
              'id': word.id,
              'en': word.original,
              'ua': word.translation,
            },
          )
          .toList();

      _remainingWords = List.from(_allWords);
      _remainingWords.shuffle();
      if (_remainingWords.isNotEmpty) {
        await _loadNextQuestion();
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _restartQuiz() {
    if (_userProgress != null && _userProgress!.hearts <= 0) {
      setState(() {
        _isOutOfHearts = true;
        _isSavingResult = false;
      });
      return;
    }

    setState(() {
      _remainingWords = List.from(_allWords);
      _remainingWords.shuffle();
      _correctAnswers = 0;
      _answered = false;
      _selectedIndex = -1;
      _isSavingResult = false;
    });
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    if (_remainingWords.isEmpty) {
      if (_isSavingResult) return;

      setState(() {
        _isSavingResult = true;
      });

      final xpEarned = _calculateXpEarned(_correctAnswers, _allWords.length);

      try {
        final firestoreService = FirestoreService();
        final updatedProgress = await firestoreService.updateUserProgress(
          xpEarned,
          completedLessonId: _lessonId,
        );
        if (mounted && updatedProgress.shouldCelebrateDailyGoal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily Goal Completed!')),
          );
          try {
            await firestoreService.markDailyGoalCelebrated();
          } catch (_) {}
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to save XP')));
        }
      }

      if (!mounted) return;

      final action = await Navigator.push<QuizResultAction>(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            correctAnswers: _correctAnswers,
            totalQuestions: _allWords.length,
            xpEarned: xpEarned,
          ),
        ),
      );

      if (!mounted) return;

      if (action == QuizResultAction.retry) {
        _restartQuiz();
      } else if (action == QuizResultAction.backToLessons) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
        if (navigator.canPop()) {
          await navigator.maybePop();
        }
      } else {
        setState(() {
          _isSavingResult = false;
        });
      }
      return;
    }

    setState(() {
      _currentWord = _remainingWords.removeAt(0);
      _options = _generateOptions(_currentWord!);
      _answered = false;
      _selectedIndex = -1;
    });
  }

  List<String> _generateOptions(Map<String, dynamic> currentWord) {
    final options = <String>[];
    options.add(currentWord['ua']);

    final otherWords = _allWords
        .where((word) => word['id'] != currentWord['id'])
        .toList();
    otherWords.shuffle();

    final wrongAnswersCount = otherWords.length < 3 ? otherWords.length : 3;
    for (int i = 0; i < wrongAnswersCount; i++) {
      options.add(otherWords[i]['ua']);
    }

    while (options.length < 4) {
      options.add('Placeholder Answer');
    }

    options.shuffle();
    _correctIndex = options.indexOf(currentWord['ua']);

    return options;
  }

  Future<void> _onAnswerSelected(int index) async {
    if (_answered) return;

    final isCorrect = index == _correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isCorrect) {
        _correctAnswers++;
      }
    });

    if (!isCorrect) {
      await _loseHeartForWrongAnswer();
    }
  }

  Future<void> _loseHeartForWrongAnswer() async {
    try {
      final progress = await FirestoreService().loseHeart();
      if (!mounted) return;
      setState(() {
        _userProgress = progress;
        _isOutOfHearts = progress.hearts <= 0;
      });
      if (progress.hearts <= 0) {
        _showOutOfHeartsDialog(progress);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update hearts')));
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

  int _calculateXpEarned(int correctAnswers, int totalQuestions) {
    var xp = correctAnswers * 10 + 20;
    if (correctAnswers == totalQuestions && totalQuestions > 0) {
      xp += 10;
    }
    return xp;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isOutOfHearts) {
      return _buildOutOfHeartsScreen();
    }

    if (_allWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No words available for quiz')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [_buildHeartsIndicator()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value:
                    (_allWords.length - _remainingWords.length) /
                    _allWords.length,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF58CC02),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Question ${_allWords.length - _remainingWords.length} of ${_allWords.length}',
              style: const TextStyle(
                color: Color(0xFF52624B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E9DD)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Text(
                  _currentWord?['en'] ?? '',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF25351F),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ..._options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: _answered ? null : () => _onAnswerSelected(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(index) ?? Colors.white,
                    disabledBackgroundColor:
                        _getButtonColor(index) ?? Colors.white,
                    foregroundColor: _getOptionTextColor(index),
                    disabledForegroundColor: _getOptionTextColor(index),
                    minimumSize: const Size(double.infinity, 54),
                    side: BorderSide(
                      color: _getButtonColor(index) ?? const Color(0xFFDDE7D7),
                      width: 1.4,
                    ),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            if (_answered)
              Text(
                _selectedIndex == _correctIndex ? 'Correct!' : 'Wrong',
                style: TextStyle(
                  color: _selectedIndex == _correctIndex
                      ? Colors.green
                      : Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            if (_answered)
              ElevatedButton(
                onPressed: (_userProgress?.hearts ?? 0) > 0
                    ? () {
                        _loadNextQuestion();
                      }
                    : null,
                child: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }

  Color? _getButtonColor(int index) {
    if (!_answered) return null;

    if (index == _correctIndex) {
      return Colors.green;
    } else if (index == _selectedIndex) {
      return Colors.red;
    }
    return null;
  }

  Color _getOptionTextColor(int index) {
    if (!_answered) return const Color(0xFF25351F);
    if (index == _correctIndex || index == _selectedIndex) {
      return Colors.white;
    }
    return const Color(0xFF52624B);
  }

  Widget _buildHeartsIndicator() {
    final hearts = _userProgress?.hearts ?? UserProgress.defaultMaxHearts;
    final maxHearts = _userProgress?.maxHearts ?? UserProgress.defaultMaxHearts;

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
    final refillText = _userProgress?.getHeartRefillText() ?? 'Try again soon';

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
