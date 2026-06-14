import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lesson_detail_screen.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No lessons available'));
          }

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            return _LessonsList(docs: docs, completedLessons: const {});
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, progressSnapshot) {
              final progressData = progressSnapshot.data?.data();
              final completedLessonsData = progressData?['completedLessons'];
              final completedLessons = completedLessonsData is List
                  ? completedLessonsData.whereType<String>().toSet()
                  : <String>{};

              return _LessonsList(
                docs: docs,
                completedLessons: completedLessons,
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonsList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Object?>> docs;
  final Set<String> completedLessons;

  const _LessonsList({required this.docs, required this.completedLessons});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString();
        final description = (data['description'] ?? '').toString();
        final isCompleted = completedLessons.contains(doc.id);
        final isUnlocked =
            index == 0 ||
            completedLessons.contains(docs[index - 1].id) ||
            isCompleted;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isUnlocked ? 1 : 0.55,
          child: Card(
            margin: EdgeInsets.zero,
            color: isUnlocked
                ? Theme.of(context).cardColor
                : colorScheme.surfaceContainerHighest,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              enabled: isUnlocked,
              leading: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF58CC02).withAlpha(isDark ? 46 : 28)
                      : isUnlocked
                      ? const Color(0xFF1CB0F6).withAlpha(isDark ? 46 : 28)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isUnlocked
                      ? Icons.play_arrow
                      : Icons.lock,
                  color: isCompleted
                      ? const Color(0xFF58CC02)
                      : isUnlocked
                      ? const Color(0xFF1CB0F6)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description.isNotEmpty) Text(description),
                  if (isCompleted)
                    const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isUnlocked)
                    Text(
                      'Complete previous lesson to unlock',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              trailing: Text(
                '#${index + 1}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: isUnlocked
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LessonDetailScreen(),
                          settings: RouteSettings(
                            arguments: {'id': doc.id, 'title': title},
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}
