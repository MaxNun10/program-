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
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 64, color: Color(0xFF58CC02)),
              SizedBox(height: 16),
              Text(
                'No words yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Add your first word to start learning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF52624B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wordProvider.words.length,
      itemBuilder: (context, index) {
        final word = wordProvider.words[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.translate, color: Color(0xFF58CC02)),
          ),
          title: Text(word.original),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${word.translation} - ${word.category}'),
              Text(
                'Correct: ${word.correctCount}  Incorrect: ${word.incorrectCount}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Difficulty: ${word.difficulty}'),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditWordScreen(word: word)),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () => _showDeleteDialog(context, word),
              ),
            ],
          ),
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
      if (!mounted) return;
      setState(() {
        userProgress = progress;
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDailyGoalCelebrationIfNeeded(progress);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showDailyGoalCelebrationIfNeeded(
    UserProgress progress,
  ) async {
    if (!mounted || !progress.shouldCelebrateDailyGoal) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily Goal Completed!')),
    );

    try {
      final updatedProgress = await FirestoreService().markDailyGoalCelebrated();
      if (!mounted) return;
      setState(() {
        userProgress = updatedProgress;
      });
    } catch (_) {}
  }

  Widget _buildDailyGoalCard(UserProgress progress) {
    final dailyGoal = progress.effectiveDailyGoal;
    final progressValue = (progress.todayXp / dailyGoal).clamp(0.0, 1.0);
    final percent = (progressValue * 100).round();
    final isCompleted = progress.todayXp >= dailyGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEAF8E5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF58CC02) : Colors.grey.shade300,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.flag,
                color: isCompleted ? const Color(0xFF58CC02) : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCompleted ? 'Daily Goal Completed!' : 'Daily Goal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: isCompleted
                      ? const Color(0xFF58CC02)
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${progress.todayXp} / $dailyGoal XP'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue.toDouble(),
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF58CC02) : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpProgressCard(UserProgress progress) {
    final currentLevel = UserProgress.calculateLevel(progress.xp);
    final currentLevelXp = progress.getXpForCurrentLevel();
    final nextLevelXp = progress.getXpForNextLevel();
    final levelProgress = progress.getCurrentLevelProgress();
    final levelRange = nextLevelXp - currentLevelXp;
    final progressValue = progress.getProgressPercentage().clamp(0.0, 1.0);
    final percent = (progressValue * 100).round();
    final remainingXp = progress.getXpNeededForNextLevel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1CB0F6), Color(0xFF84D8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Level $currentLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.xp} / $nextLevelXp XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressValue.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor: Colors.white.withAlpha(80),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '$levelProgress / $levelRange XP this level - $remainingXp XP to Level ${currentLevel + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartsCard(UserProgress progress) {
    final maxHearts = progress.maxHearts <= 0
        ? UserProgress.defaultMaxHearts
        : progress.maxHearts;
    final hearts = progress.hearts.clamp(0, maxHearts).toInt();
    final isFull = hearts >= maxHearts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hearts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$hearts / $maxHearts',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(maxHearts, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  index < hearts ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 22,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(isFull ? 'Full hearts' : progress.getHeartRefillText()),
        ],
      ),
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Email: ${authProvider.user?.email ?? 'N/A'}'),
          const SizedBox(height: 16),
          Text('Total Words: ${wordProvider.words.length}'),
          const SizedBox(height: 16),
          if (userProgress != null) ...[
            _buildHeartsCard(userProgress!),
            const SizedBox(height: 16),
            _buildDailyGoalCard(userProgress!),
            const SizedBox(height: 16),
            _buildXpProgressCard(userProgress!),
            const SizedBox(height: 16),
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
