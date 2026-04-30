import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/features/screens/admin/manage_story_screen.dart';
import 'package:little_johor_explorer/features/screens/admin/manage_quiz_screen.dart';
import 'package:little_johor_explorer/data/models/story.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  final List<String> _selectedThemes = [];
  final List<String> _selectedDistricts = [];
  bool _isSortingMode = false;
  List<Story> _sortableStories = [];

  final List<String> _themes = ['History', 'Place', 'Food'];
  final List<String> _districts = [
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

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);
    final lang = Provider.of<LanguageService>(context);

    final filteredStories = storyService.stories.where((story) {
      final List<String> storyTags = (story.tags as List?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [];
      final String storyTitle = (story.title ?? "").toLowerCase();

      bool searchMatch = _searchQuery.isEmpty ||
          storyTitle.contains(_searchQuery.toLowerCase());
      bool themeMatch = _selectedThemes.isEmpty ||
          _selectedThemes.any((t) => storyTags.contains(t.toLowerCase()));
      bool districtMatch = _selectedDistricts.isEmpty ||
          _selectedDistricts.any((d) {
            String targetWithDash = d.toLowerCase().replaceAll(' ', '-');
            return storyTags.contains(targetWithDash) ||
                storyTags.contains(d.toLowerCase());
          });

      return searchMatch && themeMatch && districtMatch;
    }).toList();

    bool isFiltering = _searchQuery.isNotEmpty ||
        _selectedThemes.isNotEmpty ||
        _selectedDistricts.isNotEmpty;
    final displayList = _isSortingMode ? _sortableStories : filteredStories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(storyService),
            _buildSearchAndFilterBar(),
            if (_selectedThemes.isNotEmpty || _selectedDistricts.isNotEmpty)
              _buildActiveFilterChips(lang),
            if (_isSortingMode)
              _buildStatusBanner(
                isFiltering
                    ? "sorting disabled during filter"
                    : "drag handle to reorder",
                isFiltering ? Colors.orange : Colors.black54,
              ),
            Expanded(
              child: storyService.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: displayList.length,
                      buildDefaultDragHandles: _isSortingMode && !isFiltering,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final movedItem = _sortableStories.removeAt(oldIndex);
                          _sortableStories.insert(newIndex, movedItem);
                        });
                        storyService.updateStoriesOrder(
                            List<Story>.from(_sortableStories));
                      },
                      itemBuilder: (context, index) {
                        return _buildAdminCard(
                            displayList[index], isFiltering, storyService);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isSortingMode ? null : _buildDualFab(storyService),
    );
  }

  // --- UI Helper Methods (Inside the State Class) ---

  Widget _buildTopBar(StoryService storyService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            "admin panel",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -1.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSortingMode = !_isSortingMode;
                if (_isSortingMode) {
                  _searchQuery = '';
                  _selectedThemes.clear();
                  _selectedDistricts.clear();
                  _sortableStories = List<Story>.from(storyService.stories);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSortingMode ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Icon(
                _isSortingMode ? Icons.check_rounded : Icons.sort_rounded,
                color: _isSortingMode ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  if (v.isNotEmpty) _isSortingMode = false;
                }),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "search content...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.black54, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(LanguageService lang) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          ..._selectedThemes.map((t) => _filterChip(
              lang.translate(t.toLowerCase()),
              Colors.orange,
              () => setState(() => _selectedThemes.remove(t)))),
          ..._selectedDistricts.map((d) => _filterChip(d, Colors.lightBlue,
              () => setState(() => _selectedDistricts.remove(d)))),
        ],
      ),
    );
  }

  Widget _filterChip(String label, Color color, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        onDeleted: onDeleted,
        backgroundColor: color.withOpacity(0.1),
        shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
      ),
    );
  }

  Widget _buildAdminCard(Story story, bool isFiltering, StoryService service) {
    return Container(
      key: ValueKey(story.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _isSortingMode && !isFiltering
            ? const Icon(Icons.drag_handle_rounded, color: Colors.black26)
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFFF5F5F5),
                  child: story.coverImageUrl.startsWith('http')
                      ? Image.network(story.coverImageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.image_outlined,
                          color: Colors.grey, size: 20),
                ),
              ),
        title: Text(
          story.title ?? "untitled",
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
        ),
        subtitle: Text(
          "#${story.tags?.join(' #').toLowerCase()}",
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w500),
        ),
        trailing: _isSortingMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionIcon(
                      Icons.quiz_outlined,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ManageQuizScreen(story: story)))),
                  const SizedBox(width: 8),
                  _actionIcon(
                      Icons.edit_outlined,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ManageStoryScreen(existingStory: story)))),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.delete_outline_rounded,
                      () => _confirmDelete(context, story.id, service),
                      isDestructive: true),
                ],
              ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDestructive ? const Color(0xFFFFEBEB) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isDestructive ? Colors.red : Colors.black, size: 18),
      ),
    );
  }

  Widget _buildDualFab(StoryService storyService) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fabPart("quiz", Icons.add_task_rounded,
              () => _showStoryPickerForQuiz(context, storyService.stories)),
          Container(width: 1, height: 20, color: Colors.white24),
          _fabPart(
              "story",
              Icons.add_rounded,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ManageStoryScreen(
                          nextOrderIndex: storyService.stories.length)))),
        ],
      ),
    );
  }

  Widget _fabPart(String label, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label.toLowerCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildStatusBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toLowerCase(),
        textAlign: TextAlign.center,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showFilterDialog() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              const Text("Themes",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _themes
                    .map((t) => FilterChip(
                          label: Text(lang.translate(t.toLowerCase())),
                          selected: _selectedThemes.contains(t),
                          onSelected: (val) {
                            setState(() {
                              val
                                  ? _selectedThemes.add(t)
                                  : _selectedThemes.remove(t);
                              if (_selectedThemes.isNotEmpty)
                                _isSortingMode = false;
                            });
                            setDialogState(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder()),
                  child: const Text("Apply",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showStoryPickerForQuiz(BuildContext context, List<Story> stories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Select Story",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: stories.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.quiz_rounded, color: Colors.orange),
                  title: Text(stories[index].title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ManageQuizScreen(story: stories[index])));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String storyId, StoryService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Story?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content:
            const Text('Are you sure you want to remove this story forever?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.deleteStoryFromFirebase(storyId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
