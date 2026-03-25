import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonCardWidget extends StatelessWidget {
  final LessonModel lesson;
  final LessonProgress? progress;
  final VoidCallback onTap;

  const LessonCardWidget({
    super.key,
    required this.lesson,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = progress != null
        ? progress!.learnedWords.length / lesson.words.length
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(lesson.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level ${lesson.difficulty}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lesson.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress != null && progress!.completed
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress?.learnedWords.length ?? 0}/${lesson.words.length} words learned',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: Text(
                    progress != null && progress!.completed
                        ? 'Review'
                        : 'Start',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
