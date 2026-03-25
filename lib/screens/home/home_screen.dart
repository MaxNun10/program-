import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../models/progress.dart';
import '../../providers/auth_provider.dart';
import '../../providers/word_provider.dart';
import '../../services/firestore_service.dart';
import '../quiz/quiz_screen.dart';
import 'add_word_screen.dart';
import 'edit_word_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    WordsList(),
    QuizScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () => Navigator.pushNamed(context, '/lessons'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Words'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddWordScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class WordsList extends StatefulWidget {
  const WordsList({super.key});

  @override
  State<WordsList> createState() => _WordsListState();
}

class _WordsListState extends State<WordsList> {
  void _showDeleteDialog(BuildContext context, Word word) {
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Word'),
          content: Text('Are you sure you want to delete "${word.original}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await wordProvider.deleteWord(word.id);
                  navigator.pop(); // Close dialog
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Word deleted successfully')),
                  );
                } catch (e) {
                  navigator.pop(); // Close dialog
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete word: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordProvider = Provider.of<WordProvider>(context);

    if (wordProvider.words.isEmpty) {
      return const Center(
        child: Text('No words yet. Add some words to start learning!'),
      );
    }

    return ListView.builder(
      itemCount: wordProvider.words.length,
      itemBuilder: (context, index) {
        final word = wordProvider.words[index];
        return ListTile(
          title: Text(word.original),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${word.translation} • ${word.category}'),
              Text(
                'Correct: ${word.correctCount} • Incorrect: ${word.incorrectCount}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Difficulty: ${word.difficulty}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditWordScreen(word: word)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, word),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProgress? userProgress;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    try {
      final firestoreService = FirestoreService();
      final progress = await firestoreService.getUserProgress();
      setState(() {
        userProgress = progress;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final wordProvider = Provider.of<WordProvider>(context);

    final totalCorrect = wordProvider.words.fold<int>(
      0,
      (sum, word) => sum + word.correctCount,
    );
    final totalIncorrect = wordProvider.words.fold<int>(
      0,
      (sum, word) => sum + word.incorrectCount,
    );
    final totalAttempts = totalCorrect + totalIncorrect;
    final accuracy = totalAttempts > 0
        ? (totalCorrect / totalAttempts * 100).round()
        : 0;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text('Email: ${authProvider.user?.email ?? 'N/A'}'),
          const SizedBox(height: 16),
          Text('Total Words: ${wordProvider.words.length}'),
          const SizedBox(height: 16),
          if (userProgress != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🔥 Streak',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${userProgress!.streak} days',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Level: ${userProgress!.level}'),
            Text('Total XP: ${userProgress!.xp}'),
            const SizedBox(height: 16),
          ],
          Text(
            'Quiz Statistics:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Total Attempts: $totalAttempts'),
          Text('Correct Answers: $totalCorrect'),
          Text('Incorrect Answers: $totalIncorrect'),
          Text('Accuracy: $accuracy%'),
        ],
      ),
    );
  }
}
