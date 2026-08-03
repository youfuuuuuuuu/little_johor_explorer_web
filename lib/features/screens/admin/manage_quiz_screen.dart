import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';

class ManageQuizScreen extends StatefulWidget {
  final Story story;
  const ManageQuizScreen({super.key, required this.story});

  @override
  State<ManageQuizScreen> createState() => _ManageQuizScreenState();
}

class _ManageQuizScreenState extends State<ManageQuizScreen> {
  final List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.quizQuestions.isNotEmpty) {
      for (var q in widget.story.quizQuestions) {
        _addQuestion(existing: q);
      }
    } else {
      _addQuestion();
    }
  }

  void _addQuestion({StoryQuizQuestion? existing}) {
    setState(() {
      _questions.add({
        'questionMs': TextEditingController(text: existing?.questionMs ?? ''),
        'hintMs': TextEditingController(text: existing?.hintMs ?? ''),
        'qImage': TextEditingController(text: existing?.qImage ?? ''),
        'correctIndex': existing?.correct ?? 0,
        'answersMs': List.generate(4, (i) {
          final txt = (existing != null && existing.answersMs.length > i)
              ? existing.answersMs[i]
              : '';
          return TextEditingController(text: txt);
        }),
      });
    });
  }

  void _removeQuestion(int index) => setState(() => _questions.removeAt(index));

  @override
  void dispose() {
    for (var q in _questions) {
      (q['questionMs'] as TextEditingController).dispose();
      (q['hintMs'] as TextEditingController).dispose();
      (q['qImage'] as TextEditingController).dispose();
      for (var c in q['answersMs'] as List<TextEditingController>) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if ((q['questionMs'] as TextEditingController).text.trim().isEmpty) {
        _showError('Question ${i + 1} text is empty.');
        return;
      }
      final answers = q['answersMs'] as List<TextEditingController>;
      for (int j = 0; j < answers.length; j++) {
        if (answers[j].text.trim().isEmpty) {
          _showError(
              'Question ${i + 1}: Answer ${String.fromCharCode(65 + j)} is empty.');
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    final List<StoryQuizQuestion> processed = _questions.map((q) {
      return StoryQuizQuestion(
        questionMs: (q['questionMs'] as TextEditingController).text.trim(),
        hintMs: (q['hintMs'] as TextEditingController).text.trim(),
        qImage: (q['qImage'] as TextEditingController).text.trim(),
        correct: q['correctIndex'] as int,
        answersMs: (q['answersMs'] as List<TextEditingController>)
            .map((c) => c.text.trim())
            .toList(),
      );
    }).toList();

    final updatedStory = Story(
      id: widget.story.id,
      title: widget.story.title,
      description: widget.story.description,
      coverImageUrl: widget.story.coverImageUrl,
      pages: widget.story.pages,
      tags: widget.story.tags,
      orderIndex: widget.story.orderIndex,
      quizQuestions: processed,
    );

    final service = Provider.of<StoryService>(context, listen: false);
    final bool success = await service.updateStoryInFirebase(updatedStory);

    if (mounted) setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Quiz saved successfully!'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else if (mounted) {
      _showError('Failed to save. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF0A0A0A), size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Quiz',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          widget.story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isPreview = !_isPreview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            _isPreview ? const Color(0xFF0A0A0A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPreview
                                ? Icons.edit_rounded
                                : Icons.remove_red_eye_rounded,
                            size: 14,
                            color: _isPreview
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isPreview ? 'Edit' : 'Preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isPreview
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_questions.length} question${_questions.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) => _questionCard(index),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _addQuestion(),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 18, color: Color(0xFF0A0A0A)),
                      SizedBox(width: 6),
                      Text('Add Question',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0A))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Quiz',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int index) {
    final q = _questions[index];
    final questionCtrl = q['questionMs'] as TextEditingController;
    final hintCtrl = q['hintMs'] as TextEditingController;
    final imageCtrl = q['qImage'] as TextEditingController;
    final answers = q['answersMs'] as List<TextEditingController>;
    final int correctIndex = q['correctIndex'] as int;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        width: 750,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Question ${index + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A))),
                const Spacer(),
                GestureDetector(
                  onTap: () => _removeQuestion(index),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 15),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
            if (_isPreview) ...[
              _previewQuestion(index, q),
            ] else ...[
              _fieldLabel('Question Text'),
              const SizedBox(height: 6),
              _inputField(
                controller: questionCtrl,
                hint: 'Enter question...',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _fieldLabel('Hint (optional)'),
              const SizedBox(height: 6),
              _inputField(
                controller: hintCtrl,
                hint: 'Enter a hint...',
                icon: Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 10),
              _fieldLabel('Image Path (optional)'),
              const SizedBox(height: 6),
              _inputField(
                controller: imageCtrl,
                hint: 'e.g. assets/images/...',
                icon: Icons.image_outlined,
                onChanged: (_) => setState(() {}),
              ),
              if (imageCtrl.text.trim().isNotEmpty)
                _imagePreview(imageCtrl.text.trim()),
              const SizedBox(height: 14),
              _fieldLabel('Answer Options'),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final bool isCorrect = correctIndex == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFF0FAF0)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF22C55E).withOpacity(0.4)
                          : const Color(0xFFE8E8E8),
                      width: isCorrect ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => q['correctIndex'] = i),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect
                                  ? const Color(0xFF22C55E)
                                  : Colors.white,
                              border: Border.all(
                                color: isCorrect
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFD0D0D0),
                                width: 1.5,
                              ),
                            ),
                            child: isCorrect
                                ? const Icon(Icons.check_rounded,
                                    size: 11, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isCorrect
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: answers[i],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0A0A0A)),
                          decoration: InputDecoration(
                            hintText: 'Option ${String.fromCharCode(65 + i)}',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade300, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewQuestion(int index, Map<String, dynamic> q) {
    final questionCtrl = q['questionMs'] as TextEditingController;
    final hintCtrl = q['hintMs'] as TextEditingController;
    final imageCtrl = q['qImage'] as TextEditingController;
    final answers = q['answersMs'] as List<TextEditingController>;
    final int correctIndex = q['correctIndex'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageCtrl.text.trim().isNotEmpty)
          _imagePreview(imageCtrl.text.trim()),
        const SizedBox(height: 12),
        Text(
          questionCtrl.text.isEmpty
              ? '(No question text yet)'
              : questionCtrl.text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A0A0A),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (i) {
          final bool isCorrect = correctIndex == i;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFF0FAF0) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE8E8E8),
                width: isCorrect ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isCorrect ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answers[i].text.isEmpty ? '(empty)' : answers[i].text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCorrect
                          ? const Color(0xFF166534)
                          : const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
                if (isCorrect)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF22C55E), size: 18),
              ],
            ),
          );
        }),
        if (hintCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: Color(0xFF0A0A0A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hintCtrl.text,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0A0A0A), height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0A0A0A),
          letterSpacing: 0.1,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0A0A0A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: Colors.grey.shade400)
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _imagePreview(String path) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF5F5F5),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: path.startsWith('http')
                ? Image.network(
                    path,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _previewError(),
                  )
                : Image.asset(
                    path,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _previewError(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _previewError() => Container(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: Color(0xFFD0D0D0), size: 28),
              const SizedBox(height: 6),
              Text('Image not found',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
}
