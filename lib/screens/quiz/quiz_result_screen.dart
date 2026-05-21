import 'package:flutter/material.dart';

enum QuizResultAction { retry, backToLessons }

class QuizResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.xpEarned,
  });

  double get percentage {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (percentage * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF4),
      appBar: AppBar(
        title: const Text('Quiz Result'),
        backgroundColor: const Color(0xFFF7FBF4),
        foregroundColor: const Color(0xFF25351F),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 116,
                  width: 116,
                  decoration: const BoxDecoration(
                    color: Color(0xFF58CC02),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Great job!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF25351F),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$correctAnswers / $totalQuestions correct',
                  style: const TextStyle(
                    color: Color(0xFF52624B),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ResultBadge(
                            icon: Icons.bolt_rounded,
                            title: 'XP earned',
                            value: '+$xpEarned',
                            color: const Color(0xFFFFC800),
                          ),
                          const SizedBox(width: 12),
                          _ResultBadge(
                            icon: Icons.check_circle_rounded,
                            title: 'Accuracy',
                            value: '$percent%',
                            color: const Color(0xFF1CB0F6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 16,
                          backgroundColor: const Color(0xFFE5E5E5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF58CC02),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(QuizResultAction.retry);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(QuizResultAction.backToLessons);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Lessons'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25351F),
                      side: const BorderSide(color: Color(0xFFD2DEC9)),
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ResultBadge({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(36),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF25351F),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF52624B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
