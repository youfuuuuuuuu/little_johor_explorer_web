import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/data/services/local_storage_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/features/screens/home/category_quiz_screen.dart';

class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({super.key});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();

  int _currentPage = 0;
  bool _isMuted = true;
  bool _isPlaying = false;
  Story? _story;

  late DateTime _startTime;
  bool _isSessionSaved = false;

  // Animation for page transitions
  late AnimationController _pageAnimController;
  late Animation<double> _pageAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _initTTS();

    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageAnim =
        CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOut);
    _pageAnimController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveReadingSession();
    } else if (state == AppLifecycleState.resumed) {
      _startTime = DateTime.now();
      _isSessionSaved = false;
    }
  }

  Future<void> _saveReadingSession() async {
    if (_isSessionSaved) return;
    final now = DateTime.now();
    final duration = now.difference(_startTime);
    int minutesSpent = duration.inMinutes;
    if (minutesSpent == 0 && duration.inSeconds >= 15) minutesSpent = 1;
    if (minutesSpent > 0) {
      try {
        final localStorage =
            Provider.of<LocalStorageService>(context, listen: false);
        await localStorage.addReadingTime(minutesSpent);
      } catch (e) {
        debugPrint('Error saving session: $e');
      }
    }
    _isSessionSaved = true;
  }

  void _initTTS() async {
    await _flutterTts.setLanguage("ms-MY");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.1);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _story ??= ModalRoute.of(context)!.settings.arguments as Story;
  }

  void _speakCurrentPage() async {
    if (_isMuted || _story == null) return;
    setState(() => _isPlaying = true);
    final text = _story!.pages[_currentPage].textMs.isNotEmpty
        ? _story!.pages[_currentPage].textMs
        : _story!.pages[_currentPage].textEn;
    await _flutterTts.speak(text);
  }

  void _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _stopSpeaking();
      } else {
        _speakCurrentPage();
      }
    });
  }

  void _goToPage(int index) {
    _stopSpeaking();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    // Added fit parameter
    if (path.isEmpty) return _imagePlaceholder();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit, // Use the passed fit value
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0A0A0A))),
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    final clean = path.replaceFirst('file:///', '').replaceFirst('assets/', '');
    return Image.asset(
      'assets/$clean',
      fit: fit, // Use the passed fit value
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Color(0xFFD0D0D0), size: 48),
        ),
      );

  void _finishStory(LanguageService lang) async {
    _stopSpeaking();
    if (_story == null) return;
    await _saveReadingSession();
    final localStorage =
        Provider.of<LocalStorageService>(context, listen: false);
    await localStorage.markStoryAsRead(_story!.id, _story!.title);
    await localStorage.addPoints(10, "Read: ${_story!.title}");
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryQuizScreen(),
          settings: RouteSettings(arguments: _story),
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveReadingSession();
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    _pageController.dispose();
    _pageAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_story == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
      );
    }

    final lang = Provider.of<LanguageService>(context);
    final totalPages = _story!.pages.length;
    final isLastPage = _currentPage == totalPages - 1;
    final double progress = (_currentPage + 1) / totalPages;

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) _saveReadingSession();
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Threads-style clean white
        body: SafeArea(
          child: Column(
            children: [
              // ── App bar (Read Button Removed from here) ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _saveReadingSession();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _story!.title.toLowerCase(), // Modern lowercase
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${lang.translate('page')} ${_currentPage + 1} ${lang.translate('of')} $totalPages',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFF5F5F5),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.black),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pages ──────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalPages,
                  onPageChanged: (index) {
                    _stopSpeaking();
                    setState(() => _currentPage = index);
                    _pageAnimController.reset();
                    _pageAnimController.forward();
                    if (!_isMuted) {
                      Future.delayed(
                          const Duration(milliseconds: 300), _speakCurrentPage);
                    }
                  },
                  itemBuilder: (context, index) {
                    final page = _story!.pages[index];
                    final displayText = lang.isMalay && page.textMs.isNotEmpty
                        ? page.textMs
                        : page.textEn;

                    return FadeTransition(
                      opacity: index == _currentPage
                          ? _pageAnim
                          : kAlwaysCompleteAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          children: [
                            // ── Story image ──────────────────────────
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: const Color(0xFFEEEEEE),
                                            width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: _buildImage(
                                          page.imageUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ── Story text ───────────────────────────
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFEEEEEE)),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Text(
                                    displayText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Page dots ──────────────────────────────────────────────
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalPages > 7 ? 7 : totalPages,
                      (index) {
                        int dotPage = index;
                        if (totalPages > 7) {
                          final start =
                              (_currentPage - 3).clamp(0, totalPages - 7);
                          dotPage = start + index;
                        }
                        final bool isActive = dotPage == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.black
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ── Navigation bar with Centered BACA Button ─────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                ),
                child: Row(
                  children: [
                    // 1. Previous Button
                    Expanded(
                      child: _navButton(
                        onTap: _currentPage > 0
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        icon: Icons.arrow_back_rounded,
                        label: lang.translate('previous'),
                        enabled: _currentPage > 0,
                        filled: false,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 2. Center "READ/BACA" Toggle Button
                    GestureDetector(
                      onTap: _toggleMute,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50, // Matches height of nav buttons
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _isMuted ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isMuted
                                ? const Color(0xFFEEEEEE)
                                : Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 18,
                              color: _isMuted
                                  ? Colors.grey.shade400
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang.isMalay ? 'baca' : 'read',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _isMuted
                                    ? Colors.grey.shade400
                                    : Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 3. Next / Finish Button
                    Expanded(
                      child: _navButton(
                        onTap: isLastPage
                            ? () => _finishStory(lang)
                            : () => _goToPage(_currentPage + 1),
                        icon: isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        label: isLastPage
                            ? lang.translate('finish_story')
                            : lang.translate('next'),
                        enabled: true,
                        filled: true,
                        isFinish: isLastPage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required bool enabled,
    required bool filled,
    bool isFinish = false,
  }) {
    final Color bg = filled
        ? (isFinish ? const Color(0xFF22C55E) : Colors.black)
        : Colors.white;
    final Color fg =
        filled ? Colors.white : (enabled ? Colors.black : Colors.grey.shade300);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(
                  color: enabled
                      ? const Color(0xFFEEEEEE)
                      : const Color(0xFFF5F5F5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!filled) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6)
            ],
            Text(
              label.toLowerCase(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.2),
            ),
            if (filled) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: fg)
            ],
          ],
        ),
      ),
    );
  }

// Required for fade animation on non-current pages
  final Animation<double> kAlwaysCompleteAnimation =
      AlwaysStoppedAnimation<double>(1.0);
}
