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
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade100.withOpacity(0.5),
                  const Color(0xFFF8F9FE)
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
                    itemCount: _quizControllers.length,
                    itemBuilder: (context, index) => _buildQuestionCard(index),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange)),
          Expanded(
              child: Text("Edit Quiz: ${widget.story.title}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade900))),
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.remove_red_eye,
                color: Colors.orange),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _quizControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Soalan ${index + 1}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.orange)),
              IconButton(
                  onPressed: () =>
                      setState(() => _quizControllers.removeAt(index)),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent)),
            ],
          ),
          const Divider(),
          _buildTextField(q['questionMs'], 'Soalan (BM)', Icons.help_outline),
          const SizedBox(height: 12),
          _buildTextField(
              q['hintMs'], 'Petunjuk (BM)', Icons.lightbulb_outline),
          const SizedBox(height: 20),
          const Text("Gambar Soalan (Optional)",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          ImageUploadBox(
            imageUrl: q['qImage'],
            isUploading: q['isUploading'],
            onTap: () => _onUploadQuestionImage(index),
            label: "Upload Question Image",
          ),
          const SizedBox(height: 25),
          const Text("Pilihan Jawapan",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.indigo)),
          const Text("Pilih butang bulat untuk menandakan jawapan yang betul.",
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          ...List.generate(4, (i) {
            bool isCorrect = q['correctIndex'] == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: isCorrect
                        ? Colors.green.shade300
                        : Colors.grey.shade200,
                    width: isCorrect ? 2 : 1),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: q['correctIndex'],
                    activeColor: Colors.green,
                    onChanged: (int? value) => setState(() {
                      q['correctIndex'] = value;
                      q['userSelectedIndex'] = value;
                    }),
                  ),
                  Expanded(
                    child: TextField(
                      controller: q['answersMs'][i],
                      decoration: const InputDecoration(
                          hintText: "Pilihan",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_isPreviewMode) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
            _buildReviewResult(index),
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.orange),
        filled: true,
        fillColor: Colors.orange.withOpacity(0.03),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _btnHeight,
              child: ElevatedButton.icon(
                onPressed: () => _addQuizField(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Question", style: _btnTextStyle),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_btnRadius))),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: _btnHeight,
                    child: CustomButton(
                        text: "Save Changes", onPressed: _saveQuiz)),
          ),
        ],
      ),
    );
  }
}
