import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../providers/word_provider.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _originalController = TextEditingController();
  final _translationController = TextEditingController();
  final _categoryController = TextEditingController();
  int _difficulty = 1;

  @override
  void dispose() {
    _originalController.dispose();
    _translationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveWord() async {
    if (_originalController.text.isEmpty ||
        _translationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final word = Word(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      original: _originalController.text.trim(),
      translation: _translationController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      difficulty: _difficulty,
      createdAt: DateTime.now(),
    );

    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    await wordProvider.addWord(word);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveWord),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _originalController,
              decoration: const InputDecoration(
                labelText: 'Original Word',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _translationController,
              decoration: const InputDecoration(
                labelText: 'Translation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Difficulty: '),
                Expanded(
                  child: Slider(
                    value: _difficulty.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _difficulty.toString(),
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
