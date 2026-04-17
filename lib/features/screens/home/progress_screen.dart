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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final history = storage.getHistory();
    final earnedBadges = storage.getEarnedBadgeIds();
    final readingActivities = history
        .where((item) => item.contains("Read:"))
        .toList()
        .reversed
        .take(10)
        .map((item) {
      final title = item.replaceFirst("Read:", "").trim();
      return {
        'story': _findStoryByTitle(storyService.stories, title),
        'points': 10
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
        'points': 10
      };
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          lang.translate('my_progress'),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade100.withOpacity(0.5),
                  const Color(0xFFF8F9FE)
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
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                    child: _buildLevelHeader(storage.getPoints(), lang),
                  ),
                ),
                _buildSectionTitle(lang.translate('my_achievements')),
                SliverToBoxAdapter(
                  child: _buildHorizontalBadgeList(earnedBadges),
                ),
                _buildSectionTitle(lang.currentLanguage == 'ms'
                    ? "Cerita Telah Dibaca"
                    : "Stories Taken"),
                SliverToBoxAdapter(
                  child:
                      _buildSingleRowScrollList(readingActivities, false, lang),
                ),
                _buildSectionTitle(lang.currentLanguage == 'ms'
                    ? "Kuiz Telah Diambil"
                    : "Quizzes Taken"),
                SliverToBoxAdapter(
                  child: _buildSingleRowScrollList(quizActivities, true, lang),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleRowScrollList(
      List<Map<String, dynamic>> items, bool isQuiz, LanguageService lang) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildNoResultsView(isQuiz
            ? lang.translate('no_quizzes_taken')
            : lang.translate('no_stories_read')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        bool isLargeScreen = screenWidth > 600;

        int crossAxisCount = isLargeScreen ? 4 : 2;
        double spacing = 16.0;
        double totalPadding = 48.0;
        double containerHeight = isLargeScreen ? 450 : 250;
        double cardWidth =
            (screenWidth - totalPadding - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        return SizedBox(
          height: containerHeight,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final activity = items[index];
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : spacing, bottom: 12),
                child: _buildActivityCard(context, activity['story'] as Story,
                    isQuiz, activity['points'] as int),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(
      BuildContext context, Story story, bool isQuiz, int points) {
    final String cleanPath = story.coverImageUrl.replaceFirst('file:///', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isQuiz ? Colors.orange : Colors.purple).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color:
                        isQuiz ? Colors.orange.shade50 : Colors.purple.shade50,
                    child: story.coverImageUrl.isNotEmpty
                        ? Image.asset(
                            cleanPath,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        : Icon(
                            isQuiz ? Icons.extension : Icons.auto_stories,
                            color: isQuiz
                                ? Colors.orange.shade200
                                : Colors.purple.shade200,
                            size: 32,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "+$points",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isQuiz ? Colors.orange : Colors.purple)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isQuiz ? "CHALLENGE" : "STORY",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: isQuiz
                            ? Colors.orange.shade800
                            : Colors.purple.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black)),
      ),
    );
  }

  Widget _buildLevelHeader(int points, LanguageService lang) {
    double progress = (points % 100) / 100;
    int level = (points / 100).floor() + 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(children: [
        Text(lang.translate('level').toUpperCase(),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("LEVEL $level",
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black)),
        const SizedBox(height: 15),
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                color: Colors.green)),
        const SizedBox(height: 10),
        Text("$points TOTAL EXP",
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 14)),
      ]),
    );
  }

  Widget _buildHorizontalBadgeList(List<String> earnedIds) {
    final districtIds = [
      'J.Bahru',
      'Muar',
      'K.Tinggi',
      'Kulai',
      'Pontian',
      'Mersing',
      'B.Pahat',
      'Segamat',
      'Tangkak',
      'Kluang'
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        bool isMobile = width <= 600;

        if (!isMobile) {
          int crossAxisCount = width > 900 ? 10 : 6;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: districtIds.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => _buildBadgeItem(
                districtIds[index], earnedIds.length > index, false),
          );
        }
        double itemWidth = (width - 48 - (10 * 3)) / 4;

        return SizedBox(
          height: 90,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: districtIds.length,
            itemBuilder: (context, index) {
              return Container(
                width: itemWidth,
                margin: EdgeInsets.only(
                    right: index == districtIds.length - 1 ? 0 : 10),
                child: _buildBadgeItem(
                    districtIds[index], earnedIds.length > index, true),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBadgeItem(String name, bool isEarned, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isEarned ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEarned ? Colors.amber : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isEarned
            ? [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 4)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            color: isEarned ? Colors.amber : Colors.purple.shade100,
            size: isMobile ? 24 : 20,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: isEarned ? Colors.black87 : Colors.purple.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(25)),
      child: Center(
          child: Text(message,
              style: TextStyle(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 13))),
    );
  }
}
