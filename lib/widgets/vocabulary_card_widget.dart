import 'package:flutter/material.dart';
import '../models/lesson.dart';

class VocabularyCardWidget extends StatefulWidget {
  final LessonWord word;
  final bool isLearned;
  final VoidCallback onMarkAsLearned;

  const VocabularyCardWidget({
    super.key,
    required this.word,
    required this.isLearned,
    required this.onMarkAsLearned,
  });

  @override
  State<VocabularyCardWidget> createState() => _VocabularyCardWidgetState();
}

class _VocabularyCardWidgetState extends State<VocabularyCardWidget> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.word.word,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    // TODO: Play audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio playback not implemented'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showTranslation = !_showTranslation;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _showTranslation ? Colors.blue[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _showTranslation
                      ? widget.word.translation
                      : 'Tap to reveal translation',
                  style: TextStyle(
                    fontSize: 18,
                    color: _showTranslation ? Colors.black : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Example: ${widget.word.example}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isLearned ? 'Learned' : 'Not learned',
                  style: TextStyle(
                    color: widget.isLearned ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.isLearned ? null : widget.onMarkAsLearned,
                  child: const Text('Mark as Learned'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
