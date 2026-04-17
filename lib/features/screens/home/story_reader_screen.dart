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
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();

  int _currentPage = 0;
  bool _isMuted = true;
  bool _isPlaying = false;
  Story? _story;

  late DateTime _startTime;
  bool _isSessionSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _initTTS();
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

    if (minutesSpent == 0 && duration.inSeconds >= 15) {
      minutesSpent = 1;
    }

    if (minutesSpent > 0) {
      try {
        final localStorage =
            Provider.of<LocalStorageService>(context, listen: false);
        await localStorage.addReadingTime(minutesSpent);
        debugPrint("⏱️ Session Saved: $minutesSpent min.");
      } catch (e) {
        debugPrint("❌ Error saving session: $e");
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
      if (_isMuted)
        _stopSpeaking();
      else
        _speakCurrentPage();
    });
  }

  Widget _buildSanitizedImage(String path) {
    if (path.isEmpty) return _buildErrorPlaceholder();

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
      );
    } else {
      final cleanPath =
          path.replaceFirst('file:///', '').replaceFirst('assets/', '');
      return Image.asset(
        'assets/$cleanPath',
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
          child:
              Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey)),
    );
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_story == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final lang = Provider.of<LanguageService>(context);
    final isLastPage = _currentPage == _story!.pages.length - 1;
    double progressRatio = (_currentPage + 1) / _story!.pages.length;
    int percentage = (progressRatio * 100).toInt();

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) _saveReadingSession();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.deepPurple.withOpacity(0.8),
                elevation: 0,
                centerTitle: true,
                title: Text(_story!.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progressRatio,
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    color: Colors.lightGreen,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 5),
                  Text("$percentage%",
                      style: TextStyle(
                          color: Colors.deepPurple.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _story!.pages.length,
                onPageChanged: (index) {
                  _stopSpeaking();
                  setState(() => _currentPage = index);
                  if (!_isMuted)
                    Future.delayed(
                        const Duration(milliseconds: 400), _speakCurrentPage);
                },
                itemBuilder: (context, index) {
                  final page = _story!.pages[index];
                  final displayText = lang.isMalay && page.textMs.isNotEmpty
                      ? page.textMs
                      : page.textEn;

                  return Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
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
                            child: _buildSanitizedImage(page.imageUrl),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                    fontSize: 18,
                                    height: 1.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade900),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circularNavBtn(
                      Icons.arrow_back_ios_new,
                      Colors.grey.shade100,
                      Colors.black54,
                      () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut),
                      _currentPage > 0),
                  GestureDetector(
                    onTap: _toggleMute,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _isMuted
                            ? LinearGradient(colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300
                              ])
                            : const LinearGradient(
                                colors: [Colors.deepPurple, Colors.indigo]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: _isMuted
                                  ? Colors.grey.shade600
                                  : Colors.white),
                          const SizedBox(width: 8),
                          Text(lang.isMalay ? "BACA" : "READ",
                              style: TextStyle(
                                  color: _isMuted
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  _circularNavBtn(
                      isLastPage ? Icons.done_all : Icons.arrow_forward_ios,
                      isLastPage ? Colors.greenAccent : Colors.blueAccent,
                      Colors.white,
                      isLastPage
                          ? () => _finishStory(lang)
                          : () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut),
                      true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularNavBtn(IconData icon, Color bg, Color iconCol,
      VoidCallback? action, bool visible) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: InkWell(
        onTap: visible ? action : null,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconCol, size: 20),
        ),
      ),
    );
  }
}
