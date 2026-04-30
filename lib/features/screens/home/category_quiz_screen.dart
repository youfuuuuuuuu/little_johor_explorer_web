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

class _CategoryQuizScreenState extends State<CategoryQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  bool _showReview = false;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _showHint = false;

  final Map<int, int> _userAnswers = {};
  late ConfettiController _confettiController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _animateToNext() {
    _slideController.reset();
    _fadeController.reset();
    _slideController.forward();
    _fadeController.forward();
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

    await Future.delayed(const Duration(milliseconds: 900));

    if (_currentQuestionIndex < total - 1) {
      if (mounted) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswered = false;
          _selectedAnswerIndex = null;
          _showHint = false;
        });
        _animateToNext();
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

  // ── Image helper ──────────────────────────────────────────────────────────
  Widget _buildImage(String path) {
    if (path.isEmpty) return _imagePlaceholder();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0A0A0A))),
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    final clean = path.replaceFirst('file:///', '').replaceFirst('assets/', '');
    return Image.asset('assets/$clean',
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder());
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Color(0xFFD0D0D0), size: 40),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Story story = ModalRoute.of(context)!.settings.arguments as Story;
    final lang = Provider.of<LanguageService>(context);
    final auth = Provider.of<AuthService>(context);
    final questions = story.quizQuestions;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Text('No questions available',
              style: TextStyle(color: Colors.grey.shade400)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────
          _showReview
              ? _buildReviewScreen(questions, lang)
              : _quizCompleted
                  ? _buildResultScreen(
                      lang,
                      questions.length,
                      auth.currentUser?.displayName ?? 'Explorer',
                    )
                  : _buildQuizScreen(story, questions, lang),

          // ── Confetti ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFF0A0A0A),
                Color(0xFF555555),
                Color(0xFFAAAAAA),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz screen ───────────────────────────────────────────────────────────
  Widget _buildQuizScreen(
      Story story, List<StoryQuizQuestion> questions, LanguageService lang) {
    final currentQ = questions[_currentQuestionIndex];
    final double progress = (_currentQuestionIndex + 1) / questions.length;

    return SafeArea(
      child: Column(
        children: [
          // ── App bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF0A0A0A), size: 22),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${lang.translate('question_label')} ${_currentQuestionIndex + 1} / ${questions.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_score pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          // ── Question + options ──────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question image
                      if (currentQ.qImage != null &&
                          currentQ.qImage!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: _buildImage(currentQ.qImage!),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Question text
                      Text(
                        currentQ.questionMs,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A0A0A),
                          height: 1.4,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Answer options
                      ...List.generate(
                        currentQ.answersMs.length,
                        (index) => _answerOption(
                          index: index,
                          text: currentQ.answersMs[index],
                          correctIndex: currentQ.correct,
                          onTap: () => _answer(
                            index,
                            currentQ.correct,
                            questions.length,
                            story.title,
                            story.tags.isNotEmpty ? story.tags.first : null,
                          ),
                        ),
                      ),

                      // Hint
                      _buildHintSection(currentQ.hintMs, lang),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Answer option ─────────────────────────────────────────────────────────
  Widget _answerOption({
    required int index,
    required String text,
    required int correctIndex,
    required VoidCallback onTap,
  }) {
    final bool isCorrect = index == correctIndex;
    final bool isSelected = _selectedAnswerIndex == index;

    // Determine visual state
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailingIcon;

    if (!_isAnswered) {
      bgColor = Colors.white;
      borderColor = const Color(0xFFE8E8E8);
      textColor = const Color(0xFF0A0A0A);
    } else if (isCorrect) {
      bgColor = const Color(0xFFF0FAF0);
      borderColor = const Color(0xFF22C55E);
      textColor = const Color(0xFF166534);
      trailingIcon = const Icon(Icons.check_circle_rounded,
          color: Color(0xFF22C55E), size: 20);
    } else if (isSelected) {
      bgColor = const Color(0xFFFFF0F0);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFF991B1B);
      trailingIcon =
          const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20);
    } else {
      bgColor = Colors.white;
      borderColor = const Color(0xFFE8E8E8);
      textColor = Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: _isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: _isAnswered && (isCorrect || isSelected) ? 1.5 : 1,
          ),
          boxShadow: !_isAnswered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _isAnswered && isCorrect
                    ? const Color(0xFF22C55E)
                    : _isAnswered && isSelected
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _isAnswered && (isCorrect || isSelected)
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Answer text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }

  // ── Hint section ──────────────────────────────────────────────────────────
  Widget _buildHintSection(String? hint, LanguageService lang) {
    if (hint == null || hint.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _showHint = !_showHint),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showHint
                      ? Icons.lightbulb_rounded
                      : Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: _showHint
                      ? const Color(0xFF0A0A0A)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  _showHint
                      ? lang.translate('hide_hint')
                      : lang.translate('show_hint'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _showHint
                        ? const Color(0xFF0A0A0A)
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showHint
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _showHint
              ? Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFF0A0A0A)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hint,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0A0A0A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  // ── Result screen ─────────────────────────────────────────────────────────
  Widget _buildResultScreen(LanguageService lang, int total, String userName) {
    final int pointsEarned = _score * 10;
    final double percent = _score / total;
    final bool isPerfect = percent == 1.0;
    final bool isGood = percent >= 0.7;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top close
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF0A0A0A), size: 22),
                padding: EdgeInsets.zero,
              ),
            ),
            const Spacer(),

            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Emoji
                  Text(
                    isPerfect
                        ? '🏆'
                        : isGood
                            ? '🎉'
                            : '💪',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${lang.translate('well_done')} $userName!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Score display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_score',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A0A0A),
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          ' / $total',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPerfect
                            ? const Color(0xFF22C55E)
                            : isGood
                                ? const Color(0xFF0A0A0A)
                                : Colors.grey.shade400,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Points badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+$pointsEarned XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showReview = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      lang.translate('review_answer'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A0A0A),
                      side: const BorderSide(color: Color(0xFFE8E8E8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      lang.translate('back_to_home'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Review screen ─────────────────────────────────────────────────────────
  Widget _buildReviewScreen(
      List<StoryQuizQuestion> questions, LanguageService lang) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _showReview = false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF0A0A0A), size: 18),
                ),
                Text(
                  lang.translate('review_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                // Summary pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_score / ${questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              itemCount: questions.length,
              itemBuilder: (context, i) {
                final q = questions[i];
                final userAnswerIdx = _userAnswers[i] ?? -1;
                final bool isCorrect = userAnswerIdx == q.correct;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF22C55E).withOpacity(0.3)
                          : const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Q number + status
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCorrect
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${lang.translate('question_label')} ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Question
                      Text(
                        q.questionMs,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Correct answer
                      _reviewAnswerRow(
                        label: lang.translate('correct_answer'),
                        text: q.answersMs[q.correct],
                        isCorrect: true,
                      ),
                      // User's wrong answer
                      if (!isCorrect && userAnswerIdx >= 0) ...[
                        const SizedBox(height: 6),
                        _reviewAnswerRow(
                          label: lang.translate('your_answer'),
                          text: q.answersMs[userAnswerIdx],
                          isCorrect: false,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewAnswerRow({
    required String label,
    required String text,
    required bool isCorrect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FAF0) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 16,
            color:
                isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCorrect
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCorrect
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
