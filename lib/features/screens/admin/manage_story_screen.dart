import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/core/widgets/custom_button.dart';
import 'package:little_johor_explorer/data/services/image_picker_service.dart';
import 'package:little_johor_explorer/core/widgets/image_upload_box.dart';

class ManageStoryScreen extends StatefulWidget {
  final Story? existingStory;
  final int nextOrderIndex;

  const ManageStoryScreen(
      {super.key, this.existingStory, this.nextOrderIndex = 0});

  @override
  State<ManageStoryScreen> createState() => _ManageStoryScreenState();
}

class _ManageStoryScreenState extends State<ManageStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _coverUrl;
  final ImagePickerService _pickerService = ImagePickerService();
  bool _isUploadingCover = false;

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
    'Tangkak'
  ];
  final List<String> _availableThemes = ['History', 'Place', 'Food'];

  final List<Map<String, dynamic>> _pageControllers = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingStory != null) {
      _titleController.text = widget.existingStory!.title ?? '';
      _descController.text = widget.existingStory!.description ?? '';
      _coverUrl = widget.existingStory!.coverImageUrl;

      for (var tag in widget.existingStory!.tags ?? []) {
        if (_districts.contains(tag)) {
          _selectedDistricts.add(tag);
        } else if (_availableThemes.contains(tag)) {
          _selectedThemes.add(tag);
        }
      }

      for (var page in widget.existingStory!.pages ?? []) {
        _pageControllers.add({
          'imageUrl': page.imageUrl ?? '',
          'textEn': TextEditingController(text: page.textEn ?? ''),
          'isUploading': false,
        });
      }
    } else {
      _addPageField();
    }
  }

  void _addPageField() {
    setState(() {
      _pageControllers.add({
        'imageUrl': '',
        'textEn': TextEditingController(),
        'isUploading': false,
      });
    });
  }

  void _removePageField(int index) =>
      setState(() => _pageControllers.removeAt(index));

  Future<void> _onPickCoverImage() async {
    setState(() => _isUploadingCover = true);
    String? url =
        await _pickerService.pickAndUploadImage(folderName: 'story_covers');
    if (url != null) setState(() => _coverUrl = url);
    setState(() => _isUploadingCover = false);
  }

  Future<void> _onPickPageImage(int index) async {
    setState(() => _pageControllers[index]['isUploading'] = true);
    String? url =
        await _pickerService.pickAndUploadImage(folderName: 'story_pages');
    if (url != null) setState(() => _pageControllers[index]['imageUrl'] = url);
    setState(() => _pageControllers[index]['isUploading'] = false);
  }

  Future<void> _submitStory() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required text fields.');
      return;
    }

    if (_pageControllers.isEmpty) {
      _showError('Please add at least one story page.');
      return;
    }

    if (_coverUrl == null || _coverUrl!.isEmpty) {
      _showError('Please upload a Cover Image.');
      return;
    }

    if (_selectedDistricts.isEmpty) {
      _showError('Please select at least one District.');
      return;
    }
    if (_selectedThemes.isEmpty) {
      _showError('Please select at least one Theme.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> finalTags = [..._selectedDistricts, ..._selectedThemes];
      List<StoryPage> pages = _pageControllers.map((controllers) {
        return StoryPage(
          imageUrl: controllers['imageUrl'] ?? '',
          textEn: controllers['textEn']!.text.trim(),
          textMs: '',
        );
      }).toList();

      final storyToSave = Story(
        id: widget.existingStory?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        coverImageUrl: _coverUrl!,
        tags: finalTags,
        pages: pages,
        quizQuestions: widget.existingStory?.quizQuestions ?? [],
        orderIndex: widget.existingStory?.orderIndex ?? widget.nextOrderIndex,
      );

      final service = Provider.of<StoryService>(context, listen: false);
      bool success = widget.existingStory == null
          ? await service.addStoryToFirebase(storyToSave)
          : await service.updateStoryInFirebase(storyToSave);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Story Saved Successfully! 🎉'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        _showError(
            'Failed to save to database. Please check your connection or permissions.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showError('An unexpected error occurred: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var controllers in _pageControllers) {
      controllers['textEn']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStory != null;

    return Scaffold(
      backgroundColor: Colors.white, // Pure white for that Threads look
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isEditing),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("basic information"),
                          _buildTextField(_titleController, 'story title',
                              Icons.title_rounded),
                          const SizedBox(height: 16),
                          _buildTextField(_descController, 'short description',
                              Icons.description_rounded,
                              maxLines: 2),
                          const SizedBox(height: 24),
                          _buildSectionTitle("cover image"),
                          ImageUploadBox(
                            imageUrl: _coverUrl,
                            isUploading: _isUploadingCover,
                            onTap: _onPickCoverImage,
                            label: "Upload Story Cover",
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("tags & category"),
                          const Text("districts",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54)),
                          const SizedBox(height: 12),
                          _buildChipWrap(_districts, _selectedDistricts),
                          const SizedBox(height: 24),
                          const Text("themes",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54)),
                          const SizedBox(height: 12),
                          _buildChipWrap(_availableThemes, _selectedThemes),
                          const SizedBox(height: 40),
                          _buildPagesHeader(),
                          ..._pageControllers.asMap().entries.map((entry) =>
                              _buildPageCard(entry.key, entry.value)),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(isEditing),
    );
  }

  Widget _buildAppBar(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 4),
          Text(
            isEditing ? 'edit story' : 'add new story',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toLowerCase(),
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.2),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.black),
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
      validator: (val) => val == null || val.trim().isEmpty ? 'required' : null,
    );
  }

  Widget _buildChipWrap(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selectedList.contains(item);
        return FilterChip(
          label: Text(item.toLowerCase(),
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
          selected: isSelected,
          onSelected: (val) => setState(
              () => val ? selectedList.add(item) : selectedList.remove(item)),
          selectedColor: Colors.black,
          checkmarkColor: Colors.white,
          backgroundColor: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: isSelected ? Colors.black : const Color(0xFFEEEEEE)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPagesHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("story content",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          GestureDetector(
            onTap: _addPageField,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16),
                  SizedBox(width: 4),
                  Text("add page",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageCard(int index, Map<String, dynamic> controllers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("page ${index + 1}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.black54)),
              IconButton(
                onPressed: () => _removePageField(index),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ImageUploadBox(
            imageUrl: controllers['imageUrl'],
            isUploading: controllers['isUploading'],
            onTap: () => _onPickPageImage(index),
            label: "Upload Page Image",
          ),
          const SizedBox(height: 16),
          _buildTextField(
              controllers['textEn']!, 'content text', Icons.text_fields_rounded,
              maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isEditing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: _isUploading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2))
          : SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEditing ? "save changes" : "create story",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
    );
  }
}
