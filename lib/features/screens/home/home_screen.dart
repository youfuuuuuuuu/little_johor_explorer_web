import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/features/screens/admin/admin_dashboard_screen.dart';
import 'package:little_johor_explorer/features/screens/home/story_reader_screen.dart';
import 'package:little_johor_explorer/features/screens/home/category_quiz_screen.dart';
import 'package:little_johor_explorer/features/screens/parent/parent_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final List<String> _selectedThemes = [];
  final List<String> _selectedDistricts = [];
  bool _searchFocused = false;
  final FocusNode _searchFocus = FocusNode();

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
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);
    final lang = Provider.of<LanguageService>(context);
    final auth = Provider.of<AuthService>(context);

    final bool isParent = auth.currentUser?.role == 'parent';
    final bool isAdmin = auth.currentUser?.role == 'admin';
    final String userName = auth.currentUser?.displayName ?? 'Explorer';
    final String? avatarUrl =
        auth.currentUser?.avatarUrl?.replaceFirst('file:///', '');

    final filteredStories = storyService.stories.where((story) {
      final storyTags =
          story.tags.map((e) => e.toString().toLowerCase().trim()).toList();
      final storyTitle = story.title.toLowerCase();
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

    final quizStories =
        filteredStories.where((s) => s.quizQuestions.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lang.translate('hello')}, $userName 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.translate('let_explore'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Language toggle
                    GestureDetector(
                      onTap: () => lang.toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          lang.currentLanguage == 'en' ? '🇬🇧 EN' : '🇲🇾 BM',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF0F0F0),
                      backgroundImage:
                          avatarUrl != null ? AssetImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 20, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _searchFocused
                                ? const Color(0xFF0A0A0A)
                                : const Color(0xFFE8E8E8),
                            width: _searchFocused ? 1.5 : 1,
                          ),
                          boxShadow: _searchFocused
                              ? [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                              : [],
                        ),
                        child: TextField(
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: lang.translate('search_hint'),
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: Colors.grey.shade400, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        color: Colors.grey.shade400, size: 18),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter button
                    GestureDetector(
                      onTap: () => _showFilterSheet(lang),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (_selectedThemes.isNotEmpty ||
                                  _selectedDistricts.isNotEmpty)
                              ? const Color(0xFF0A0A0A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: (_selectedThemes.isNotEmpty ||
                                  _selectedDistricts.isNotEmpty)
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active filter chips ───────────────────────────────────────
            if (_selectedThemes.isNotEmpty || _selectedDistricts.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    children: [
                      ..._selectedThemes.map((t) => _filterPill(
                          lang.translate(t.toLowerCase()),
                          () => setState(() => _selectedThemes.remove(t)))),
                      ..._selectedDistricts.map((d) => _filterPill(d,
                          () => setState(() => _selectedDistricts.remove(d)))),
                    ],
                  ),
                ),
              ),

            // ── Role quick actions (between search and Featured Stories) ──
            if (isParent || isAdmin)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      if (isParent)
                        Expanded(
                            child: _roleButton(
                          context,
                          icon: Icons.shield_outlined,
                          label: lang.translate('dashboard'),
                          screen: const ParentDashboard(),
                          color: const Color(0xFF0A0A0A),
                        )),
                      if (isParent && isAdmin) const SizedBox(width: 10),
                      if (isAdmin)
                        Expanded(
                            child: _roleButton(
                          context,
                          icon: Icons.admin_panel_settings_outlined,
                          label: lang.translate('admin'),
                          screen: const AdminDashboardScreen(),
                          color: const Color(0xFF0A0A0A),
                        )),
                    ],
                  ),
                ),
              ),

            // ── Stories section ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search subtitle — only shown when searching, sits above title
                          if (_searchQuery.isNotEmpty) ...[
                            Text(
                              '${lang.translate('results_for')} "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0A0A0A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          // "Featured Stories" always visible
                          Text(
                            lang.translate('featured_stories'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${filteredStories.length} ${lang.currentLanguage == 'ms' ? 'cerita' : 'stories'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stories — horizontal scroll, 2 rows mobile / 4 rows web ──
            storyService.isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF0A0A0A)),
                      ),
                    ),
                  )
                : filteredStories.isEmpty
                    ? SliverToBoxAdapter(
                        child: _emptyState(lang.translate('no_stories_found')))
                    : SliverToBoxAdapter(
                        child: _horizontalStoryGrid(
                            context, filteredStories, false),
                      ),

            // ── Quizzes section header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.translate('adventure_quizzes'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${quizStories.length} ${lang.currentLanguage == 'ms' ? 'kuiz' : 'quizzes'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quizzes — same horizontal scroll layout ───────────────────
            quizStories.isEmpty
                ? SliverToBoxAdapter(
                    child: _emptyState(lang.translate('no_quizzes_found')))
                : SliverToBoxAdapter(
                    child: _horizontalStoryGrid(context, quizStories, true),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Horizontal scrollable grid ────────────────────────────────────────────
  //
  // Layout rules (both mobile and web/tab):
  //   • Top row fills first, bottom row fills with the remainder.
  //   • topCount  = ceil(total / 2)   e.g. 5 stories → top=3, bottom=2
  //   • bottomCount = floor(total / 2)
  //
  // Mobile  (width ≤ 600): visibleCols = 2
  //   • 5 stories  → top=[1,2,3]  bottom=[4,5]   → 3 columns, peek of col 3
  //   • 6 stories  → top=[1,2,3]  bottom=[4,5,6] → 3 columns, all visible
  //   • 8 stories  → top=[1,2,3,4] bottom=[5,6,7,8] → 4 columns, peek of col 3+4
  //
  // Web/Tab (width > 600): visibleCols = 4
  //   • 9 stories  → top=[1..5] bottom=[6..9] → 5 columns, peek of col 5
  //   • 10 stories → top=[1..5] bottom=[6..10] → 5 columns, peek of col 5
  //
  // Each column = 1 top card stacked above 1 bottom card (or empty if no pair).
  // Columns scroll horizontally.
  Widget _horizontalStoryGrid(
      BuildContext context, List<Story> stories, bool isQuiz) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenW = constraints.maxWidth;
        final bool isWide = screenW > 600;
        final int visibleCols = isWide ? 4 : 2;

        const double sidePad = 20.0;
        const double gap = 12.0;
        // Small peek to hint there are more cards off-screen
        const double peekWidth = 24.0;

        // Card width sized so exactly `visibleCols` fit, plus a peek
        final double availableW = screenW - sidePad - peekWidth;
        final double cardW = (availableW - gap * visibleCols) / visibleCols;
        final double cardH = cardW / 0.72;

        // Split into top row and bottom row.
        //
        // Rule: top row fills at least `visibleCols` items before bottom row
        // starts receiving any. After that, top and bottom grow together.
        //
        // Verified examples:
        //   mobile (2): 5→top=3,bot=2  6→3,3  8→4,4
        //   web    (4): 5→top=4,bot=1  6→4,2  8→4,4  9→5,4  10→5,5
        final int total = stories.length;
        final int ceilHalf = (total / 2).ceil();
        final int topCount = total <= visibleCols
            ? total
            : ceilHalf < visibleCols
                ? visibleCols
                : ceilHalf;
        final int bottomCount = total - topCount;

        // Number of columns = topCount (top row is always longer or equal)
        final int colCount = topCount;

        return SizedBox(
          height: cardH * 2 + gap,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: sidePad, right: sidePad),
            itemCount: colCount,
            itemBuilder: (context, colIndex) {
              // Top row: index 0 → topCount-1  (sequential left to right)
              final int topStoryIndex = colIndex;

              // Bottom row: index topCount → total-1
              final int bottomStoryIndex = topCount + colIndex;
              final bool hasBottom = bottomStoryIndex < total;

              return Container(
                width: cardW,
                margin:
                    EdgeInsets.only(right: colIndex == colCount - 1 ? 0 : gap),
                child: Column(
                  children: [
                    // Top card
                    SizedBox(
                      height: cardH,
                      child:
                          _storyCard(context, stories[topStoryIndex], isQuiz),
                    ),
                    SizedBox(height: gap),
                    // Bottom card — empty placeholder keeps row height consistent
                    SizedBox(
                      height: cardH,
                      child: hasBottom
                          ? _storyCard(
                              context, stories[bottomStoryIndex], isQuiz)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Story card ────────────────────────────────────────────────────────────
  Widget _storyCard(BuildContext context, Story story, bool isQuiz) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isQuiz ? const CategoryQuizScreen() : const StoryReaderScreen(),
          settings: RouteSettings(arguments: story),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(story.coverImageUrl,
                        isQuiz ? Colors.orange.shade50 : Colors.grey.shade50),
                    // Quiz badge overlay
                    if (isQuiz)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.quiz_rounded,
                                  size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text('QUIZ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          story.tags.isNotEmpty ? story.tags.first : 'Johor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isQuiz)
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Text(
                              '${story.estimatedReadingTime}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path, Color fallbackColor) {
    if (path.isEmpty) {
      return Container(
          color: fallbackColor,
          child: const Icon(Icons.image_outlined, color: Colors.grey));
    }
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              color: fallbackColor,
              child: const Icon(Icons.image_outlined, color: Colors.grey)));
    }
    final clean = path.replaceFirst('file:///', '').replaceFirst('assets/', '');
    return Image.asset('assets/$clean',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            color: fallbackColor,
            child: const Icon(Icons.image_outlined, color: Colors.grey)));
  }

  Widget _filterPill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 6, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _roleButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Widget screen,
      required Color color}) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(LanguageService lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.translate('filter_stories'),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A))),
                    if (_selectedThemes.isNotEmpty ||
                        _selectedDistricts.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedThemes.clear();
                            _selectedDistricts.clear();
                          });
                          setS(() {});
                        },
                        child: Text(lang.translate('clear_all'),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(lang.translate('themes'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _themes.map((t) {
                    final selected = _selectedThemes.contains(t);
                    return GestureDetector(
                      onTap: () {
                        setState(() => selected
                            ? _selectedThemes.remove(t)
                            : _selectedThemes.add(t));
                        setS(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              selected ? const Color(0xFF0A0A0A) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? const Color(0xFF0A0A0A)
                                  : const Color(0xFFE8E8E8)),
                        ),
                        child: Text(lang.translate(t.toLowerCase()),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(lang.translate('districts'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _districts.map((d) {
                    final selected = _selectedDistricts.contains(d);
                    return GestureDetector(
                      onTap: () {
                        setState(() => selected
                            ? _selectedDistricts.remove(d)
                            : _selectedDistricts.add(d));
                        setS(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              selected ? const Color(0xFF0A0A0A) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? const Color(0xFF0A0A0A)
                                  : const Color(0xFFE8E8E8)),
                        ),
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(lang.translate('apply'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
