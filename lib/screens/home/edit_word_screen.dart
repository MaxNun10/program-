import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../providers/word_provider.dart';

class EditWordScreen extends StatefulWidget {
  final Word word;

  const EditWordScreen({super.key, required this.word});

  @override
  State<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends State<EditWordScreen> {
  late final TextEditingController _originalController;
  late final TextEditingController _translationController;
  late final TextEditingController _categoryController;
  late int _difficulty;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _originalController = TextEditingController(text: widget.word.original);
    _translationController = TextEditingController(
      text: widget.word.translation,
    );
    _categoryController = TextEditingController(text: widget.word.category);
    _difficulty = widget.word.difficulty;
  }

  @override
  void dispose() {
    _originalController.dispose();
    _translationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _updateWord() async {
    if (_originalController.text.isEmpty ||
        _translationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedWord = widget.word.copyWith(
      original: _originalController.text.trim(),
      translation: _translationController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      difficulty: _difficulty,
    );

    final wordProvider = Provider.of<WordProvider>(context, listen: false);

    try {
      await wordProvider.updateWord(updatedWord);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update word: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Word'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _updateWord),
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
