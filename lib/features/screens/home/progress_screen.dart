import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/models/story.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalStorageService>(context);
    final storyService = Provider.of<StoryService>(context);
    final lang = Provider.of<LanguageService>(context);

    if (storyService.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF0A0A0A))),
      );
    }

    final history = storage.getHistory();
    final earnedBadges = storage.getEarnedBadgeIds();
    final points = storage.getPoints();
    final readingTime = storage.getTotalReadingTime();

    final readingActivities = history
        .where((item) => item.contains("Read:"))
        .toList()
        .reversed
        .take(10)
        .map((item) {
      final title = item.replaceFirst("Read:", "").trim();
      return {
        'story': _findStoryByTitle(storyService.stories, title),
        'points': 10,
      };
    }).toList();

    final quizActivities = history
        .where((item) => item.contains("Quiz:"))
        .toList()
        .reversed
        .take(10)
        .map((item) {
      final title = item.replaceFirst("Quiz:", "").trim();
      return {
        'story': _findStoryByTitle(storyService.stories, title),
        'points': 10,
      };
    }).toList();

    final int level = (points / 100).floor() + 1;
    final double progress = (points % 100) / 100;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: LayoutBuilder(builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isLargeScreen = constraints.maxWidth > 800;

        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    lang.translate('my_progress'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Level card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                  lang.translate('level').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'LEVEL $level ${lang.translate('explorer').toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$points XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).toInt()}% to Level ${level + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stat Cards Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child: _statCard(
                        icon: Icons.bolt_rounded,
                        value: '$points',
                        label: lang.translate('total_points'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                        icon: Icons.schedule_rounded,
                        value: '$readingTime',
                        label: lang.translate('reading_time'),
                        suffix: 'min',
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                        icon: Icons.emoji_events_rounded,
                        value: '${earnedBadges.length}',
                        label: lang.translate('my_badges'),
                      )),
                    ],
                  ),
                ),
              ),

              // ── Badges Section (Show 8 on Web, 4 on Mobile) ────────────────
              _sectionHeader(lang.translate('my_badges')),
              SliverToBoxAdapter(
                child:
                    _buildBadgeGrid(earnedBadges, isLargeScreen, screenWidth),
              ),

              // ── Stories read (Dynamic 2/4) ────────────────────────────────
              _sectionHeader(lang.currentLanguage == 'ms'
                  ? "Cerita Telah Dibaca"
                  : "Stories Read"),
              SliverToBoxAdapter(
                child: readingActivities.isEmpty
                    ? _emptySection(lang.translate('no_stories_read'))
                    : _horizontalActivityList(context, readingActivities, false,
                        isLargeScreen, screenWidth),
              ),

              // ── Quizzes done (Dynamic 2/4) ────────────────────────────────
              _sectionHeader(lang.currentLanguage == 'ms'
                  ? "Kuiz Telah Diambil"
                  : "Quizzes Taken"),
              SliverToBoxAdapter(
                child: quizActivities.isEmpty
                    ? _emptySection(lang.translate('no_quizzes_taken'))
                    : _horizontalActivityList(context, quizActivities, true,
                        isLargeScreen, screenWidth),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        );
      }),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.5,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(suffix,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<String> earnedIds, bool isLarge, double width) {
    // Show 8 on Web/Tab, 4 on Mobile
    final int visibleCount = isLarge ? 8 : 4;
    final double padding = 40.0; // Left + Right padding
    final double spacing = 10.0 * (visibleCount - 1);
    final double itemWidth = (width - padding - spacing) / visibleCount;

    final List<Map<String, String>> badges = [
      {'id': 'first_discovery', 'label': 'First Read', 'icon': '📖'},
      {'id': 'JOHOR-BAHRU Master', 'label': 'J.Bahru', 'icon': '🏙️'},
      {'id': 'MUAR Master', 'label': 'Muar', 'icon': '🌊'},
      {'id': 'KOTA-TINGGI Master', 'label': 'K.Tinggi', 'icon': '⛰️'},
      {'id': 'KULAI Master', 'label': 'Kulai', 'icon': '🌿'},
      {'id': 'PONTIAN Master', 'label': 'Pontian', 'icon': '🐟'},
      {'id': 'MERSING Master', 'label': 'Mersing', 'icon': '🏝️'},
      {'id': 'BATU-PAHAT Master', 'label': 'B.Pahat', 'icon': '🏛️'},
      {'id': 'SEGAMAT Master', 'label': 'Segamat', 'icon': '🌾'},
      {'id': 'TANGKAK Master', 'label': 'Tangkak', 'icon': '🎋'},
      {'id': 'KLUANG Master', 'label': 'Kluang', 'icon': '☕'},
    ];

    return SizedBox(
      height: 100, // Slightly taller for stability
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isEarned = earnedIds.contains(badge['id']);
          return Container(
            width: itemWidth, // Calculated width
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isEarned ? const Color(0xFF0A0A0A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isEarned
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFF0F0F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isEarned ? badge['icon']! : '🔒',
                    style: TextStyle(fontSize: isLarge ? 20 : 18)),
                const SizedBox(height: 4),
                FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      badge['label']!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isEarned ? Colors.white : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _horizontalActivityList(
      BuildContext context,
      List<Map<String, dynamic>> items,
      bool isQuiz,
      bool isLarge,
      double width) {
    final int visibleCount = isLarge ? 4 : 2;
    final double padding = 40.0;
    final double spacing = 12.0 * (visibleCount - 1);
    final double itemWidth = (width - padding - spacing) / visibleCount;

    return SizedBox(
      height: isLarge ? 240 : 210, // Tall enough so web images don't clip
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final activity = items[index];
          final story = activity['story'] as Story;
          final points = activity['points'] as int;

          return Container(
            width: itemWidth,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3, // Give the image more relative space
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCoverImage(story.coverImageUrl, isQuiz),
                        _buildPointsBadge(points),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      _buildTag(isQuiz),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverImage(String path, bool isQuiz) {
    final bg = isQuiz ? Colors.orange.shade50 : Colors.grey.shade50;
    if (path.isEmpty) return Container(color: bg);
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: bg));
    }
    final clean = path.replaceFirst('file:///', '');
    return Image.asset(clean,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: bg));
  }

  Widget _emptySection(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Story _findStoryByTitle(List<Story> stories, String title) {
    return stories.firstWhere(
      (s) => s.title.trim().toLowerCase() == title.toLowerCase(),
      orElse: () => Story(
          id: 'temp',
          title: title,
          description: '',
          coverImageUrl: '',
          pages: []),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$points XP',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(bool isQuiz) {
    return Text(
      isQuiz ? 'Quiz' : 'Story',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
