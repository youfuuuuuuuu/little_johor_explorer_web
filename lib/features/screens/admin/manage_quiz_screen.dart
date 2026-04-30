import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/core/widgets/custom_button.dart';
import 'package:little_johor_explorer/data/services/image_picker_service.dart';
import 'package:little_johor_explorer/core/widgets/image_upload_box.dart';

class ManageQuizScreen extends StatefulWidget {
  final Story story;
  const ManageQuizScreen({super.key, required this.story});

  @override
  State<ManageQuizScreen> createState() => _ManageQuizScreenState();
}

class _ManageQuizScreenState extends State<ManageQuizScreen> {
  final List<Map<String, dynamic>> _quizControllers = [];
  bool _isSaving = false;
  bool _isPreviewMode = false;
  final ImagePickerService _pickerService = ImagePickerService();

  static const double _btnHeight = 55.0;
  static const double _btnRadius = 15.0;
  static const TextStyle _btnTextStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);

  @override
  void initState() {
    super.initState();
    if (widget.story.quizQuestions.isNotEmpty) {
      for (var q in widget.story.quizQuestions) {
        _addQuizField(q);
      }
    } else {
      _addQuizField();
    }
  }

  void _addQuizField([StoryQuizQuestion? data]) {
    setState(() {
      _quizControllers.add({
        'questionMs': TextEditingController(text: data?.questionMs ?? ''),
        'hintMs': TextEditingController(text: data?.hintMs ?? ''),
        'qImage': data?.qImage ?? '',
        'isUploading': false,
        'correctIndex': data?.correct ?? 0,
        'userSelectedIndex': -1,
        'answersMs': List.generate(4, (i) {
          String initialText = "";
          if (data != null && data.answersMs.length > i)
            initialText = data.answersMs[i];
          return TextEditingController(text: initialText);
        }),
      });
    });
  }

  Widget _buildReviewResult(int index) {
    final q = _quizControllers[index];
    int correctIdx = q['correctIndex'];
    int selectedIdx = q['userSelectedIndex'];

    String getLetter(int i) => String.fromCharCode(65 + i);

    if (selectedIdx == -1) return const SizedBox.shrink();

    bool isCorrect = selectedIdx == correctIdx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("SEMAKAN JAWAPAN",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1.5)),
              ),
              Expanded(child: Divider(thickness: 1)),
            ],
          ),
        ),
        if (isCorrect)
          _resultTile(
            label: "Tahniah! Jawapan Tepat",
            text:
                "(${getLetter(selectedIdx)}) ${q['answersMs'][selectedIdx].text}",
            themeColor: Colors.green.shade600,
            icon: Icons.auto_awesome,
          )
        else
          Column(
            children: [
              _resultTile(
                label: "Pilihan Anda",
                text:
                    "(${getLetter(selectedIdx)}) ${q['answersMs'][selectedIdx].text}",
                themeColor: Colors.red.shade600,
                icon: Icons.close_rounded,
                isWrong: true,
              ),
              const SizedBox(height: 12),
              _resultTile(
                label: "Jawapan Sebenar",
                text:
                    "(${getLetter(correctIdx)}) ${q['answersMs'][correctIdx].text}",
                themeColor: Colors.indigo.shade600,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
      ],
    );
  }

  Widget _resultTile({
    required String label,
    required String text,
    required Color themeColor,
    required IconData icon,
    bool isWrong = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 70,
              color: themeColor.withOpacity(0.1),
              child: Icon(icon, color: themeColor, size: 28),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade900,
                        decoration: isWrong ? TextDecoration.lineThrough : null,
                        decorationColor: themeColor.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onUploadQuestionImage(int index) async {
    setState(() => _quizControllers[index]['isUploading'] = true);
    String? url =
        await _pickerService.pickAndUploadImage(folderName: 'quiz_images');
    if (url != null) {
      setState(() {
        _quizControllers[index]['qImage'] = url;
      });
    }
    setState(() => _quizControllers[index]['isUploading'] = false);
  }

  Future<void> _saveQuiz() async {
    setState(() => _isSaving = true);
    final List<StoryQuizQuestion> processedQuizData = _quizControllers.map((q) {
      return StoryQuizQuestion(
        questionMs: q['questionMs'].text.trim(),
        hintMs: q['hintMs'].text.trim(),
        qImage: q['qImage'],
        correct: q['correctIndex'],
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
      quizQuestions: processedQuizData,
    );

    final service = Provider.of<StoryService>(context, listen: false);
    bool success = await service.updateStoryInFirebase(updatedStory);

    if (mounted) setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Quiz Saved!"), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white for that Threads look
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: _quizControllers.length,
                itemBuilder: (context, index) => _buildQuestionCard(index),
              ),
            ),
          ],
        ),
      ),
      bottomSheet:
          _buildBottomAction(), // Using bottomSheet for a more fixed "Social Bar" feel
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "manage quiz",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  widget.story.title.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
          // Clean Toggle Button
          GestureDetector(
            onTap: () => setState(() => _isPreviewMode = !_isPreviewMode),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isPreviewMode ? Colors.black : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isPreviewMode ? Icons.edit_rounded : Icons.visibility_rounded,
                color: _isPreviewMode ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _quizControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFEEEEEE), width: 1), // Flat border logic
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "question ${index + 1}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _quizControllers.removeAt(index)),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 22),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledTextField(
                    q['questionMs'], 'soalan (bm)', Icons.help_outline_rounded),
                const SizedBox(height: 12),
                _buildStyledTextField(
                    q['hintMs'], 'petunjuk', Icons.lightbulb_outline_rounded),
                const SizedBox(height: 24),
                const Text("media asset (optional)",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54)),
                const SizedBox(height: 12),
                ImageUploadBox(
                  imageUrl: q['qImage'],
                  isUploading: q['isUploading'],
                  onTap: () => _onUploadQuestionImage(index),
                  label: "Upload Image",
                ),
                const SizedBox(height: 32),
                const Text("answer options",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54)),
                const SizedBox(height: 12),
                ...List.generate(4, (i) => _buildModernOption(index, i)),
                if (_isPreviewMode) ...[
                  const SizedBox(height: 20),
                  _buildReviewResult(index),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOption(int qIndex, int optionIndex) {
    final q = _quizControllers[qIndex];
    bool isSelected = q['correctIndex'] == optionIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Radio<int>(
            value: optionIndex,
            groupValue: q['correctIndex'],
            activeColor: Colors.white, // Inverted for selected state
            onChanged: (int? value) => setState(() {
              q['correctIndex'] = value;
              q['userSelectedIndex'] = value;
            }),
          ),
          Expanded(
            child: TextField(
              controller: q['answersMs'][optionIndex],
              style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400),
              decoration: const InputDecoration(
                hintText: "Enter option...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.black),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _addQuizField(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("add question",
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saveQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("save changes",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
