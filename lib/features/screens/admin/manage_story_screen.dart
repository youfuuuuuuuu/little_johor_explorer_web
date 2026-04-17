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
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.deepPurple.shade100.withOpacity(0.5),
                    const Color(0xFFF8F9FE)
                  ]),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(isEditing),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionCard(
                                title: "Basic Info",
                                icon: Icons.info_outline,
                                child: Column(
                                  children: [
                                    _buildTextField(_titleController,
                                        'Story Title', Icons.title),
                                    const SizedBox(height: 15),
                                    _buildTextField(_descController,
                                        'Short Description', Icons.description,
                                        maxLines: 2),
                                    const SizedBox(height: 25),
                                    ImageUploadBox(
                                      imageUrl: _coverUrl,
                                      isUploading: _isUploadingCover,
                                      onTap: _onPickCoverImage,
                                      label: "Upload Story Cover",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),
                              _buildSectionCard(
                                title: "Tags & Categorization",
                                icon: Icons.local_offer_outlined,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Districts",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo)),
                                    const SizedBox(height: 8),
                                    _buildChipWrap(_districts,
                                        _selectedDistricts, Colors.indigo),
                                    const SizedBox(height: 20),
                                    const Text("Themes",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange)),
                                    const SizedBox(height: 8),
                                    _buildChipWrap(_availableThemes,
                                        _selectedThemes, Colors.orange),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),
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
          _buildBottomAction(isEditing),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.indigo)),
          Text(isEditing ? 'Edit Story' : 'Add New Story',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo.shade900)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.indigo, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildChipWrap(
      List<String> options, List<String> selectedList, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selectedList.contains(item);
        return FilterChip(
          label: Text(item,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12)),
          selected: isSelected,
          onSelected: (val) => setState(
              () => val ? selectedList.add(item) : selectedList.remove(item)),
          selectedColor: color,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white,
          shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.2))),
        );
      }).toList(),
    );
  }

  Widget _buildPagesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Story Content",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          TextButton.icon(
              onPressed: _addPageField,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Add Page"),
              style: TextButton.styleFrom(foregroundColor: Colors.indigo)),
        ],
      ),
    );
  }

  Widget _buildPageCard(int index, Map<String, dynamic> controllers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withOpacity(0.1))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 12,
                  child: Text("${index + 1}",
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white))),
              IconButton(
                  onPressed: () => _removePageField(index),
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 10),
          ImageUploadBox(
            imageUrl: controllers['imageUrl'],
            isUploading: controllers['isUploading'],
            onTap: () => _onPickPageImage(index),
            label: "Upload Page Image (Optional)",
          ),
          const SizedBox(height: 15),
          _buildTextField(
              controllers['textEn']!, 'Story Text Content', Icons.text_fields,
              maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isEditing) {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _isUploading
              ? const CircularProgressIndicator()
              : CustomButton(
                  text: isEditing ? "Save Changes" : "Create Story",
                  onPressed: _submitStory),
        ),
      ),
    );
  }
}
