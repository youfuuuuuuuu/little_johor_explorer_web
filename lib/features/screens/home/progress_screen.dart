import 'dart:ui';
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
    final points = storage.getPoints();
    final readingTime = storage.getTotalReadingTime();

    final readStoryIds = storage.getReadStoryIds();
    final int totalStoriesRead = readStoryIds.length;

    final List<Map<String, dynamic>> badgeMilestones = [
      {'id': 'newbie', 'label': 'Newbie', 'icon': '📖', 'threshold': 1},
      {'id': 'curious', 'label': 'Curious', 'icon': '🔍', 'threshold': 3},
      {
        'id': 'storyteller',
        'label': 'Storyteller',
        'icon': '🗣️',
        'threshold': 5
      },
      {
        'id': 'adventurer',
        'label': 'Adventurer',
        'icon': '🎒',
        'threshold': 10
      },
      {'id': 'expert', 'label': 'Johor Expert', 'icon': '🌟', 'threshold': 15},
      {'id': 'legend', 'label': 'Legend', 'icon': '👑', 'threshold': 20},
    ];

    final int earnedBadgesCount = badgeMilestones
        .where((badge) => totalStoriesRead >= (badge['threshold'] as int))
        .length;

    final List<String> recentEventsFirst = history
        .map((item) => item.toString())
        .where((item) => item.startsWith("Read:"))
        .map((item) => item.replaceFirst("Read:", "").trim())
        .toList();

    List<String> top10UniqueTitles = [];
    for (String title in recentEventsFirst) {
      if (!top10UniqueTitles.contains(title)) {
        top10UniqueTitles.add(title);
      }
      if (top10UniqueTitles.length == 10) break;
    }

    final List<Story> readingActivities = top10UniqueTitles
        .map((title) => _findStoryByTitle(storyService.stories, title))
        .where((story) => story.id != 'temp')
        .toList();

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
                        value: '$earnedBadgesCount',
                        label: lang.translate('my_badges'),
                      )),
                    ],
                  ),
                ),
              ),
              _sectionHeader(lang.translate('my_badges')),
              SliverToBoxAdapter(
                child: _buildBadgeGrid(context, badgeMilestones,
                    totalStoriesRead, isLargeScreen, screenWidth),
              ),
              _sectionHeader(lang.currentLanguage == 'ms'
                  ? "Cerita Telah Dibaca"
                  : "Stories Read"),
              SliverToBoxAdapter(
                child: readingActivities.isEmpty
                    ? _emptySection(lang.translate('no_stories_read'))
                    : _verticalActivityList(context, readingActivities),
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

  Widget _buildBadgeGrid(
      BuildContext context,
      List<Map<String, dynamic>> badges,
      int totalStoriesRead,
      bool isLarge,
      double width) {
    final int visibleCount = isLarge ? 8 : 4;
    final double padding = 40.0;
    final double spacing = 10.0 * (visibleCount - 1);
    final double itemWidth = (width - padding - spacing) / visibleCount;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final threshold = badge['threshold'] as int;
            final isEarned = totalStoriesRead >= threshold;

            return Container(
              width: itemWidth,
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
                  Text(isEarned ? badge['icon'] : '🔒',
                      style: TextStyle(fontSize: isLarge ? 20 : 18)),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        badge['label'],
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isEarned ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  if (!isEarned)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$totalStoriesRead / $threshold',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _verticalActivityList(BuildContext context, List<Story> stories) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: _buildCoverImage(story.coverImageUrl),
              ),
            ),
            title: Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(String path) {
    final bg = Colors.blue.shade50;
    if (path.isEmpty) return Container(color: bg);
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: bg));
    }
    final clean = path.replaceFirst('file:///', '').replaceFirst('assets/', '');
    return Image.asset('assets/$clean',
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
      (s) => s.title.trim().toLowerCase() == title.trim().toLowerCase(),
      orElse: () => Story(
          id: 'temp',
          title: title,
          description: '',
          coverImageUrl: '',
          pages: []),
    );
  }
}
