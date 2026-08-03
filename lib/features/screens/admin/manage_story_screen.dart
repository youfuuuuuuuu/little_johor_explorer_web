import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';

class ManageStoryScreen extends StatefulWidget {
  final Story? existingStory;
  final int? nextOrderIndex;

  const ManageStoryScreen({
    super.key,
    this.existingStory,
    this.nextOrderIndex,
  });

  @override
  State<ManageStoryScreen> createState() => _ManageStoryScreenState();
}

class _ManageStoryScreenState extends State<ManageStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _coverUrlController = TextEditingController();

  final List<String> _selectedDistricts = [];
  final List<String> _selectedThemes = [];

  final List<String> _districts = [
    'Johor',
    'Johor Bahru',
    'Kota Tinggi',
    'Muar',
    'Kulai',
    'Pontian',
    'Mersing',
    'Kluang',
    'Segamat',
    'Batu Pahat',
    'Tangkak',
  ];
  final List<String> _availableThemes = ['History', 'Place', 'Food'];

  final List<Map<String, dynamic>> _pageControllers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingStory != null) {
      final s = widget.existingStory!;
      _titleController.text = s.title;
      _descController.text = s.description;
      _coverUrlController.text = s.coverImageUrl;

      for (var tag in s.tags) {
        if (_districts.contains(tag)) {
          _selectedDistricts.add(tag);
        } else if (_availableThemes.contains(tag)) {
          _selectedThemes.add(tag);
        }
      }

      for (var page in s.pages) {
        _pageControllers.add({
          'imageUrl': TextEditingController(text: page.imageUrl),
          'textMs': TextEditingController(
              text: page.textMs.isNotEmpty ? page.textMs : page.textEn),
        });
      }
    } else {
      _addPage();
    }
  }

  void _addPage() {
    setState(() {
      _pageControllers.add({
        'imageUrl': TextEditingController(),
        'textMs': TextEditingController(),
      });
    });
  }

  void _removePage(int index) =>
      setState(() => _pageControllers.removeAt(index));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _coverUrlController.dispose();
    for (var p in _pageControllers) {
      (p['imageUrl'] as TextEditingController).dispose();
      (p['textMs'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final storyService = Provider.of<StoryService>(context, listen: false);

      final List<String> combinedTags = [
        ..._selectedDistricts,
        ..._selectedThemes,
      ];

      final List<StoryPage> storyPages = _pageControllers.map((controllerMap) {
        final urlController =
            controllerMap['imageUrl'] as TextEditingController?;
        final msController = controllerMap['textMs'] as TextEditingController?;

        final String imageUrl = urlController?.text.trim() ?? '';
        final String textMs = msController?.text.trim() ?? '';

        return StoryPage(
          imageUrl: imageUrl,
          textEn: textMs,
          textMs: textMs,
        );
      }).toList();

      final int targetOrderIndex = widget.existingStory?.orderIndex ??
          widget.nextOrderIndex ??
          storyService.stories.length;

      final storyToSave = Story(
        id: widget.existingStory?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        coverImageUrl: _coverUrlController.text.trim(),
        tags: combinedTags,
        pages: storyPages,
        quizQuestions: widget.existingStory?.quizQuestions ?? [],
        orderIndex: targetOrderIndex,
      );

      final bool isSaveSuccessful = widget.existingStory == null
          ? await storyService.addStoryToFirebase(storyToSave)
          : await storyService.updateStoryInFirebase(storyToSave);

      if (!mounted) return;

      if (isSaveSuccessful) {
        _showSuccessSnackBar('Story saved successfully! 🎉');
        Navigator.pop(context);
      } else {
        _showError('Unable to complete save operation. Please try again.');
        debugPrint(
            '❌ Firebase operation returned false status indicator flag.');
      }
    } on FirebaseException catch (firebaseError) {
      debugPrint(
          "🔥 FIREBASE ERROR [${firebaseError.code}]: ${firebaseError.message}");
      if (mounted) {
        _showError("Database connection blocked: ${firebaseError.code}");
      }
    } catch (customException, stackTrace) {
      debugPrint("❌ UNEXPECTED APPLICATION CRASH: $customException");
      debugPrint("STACK TRACE: $stackTrace");
      if (mounted) {
        _showError('An unexpected operational error occurred.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0A0A0A), size: 18),
        ),
        title: Text(
          isEditing ? 'Edit Story' : 'Add New Story',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionCard(
                  title: 'Basic Info',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      _textField(
                        controller: _titleController,
                        label: 'Story Title',
                        icon: Icons.title_rounded,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _descController,
                        label: 'Short Description',
                        icon: Icons.description_outlined,
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _coverUrlController,
                        label: 'Cover Image Path (optional)',
                        icon: Icons.image_outlined,
                        hint: 'e.g. assets/images/johor/story_cover.png',
                      ),
                      if (_coverUrlController.text.trim().isNotEmpty)
                        _imagePreview(_coverUrlController.text.trim()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Tags & Categorization',
                  icon: Icons.local_offer_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Districts'),
                      const SizedBox(height: 10),
                      _chipWrap(_districts, _selectedDistricts,
                          const Color(0xFF0A0A0A)),
                      const SizedBox(height: 20),
                      _label('Themes'),
                      const SizedBox(height: 10),
                      _chipWrap(_availableThemes, _selectedThemes,
                          const Color(0xFF0A0A0A)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Story Pages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.3,
                        )),
                    GestureDetector(
                      onTap: _addPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Add Page',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._pageControllers
                    .asMap()
                    .entries
                    .map((e) => _pageCard(e.key, e.value)),
                const SizedBox(height: 30),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Story',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageCard(int index, Map<String, dynamic> p) {
    final imageCtrl = p['imageUrl'] as TextEditingController;
    final msCtrl = p['textMs'] as TextEditingController;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Page ${index + 1}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0A))),
                ],
              ),
              GestureDetector(
                onTap: () => _removePage(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _plainField(
            controller: imageCtrl,
            label: 'Image Path (optional)',
            hint: 'e.g. assets/images/johor/page1.png',
            icon: Icons.image_outlined,
            onChanged: (_) => setState(() {}),
          ),
          if (imageCtrl.text.trim().isNotEmpty)
            _imagePreview(imageCtrl.text.trim()),
          const SizedBox(height: 12),
          _plainField(
            controller: msCtrl,
            label: 'Story Text',
            hint: 'Enter the story page text here...',
            icon: Icons.text_fields_rounded,
            maxLines: 4,
          ),
        ],
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A))),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0A0A0A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
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

  Widget _plainField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
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
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A)));

  Widget _chipWrap(List<String> options, List<String> selected, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => setState(
              () => isSelected ? selected.remove(item) : selected.add(item)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? color : const Color(0xFFE8E8E8)),
            ),
            child: Text(item,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : const Color(0xFF0A0A0A))),
          ),
        );
      }).toList(),
    );
  }
}
