import 'package:flutter/material.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizQuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(int) onAnswerSelected;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.question,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...widget.question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: _selectedIndex != null
                  ? null
                  : () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onAnswerSelected(index);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedIndex == index
                    ? (index == widget.question.correctIndex
                          ? Colors.green
                          : Colors.red)
                    : null,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(option),
            ),
          );
        }),
        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _selectedIndex == widget.question.correctIndex
                  ? 'Correct!'
                  : 'Incorrect. The correct answer is: ${widget.question.options[widget.question.correctIndex]}',
              style: TextStyle(
                color: _selectedIndex == widget.question.correctIndex
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
