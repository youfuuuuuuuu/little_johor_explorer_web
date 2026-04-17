import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:confetti/confetti.dart';

class CategoryQuizScreen extends StatefulWidget {
  const CategoryQuizScreen({super.key});

  @override
  State<CategoryQuizScreen> createState() => _CategoryQuizScreenState();
}

class _CategoryQuizScreenState extends State<CategoryQuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  bool _showReview = false;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _showHint = false;

  final Map<int, int> _userAnswers = {};
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _answer(
      int idx, int correct, int total, String storyTitle, String? tag) async {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _selectedAnswerIndex = idx;
      _userAnswers[_currentQuestionIndex] = idx;
      if (idx == correct) _score++;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (_currentQuestionIndex < total - 1) {
      if (mounted) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswered = false;
          _selectedAnswerIndex = null;
          _showHint = false;
        });
      }
    } else {
      _finishQuizLogic(storyTitle, total, tag);
    }
  }

  void _finishQuizLogic(String storyTitle, int total, String? tag) async {
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    int totalPointsEarned = _score * 10;
    final scorePercentage = (_score / total) * 100;
    setState(() => _quizCompleted = true);
    await storage.addPoints(totalPointsEarned, "Quiz: $storyTitle");

    if (scorePercentage == 100) {
      _confettiController.play();
      String badgeName =
          (tag != null) ? '${tag.toUpperCase()} Master' : '$storyTitle Master';
      if (!storage.getEarnedBadgeIds().contains(badgeName)) {
        await storage.awardBadge(badgeName);
      }
    }
  }

  Widget _buildBackgroundLayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade100.withOpacity(0.5),
            const Color(0xFFF8F9FE),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Story story = ModalRoute.of(context)!.settings.arguments as Story;
    final lang = Provider.of<LanguageService>(context);
    final auth = Provider.of<AuthService>(context);
    final questions = story.quizQuestions;

    if (questions.isEmpty) {
      return Scaffold(
          body: Center(child: Text(lang.translate('no_questions'))));
    }

    String appBarTitle = _showReview
        ? lang.translate('review_title')
        : (_quizCompleted ? lang.translate('quiz_completed') : story.title);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.deepPurple.withOpacity(0.8),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(
                    _showReview
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.close_rounded,
                    color: Colors.white),
                onPressed: () => _showReview
                    ? setState(() => _showReview = false)
                    : Navigator.pop(context),
              ),
              title: Text(appBarTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white)),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundLayer(),
          Positioned.fill(
            child: _showReview
                ? _buildReviewContent(questions, lang)
                : _quizCompleted
                    ? _buildResultContent(lang, questions.length,
                        auth.currentUser?.displayName ?? "Explorer")
                    : _buildQuizBody(story, questions, lang),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBody(
      Story story, List<StoryQuizQuestion> questions, LanguageService lang) {
    final currentQ = questions[_currentQuestionIndex];
    double progressRatio = (_currentQuestionIndex + 1) / questions.length;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProgressBar(progressRatio),
          if (currentQ.qImage != null && currentQ.qImage!.isNotEmpty)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildUniversalImage(currentQ.qImage!),
                ),
              ),
            ),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  Text(currentQ.questionMs,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900)),
                  const SizedBox(height: 24),
                  ...List.generate(
                      currentQ.answersMs.length,
                      (index) => _buildAnswerOption(
                          index, currentQ, questions.length, story)),
                  _buildHintSection(currentQ.hintMs, lang),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversalImage(String path) {
    if (path.isEmpty) return _buildErrorPlaceholder();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
      );
    } else {
      final cleanPath =
          path.replaceFirst('file:///', '').replaceFirst('assets/', '');
      return Image.asset('assets/$cleanPath',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder());
    }
  }

  Widget _buildErrorPlaceholder() => Container(
      color: Colors.grey.shade100,
      child: const Center(
          child:
              Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)));

  Widget _buildProgressBar(double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          color: Colors.lightGreen,
          minHeight: 8,
          borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildAnswerOption(
      int index, StoryQuizQuestion currentQ, int total, Story story) {
    bool isCorrect = index == currentQ.correct;
    bool isSelected = _selectedAnswerIndex == index;
    Color bgColor = _isAnswered
        ? (isCorrect
            ? Colors.green.shade50
            : (isSelected ? Colors.red.shade50 : Colors.white))
        : Colors.white;
    Color borderColor = _isAnswered
        ? (isCorrect
            ? Colors.green
            : (isSelected ? Colors.red : Colors.indigo.shade50))
        : Colors.indigo.shade50;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _answer(index, currentQ.correct, total, story.title,
            story.tags.isNotEmpty ? story.tags.first : null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2)),
          child: Row(children: [
            CircleAvatar(
                radius: 14,
                backgroundColor: Colors.deepPurple.shade50,
                child: Text(String.fromCharCode(65 + index),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple))),
            const SizedBox(width: 15),
            Expanded(
                child: Text(currentQ.answersMs[index],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15))),
            if (_isAnswered && isCorrect)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (_isAnswered && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Colors.red, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultContent(LanguageService lang, int total, String userName) {
    int pointsEarned = _score * 10;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 80, color: Colors.orange.shade400),
          const SizedBox(height: 20),
          Text("${lang.translate('well_done')}\n$userName!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo)),
          const SizedBox(height: 30),
          Text("$_score / $total",
              style:
                  const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
          Text("+$pointsEarned EXP",
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: () => setState(() => _showReview = true),
              child: Text(lang.translate('review_answer'))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('back_to_home'))),
        ],
      ),
    );
  }

  Widget _buildReviewContent(
      List<StoryQuizQuestion> questions, LanguageService lang) {
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
        itemCount: questions.length,
        itemBuilder: (context, i) {
          bool isCorrect = (_userAnswers[i] ?? -1) == questions[i].correct;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red),
              title: Text(questions[i].questionMs,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Answer: ${questions[i].answersMs[questions[i].correct]}"),
            ),
          );
        });
  }

  Widget _buildHintSection(String? hint, LanguageService lang) {
    if (hint == null || hint.isEmpty) return const SizedBox();
    return Column(
      children: [
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => setState(() => _showHint = !_showHint),
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(_showHint ? "Hide Hint" : "Show Hint"),
        ),
        if (_showHint)
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.orange))),
      ],
    );
  }
}
