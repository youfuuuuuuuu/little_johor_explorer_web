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
      backgroundColor: const Color(0xFFF0F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.blueGrey.shade800, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Admin Panel",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey.shade800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSortingMode = !_isSortingMode;
                        if (_isSortingMode) {
                          _searchQuery = '';
                          _selectedThemes.clear();
                          _selectedDistricts.clear();
                          _sortableStories = List<Story>.from(
                              Provider.of<StoryService>(context, listen: false)
                                  .stories);
                        } else {
                          _sortableStories = [];
                        }
                      });
                    },
                    icon: Icon(
                        _isSortingMode
                            ? Icons.check_circle_rounded
                            : Icons.sort_rounded,
                        color: _isSortingMode
                            ? Colors.green
                            : Colors.lightBlue.shade700,
                        size: 22),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white, elevation: 1),
                  ),
                ],
              ),
            ),
            _buildSearchAndFilterBar(),
            if (_selectedThemes.isNotEmpty || _selectedDistricts.isNotEmpty)
              _buildActiveFilterChips(lang),
            if (_isSortingMode && isFiltering)
              _buildStatusBanner(
                  "Sorting disabled while filters are active.", Colors.orange),
            if (_isSortingMode && !isFiltering)
              _buildStatusBanner(
                  "Hold and drag the handle on the right to reorder.",
                  Colors.lightBlue),
            Expanded(
              child: storyService.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: displayList.length,
                      buildDefaultDragHandles: _isSortingMode && !isFiltering,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final movedItem = _sortableStories.removeAt(oldIndex);
                          _sortableStories.insert(newIndex, movedItem);
                        });
                        Provider.of<StoryService>(context, listen: false)
                            .updateStoriesOrder(
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

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v;
                    if (v.isNotEmpty) _isSortingMode = false;
                  });
                },
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Search stories...",
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.lightBlue, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.all(12),
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
        shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.2))),
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
              Text("Filters",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade800)),
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
                          label: Text(lang.translate(t.toLowerCase()),
                              style: const TextStyle(fontSize: 12)),
                          selected: _selectedThemes.contains(t),
                          selectedColor: Colors.orange.shade50,
                          checkmarkColor: Colors.orange,
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
              const SizedBox(height: 20),
              const Text("Districts",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _districts
                    .map((d) => FilterChip(
                          label: Text(d, style: const TextStyle(fontSize: 12)),
                          selected: _selectedDistricts.contains(d),
                          selectedColor: Colors.lightBlue.shade50,
                          checkmarkColor: Colors.lightBlue,
                          onSelected: (val) {
                            setState(() {
                              val
                                  ? _selectedDistricts.add(d)
                                  : _selectedDistricts.remove(d);
                              if (_selectedDistricts.isNotEmpty)
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
                      backgroundColor: Colors.lightBlue.shade400,
                      shape: const StadiumBorder(),
                      elevation: 0),
                  child: const Text("Apply",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAdminCard(Story story, bool isFiltering, StoryService service) {
    return Container(
      key: ValueKey(story.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _isSortingMode && !isFiltering
            ? const Icon(Icons.drag_indicator, color: Colors.grey)
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: story.coverImageUrl.startsWith('http')
                      ? Image.network(
                          story.coverImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                          errorBuilder: (context, e, s) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.lightBlue.shade50,
                              shape: BoxShape.circle),
                          child: Icon(Icons.menu_book_rounded,
                              color: Colors.lightBlue.shade400, size: 20),
                        ),
                ),
              ),
        title: Text(story.title ?? "Untitled",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.blueGrey.shade800)),
        subtitle: Text("#${story.tags?.join(' #').toUpperCase()}",
            style: TextStyle(
                color: Colors.lightBlue.shade300,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        trailing: _isSortingMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _circleAction(
                      Icons.quiz_rounded,
                      Colors.orange,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ManageQuizScreen(story: story)))),
                  const SizedBox(width: 8),
                  _circleAction(
                      Icons.edit_rounded,
                      Colors.blue,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ManageStoryScreen(existingStory: story)))),
                  const SizedBox(width: 8),
                  _circleAction(Icons.delete_outline_rounded, Colors.redAccent,
                      () => _confirmDelete(context, story.id, service)),
                ],
              ),
      ),
    );
  }

  Widget _circleAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildStatusBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1))),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDualFab(StoryService storyService) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () =>
                _showStoryPickerForQuiz(context, storyService.stories),
            icon: const Icon(Icons.add_task_rounded,
                color: Colors.orange, size: 20),
            label: const Text("Quiz",
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 8)),
          TextButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageStoryScreen(
                        nextOrderIndex: storyService.stories.length))),
            icon: Icon(Icons.add_rounded,
                color: Colors.lightBlue.shade600, size: 22),
            label: Text("Story",
                style: TextStyle(
                    color: Colors.lightBlue.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
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
            Text("Select Story",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey.shade800)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: stories.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.quiz_rounded,
                      color: Colors.orange, size: 20),
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
                shape: const StadiumBorder(),
                elevation: 0),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
