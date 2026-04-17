import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/features/screens/admin/admin_dashboard_screen.dart';
import 'package:little_johor_explorer/features/screens/home/story_reader_screen.dart';
import 'package:little_johor_explorer/features/screens/home/category_quiz_screen.dart';
import 'package:little_johor_explorer/features/screens/parent/parent_dashboard.dart';
import 'package:little_johor_explorer/data/models/story.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final List<String> _selectedThemes = [];
  final List<String> _selectedDistricts = [];

  final List<String> _themes = ['History', 'Place', 'Food'];
  final List<String> _districts = [
    'Johor Bahru',
    'Kota Tinggi',
    'Muar',
    'Batu Pahat',
    'Mersing',
    'Segamat',
    'Tangkak',
    'Pontian',
    'Kluang',
    'Kulai'
  ];

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);
    final lang = Provider.of<LanguageService>(context);
    final auth = Provider.of<AuthService>(context);

    // ⭐️ This is where we define the roles!
    final bool isParent = auth.currentUser?.role == 'parent';
    final bool isAdmin = auth.currentUser?.role == 'admin';
    final String userName = auth.currentUser?.displayName ?? "Explorer";

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

    return LayoutBuilder(builder: (context, constraints) {
      bool isWeb = constraints.maxWidth > 800;
      int crossAxisCount = isWeb ? 4 : 2;
      double dynamicAspectRatio;

      if (isWeb) {
        double horizontalPadding = 48.0;
        double gridGap = 16.0 * (crossAxisCount - 1);
        double availableWidth =
            constraints.maxWidth - horizontalPadding - gridGap;
        double itemWidth = availableWidth / crossAxisCount;

        double targetHeight = 420.0;
        dynamicAspectRatio = itemWidth / targetHeight;
      } else {
        dynamicAspectRatio = 0.72;
      }

      return Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade100.withOpacity(0.5),
                    const Color(0xFFF8F9FE),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${lang.translate('hello')} $userName! 👋",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey.shade400)),
                                  Text(lang.translate('let_explore'),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black)),
                                ],
                              ),
                              _buildLanguageToggle(lang),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTopFilterBar(lang),
                        ],
                      ),
                    ),
                  ),

                  // ⭐️ Shows the button row if the user is a parent OR an admin
                  if (isParent || isAdmin)
                    SliverToBoxAdapter(
                        child: _buildRoleQuickActions(
                            context, lang, isParent, isAdmin)),

                  if (_selectedThemes.isNotEmpty ||
                      _selectedDistricts.isNotEmpty)
                    SliverToBoxAdapter(child: _buildActiveFilterChips(lang)),
                  _buildSectionTitle(
                      context,
                      lang,
                      _searchQuery.isEmpty
                          ? lang.translate('featured_stories')
                          : "${lang.translate('results_for')} '$_searchQuery'"),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: filteredStories.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildNoResultsView(
                                lang.translate('no_stories_found')))
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: dynamicAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildStoryCard(
                                  context, filteredStories[index], false),
                              childCount: filteredStories.length,
                            ),
                          ),
                  ),
                  _buildSectionTitle(
                      context, lang, lang.translate('adventure_quizzes')),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: filteredStories.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildNoResultsView(
                                lang.translate('no_quizzes_found')))
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: dynamicAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildStoryCard(
                                  context, filteredStories[index], true),
                              childCount: filteredStories.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSanitizedImage(String path) {
    if (path.isEmpty) {
      return Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported));
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      final cleanPath =
          path.replaceFirst('file:///', '').replaceFirst('assets/', '');
      return Image.asset(
        'assets/$cleanPath',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  Widget _buildSectionTitle(
      BuildContext context, LanguageService lang, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 15),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Story story, bool isQuiz) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isQuiz
                  ? const CategoryQuizScreen()
                  : const StoryReaderScreen(),
              settings: RouteSettings(arguments: story),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  color:
                      isQuiz ? Colors.orange.shade50 : Colors.lightBlue.shade50,
                  child: _buildSanitizedImage(story.coverImageUrl),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.blueGrey.shade800)),
                  const SizedBox(height: 2),
                  Text(story.tags.isNotEmpty ? story.tags.first : "Johor",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey.shade300,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService lang) {
    return GestureDetector(
      onTap: () => lang.toggleLanguage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blueGrey.shade50)),
        child: Text(lang.currentLanguage == 'en' ? '🇬🇧 EN' : '🇲🇾 BM',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildTopFilterBar(LanguageService lang) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: lang.translate('search_hint'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.black, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
              onPressed: () => _showFilterDialog(lang),
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.black, size: 20)),
        ],
      ),
    );
  }

  // ⭐️ This method safely builds the buttons based on role!
  Widget _buildRoleQuickActions(
      BuildContext context, LanguageService lang, bool isParent, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: Row(
        children: [
          if (isParent)
            _actionButton(
                context,
                Icons.dashboard_rounded,
                lang.translate('dashboard'),
                const ParentDashboard(),
                Colors.blue),
          if (isAdmin)
            _actionButton(
                context,
                Icons.admin_panel_settings_rounded,
                lang.translate(
                    'admin'), // ensure this is defined in translations
                const AdminDashboardScreen(),
                Colors.black),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label,
      Widget screen, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(LanguageService lang) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(top: 10),
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

  void _showFilterDialog(LanguageService lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('filter_stories'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Text(lang.translate('themes'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _themes
                      .map((t) => FilterChip(
                            label: Text(lang.translate(t.toLowerCase()),
                                style: const TextStyle(fontSize: 12)),
                            selected: _selectedThemes.contains(t),
                            selectedColor: Colors.orange.shade100,
                            checkmarkColor: Colors.orange,
                            onSelected: (val) {
                              setDialogState(() {
                                val
                                    ? _selectedThemes.add(t)
                                    : _selectedThemes.remove(t);
                              });
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 25),
                Text(lang.translate('districts'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _districts
                      .map((d) => FilterChip(
                            label:
                                Text(d, style: const TextStyle(fontSize: 12)),
                            selected: _selectedDistricts.contains(d),
                            selectedColor: Colors.lightBlue.shade100,
                            checkmarkColor: Colors.lightBlue,
                            onSelected: (val) {
                              setDialogState(() {
                                val
                                    ? _selectedDistricts.add(d)
                                    : _selectedDistricts.remove(d);
                              });
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(200, 45)),
                    child: Text(lang.translate('apply'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNoResultsView(String message) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.map_rounded, size: 50, color: Colors.blueGrey.shade100),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Colors.blueGrey.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
