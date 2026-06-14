import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/speech_service.dart';
import '../quiz/quiz_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late String lessonId;
  late String lessonTitle;

  Future<void> _playWordAudio(String text) async {
    try {
      await SpeechService.speak(text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not play audio')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    lessonId = args['id'];
    lessonTitle = args['title'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lessonTitle)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF9BE564)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 34),
                const SizedBox(height: 10),
                Text(
                  lessonTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review the words, then start training.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(lessonId)
                  .collection('words')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No words in this lesson'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final colorScheme = Theme.of(context).colorScheme;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final word = data['word'] ?? '';
                    final translation = data['translation'] ?? '';
                    final example = data['example'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1CB0F6,
                            ).withAlpha(isDark ? 46 : 28),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.text_fields,
                            color: Color(0xFF1CB0F6),
                          ),
                        ),
                        title: Text(
                          word,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (translation.isNotEmpty) Text(translation),
                            if (example.isNotEmpty)
                              Text(
                                example,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Listen',
                          icon: const Icon(Icons.volume_up_outlined),
                          color: const Color(0xFF1CB0F6),
                          onPressed: () => _playWordAudio(word.toString()),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizScreen(),
                      settings: RouteSettings(
                        arguments: {'lessonId': lessonId},
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: const Text(
                  'Start training',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
