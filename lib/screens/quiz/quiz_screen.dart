import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../providers/word_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Word> _quizWords = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() {
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    setState(() {
      _quizWords = List.from(wordProvider.words)..shuffle();
      _currentIndex = 0;
      _showAnswer = false;
      _correctAnswers = 0;
    });
  }

  void _nextQuestion(bool correct) {
    if (correct) {
      _correctAnswers++;
    }

    if (_currentIndex < _quizWords.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete'),
        content: Text(
          'You got $_correctAnswers out of ${_quizWords.length} correct!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadQuiz();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordProvider = Provider.of<WordProvider>(context);

    if (wordProvider.words.isEmpty) {
      return const Center(child: Text('Add some words first to start a quiz!'));
    }

    if (_quizWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentWord = _quizWords[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${_quizWords.length}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    currentWord.original,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_showAnswer)
                    Text(
                      currentWord.translation,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (!_showAnswer)
            ElevatedButton(
              onPressed: () => setState(() => _showAnswer = true),
              child: const Text('Show Answer'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _nextQuestion(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Incorrect'),
                ),
                ElevatedButton(
                  onPressed: () => _nextQuestion(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Correct'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
