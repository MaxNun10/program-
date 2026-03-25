import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      _loadNextQuestion();
    }

    setState(() => _isLoading = false);
  }

  void _loadNextQuestion() {
    if (_remainingWords.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            correctAnswers: _correctAnswers,
            totalQuestions: _allWords.length,
          ),
        ),
      );
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

  void _onAnswerSelected(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _correctIndex) {
        _correctAnswers++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_allWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No words available for quiz')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question ${_allWords.length - _remainingWords.length} of ${_allWords.length}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _currentWord?['en'] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ..._options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: _answered ? null : () => _onAnswerSelected(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(index),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
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
                onPressed: _loadNextQuestion,
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
}
