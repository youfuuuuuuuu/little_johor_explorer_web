import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:little_johor_explorer/data/services/gemini_service.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/core/widgets/message_bubble.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatWithHistoryScreen extends StatefulWidget {
  const ChatWithHistoryScreen({super.key});

  @override
  State<ChatWithHistoryScreen> createState() => _ChatWithHistoryScreenState();
}

class _ChatWithHistoryScreenState extends State<ChatWithHistoryScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  final List<Map<String, dynamic>> _chatMessages = [];

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _sttLocale = 'en_US';
  int _recordDuration = 0;
  Timer? _timer;
  String _lastFullText = "";

  final List<String> _allPromptKeys = [
    'prompt_1',
    'prompt_2',
    'prompt_3',
    'prompt_4',
    'prompt_5',
    'prompt_6',
    'prompt_7',
    'prompt_8',
    'prompt_9',
    'prompt_10'
  ];
  List<String> _activePrompts = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final lang = Provider.of<LanguageService>(context, listen: false);
      setState(
          () => _sttLocale = lang.currentLanguage == 'ms' ? 'ms_MY' : 'en_US');
      _initSpeech();
      _setNewPrompts();
      _loadExistingHistory();
    });
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      bool hasSpeech = await _speech!.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && _isListening) {
            _startSpeechEngine(isRestart: true);
          }
        },
        onError: (error) => debugPrint("STT Error: $error"),
      );
      if (mounted) setState(() => _speechEnabled = hasSpeech);
    } catch (e) {
      debugPrint("STT error: $e");
    }
  }

  void _startSpeechEngine({bool isRestart = false}) async {
    if (!_isListening || _speech == null) return;
    String existingText = _messageController.text;
    await _speech!.listen(
      onResult: (val) {
        if (mounted && val.recognizedWords.isNotEmpty) {
          setState(() {
            String newWords = val.recognizedWords;
            if (isRestart && !newWords.startsWith(existingText)) {
              _messageController.text = existingText + " " + newWords;
            } else {
              _messageController.text = newWords;
            }
            _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length));
          });
        }
      },
      listenMode: stt.ListenMode.dictation,
      localeId: _sttLocale,
      cancelOnError: false,
      partialResults: true,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 20),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recordDuration++);
      if ((_recordDuration == 30 || _recordDuration == 45) &&
          _recordDuration < 59) _rebootMic();
      if (_recordDuration >= 59) _listen();
    });
  }

  void _rebootMic() async {
    if (!_isListening) return;
    _lastFullText = _messageController.text;
    await _speech?.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isListening) _startSpeechEngine(isRestart: true);
  }

  void _listen() async {
    if (_speech == null) return;
    if (!_isListening) {
      bool available = await _speech!.initialize();
      if (available) {
        _messageController.clear();
        _lastFullText = "";
        setState(() => _isListening = true);
        _startTimer();
        _startSpeechEngine();
      }
    } else {
      setState(() => _isListening = false);
      _stopTimerAndListening();
      await _speech!.stop();
    }
  }

  void _stopTimerAndListening() {
    _timer?.cancel();
    if (mounted)
      setState(() {
        _isListening = false;
        _recordDuration = 0;
      });
  }

  void _toggleSttLocale() => setState(() {
        _sttLocale = _sttLocale == 'en_US' ? 'ms_MY' : 'en_US';
      });

  void _setNewPrompts() {
    final shuffled = List<String>.from(_allPromptKeys)..shuffle();
    setState(() => _activePrompts = shuffled.take(5).toList());
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _loadExistingHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final lang = Provider.of<LanguageService>(context, listen: false);
      final currentUser = authService.currentUser;
      geminiService.initUserSession(currentUser?.id ?? "unknown");
      _chatMessages.clear();

      if (geminiService.history.isNotEmpty) {
        setState(() {
          for (var msg in geminiService.history) {
            final isUser = msg.role == 'user';
            final text =
                msg.parts.whereType<TextPart>().map((e) => e.text).join();
            _chatMessages.add({
              'text': text,
              'isUser': isUser,
              'sender': isUser ? (currentUser?.displayName ?? "Me") : 'bot',
              'avatar': isUser ? currentUser?.avatarUrl : null,
              'time': DateTime.now(),
            });
          }
        });
      }

      if (_chatMessages.isEmpty) {
        setState(() {
          _chatMessages.add({
            'text': lang.currentLanguage == 'ms'
                ? "Helo! Saya Mr. Knowledge. Ada apa-apa yang anda ingin tahu tentang Johor hari ini?"
                : "Hello! I'm Mr. Knowledge. What would you like to explore about Johor today?",
            'isUser': false,
            'sender': 'bot',
            'avatar': null,
            'time': DateTime.now(),
          });
        });
      }
      _scrollToBottom();
    });
  }

  void _sendMessage({String? quickText}) async {
    final message = quickText ?? _messageController.text.trim();
    if (message.isEmpty) return;
    if (_isListening) {
      _speech?.stop();
      _stopTimerAndListening();
    }
    _messageController.clear();
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _chatMessages.add({
        'text': message,
        'isUser': true,
        'sender': authService.currentUser?.displayName ?? "Me",
        'avatar': authService.currentUser?.avatarUrl,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });
    _scrollToBottom();
    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final responseText = await geminiService
          .chatWithHistory(message)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'text': responseText,
            'isUser': false,
            'sender': 'bot',
            'avatar': null,
            'time': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        final lang = Provider.of<LanguageService>(context, listen: false);
        setState(() {
          _chatMessages.add({
            'text': lang.currentLanguage == 'ms'
                ? "Maaf, ralat berlaku."
                : "An error occurred. Please try again.",
            'isUser': false,
            'sender': 'bot',
            'avatar': null,
            'time': DateTime.now(),
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech?.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            // Bot avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('mr_knowledge'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(lang.translate('online'),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded,
                color: Colors.grey.shade500, size: 20),
            onPressed: () => _showClearDialog(lang),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Divider
          Container(height: 0.5, color: const Color(0xFFE8E8E8)),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                DateTime msgTime =
                    msg['time'] is DateTime ? msg['time'] : DateTime.now();
                bool showDate = false;
                if (index == 0) {
                  showDate = true;
                } else {
                  DateTime prevTime =
                      _chatMessages[index - 1]['time'] is DateTime
                          ? _chatMessages[index - 1]['time']
                          : DateTime.now();
                  if (!_isSameDay(msgTime, prevTime)) showDate = true;
                }
                return Column(
                  children: [
                    if (showDate) _dateDivider(msgTime, lang),
                    _messageRow(msg),
                  ],
                );
              },
            ),
          ),
          // Typing indicator
          if (_isTyping) _typingIndicator(lang),
          // Quick prompts
          _quickPrompts(lang),
          // Input
          _inputBar(lang),
        ],
      ),
    );
  }

  Widget _dateDivider(DateTime date, LanguageService lang) {
    final now = DateTime.now();
    String text = _isSameDay(date, now)
        ? (lang.currentLanguage == 'ms' ? 'Hari ini' : 'Today')
        : DateFormat('d MMM yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Container(height: 0.5, color: const Color(0xFFE8E8E8))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Container(height: 0.5, color: const Color(0xFFE8E8E8))),
        ],
      ),
    );
  }

  Widget _messageRow(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    final String? avatarUrl = msg['avatar']?.replaceFirst('file:///', '');
    final String timeStr = DateFormat('h:mm a').format(msg['time']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF0A0A0A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    msg['text'],
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF0A0A0A),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeStr,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage: avatarUrl != null ? AssetImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator(LanguageService lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A), shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _quickPrompts(LanguageService lang) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activePrompts.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () =>
              _sendMessage(quickText: lang.translate(_activePrompts[index])),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Text(
              lang.translate(_activePrompts[index]),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBar(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border:
            Border(top: BorderSide(color: const Color(0xFFE8E8E8), width: 0.5)),
      ),
      child: Column(
        children: [
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sttLocale == 'en_US' ? "Listening..." : "Mendengar...",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${_recordDuration}s / 59s',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade300,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _isListening
                            ? Colors.redAccent.withOpacity(0.4)
                            : const Color(0xFFE8E8E8)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? (_sttLocale == 'en_US'
                              ? "Speak now..."
                              : "Cakap sekarang...")
                          : lang.translate('ask_hint'),
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Language toggle (when idle)
              if (!_isListening && _messageController.text.isEmpty)
                _iconBtn(
                  onTap: _toggleSttLocale,
                  child: Text(
                    _sttLocale == 'en_US' ? 'EN' : 'MS',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A)),
                  ),
                  color: Colors.white,
                  border: true,
                ),
              // Send (when text entered)
              if (_messageController.text.isNotEmpty)
                _iconBtn(
                  onTap: () => _sendMessage(),
                  child: const Icon(Icons.arrow_right_alt_rounded,
                      color: Colors.white, size: 20),
                  color: const Color(0xFF0A0A0A),
                ),
              const SizedBox(width: 6),
              // Mic
              _iconBtn(
                onTap: _listen,
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                color:
                    _isListening ? Colors.redAccent : const Color(0xFF0A0A0A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required VoidCallback onTap,
    required Widget child,
    required Color color,
    bool border = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: border ? Border.all(color: const Color(0xFFE8E8E8)) : null,
          boxShadow: border
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Center(child: child),
      ),
    );
  }

  void _showClearDialog(LanguageService lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(lang.translate('clear_chat_title'),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0A0A0A))),
        content: Text(lang.translate('clear_chat_msg'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.translate('cancel'),
                  style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
              onPressed: () {
                Provider.of<GeminiService>(context, listen: false).clearChat();
                setState(() => _chatMessages.clear());
                Navigator.pop(ctx);
              },
              child: Text(lang.translate('clear'),
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
