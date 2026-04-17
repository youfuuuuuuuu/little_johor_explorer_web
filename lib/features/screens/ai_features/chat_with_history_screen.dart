import 'dart:async';
import 'dart:ui';
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
      setState(() {
        _sttLocale = lang.currentLanguage == 'ms' ? 'ms_MY' : 'en_US';
      });
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
          debugPrint("STT Status: $status");
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _recordDuration++);

      if ((_recordDuration == 30 || _recordDuration == 45) &&
          _recordDuration < 59) {
        _rebootMic();
      }

      if (_recordDuration >= 59) {
        _listen();
      }
    });
  }

  void _rebootMic() async {
    if (!_isListening) return;
    _lastFullText = _messageController.text;

    await _speech?.stop();
    await Future.delayed(const Duration(milliseconds: 300));

    if (_isListening) {
      _startSpeechEngine(isRestart: true);
    }
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
    if (mounted) {
      setState(() {
        _isListening = false;
        _recordDuration = 0;
      });
    }
  }

  void _toggleSttLocale() {
    setState(() {
      _sttLocale = _sttLocale == 'en_US' ? 'ms_MY' : 'en_US';
    });
  }

  void _setNewPrompts() {
    final shuffled = List<String>.from(_allPromptKeys)..shuffle();
    setState(() => _activePrompts = shuffled.take(5).toList());
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

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
                ? "Helo! Saya Mr. Knowledge. Ada apa-apa yang anda ingin tahu tentang Johor hari ini? Tanya saya apa sahaja!"
                : "Hello! I'm Mr. Knowledge. Is there anything you want to know about Johor today? Ask me anything!",
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
                : "An error occurred.",
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
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.translate('mr_knowledge'),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: () => _showClearChatDialog(lang),
          )
        ],
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
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      DateTime msgTime = msg['time'] is DateTime
                          ? msg['time']
                          : DateTime.now();
                      bool showDateDivider = false;
                      if (index == 0) {
                        showDateDivider = true;
                      } else {
                        DateTime prevTime =
                            _chatMessages[index - 1]['time'] is DateTime
                                ? _chatMessages[index - 1]['time']
                                : DateTime.now();
                        if (!_isSameDay(msgTime, prevTime)) {
                          showDateDivider = true;
                        }
                      }
                      return Column(
                        children: [
                          if (showDateDivider) _buildDateDivider(msgTime, lang),
                          _buildMessageRow(msg, lang),
                        ],
                      );
                    },
                  ),
                ),
                if (_isTyping) _buildTypingIndicator(lang),
                _buildQuickPrompts(lang),
                _buildInputSection(lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date, LanguageService lang) {
    String text;
    final now = DateTime.now();
    if (date.day == now.day) {
      text = lang.currentLanguage == 'ms' ? 'Hari ini' : 'Today';
    } else {
      text = DateFormat('d MMM yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade600)),
    );
  }

  Widget _buildMessageRow(Map<String, dynamic> msg, LanguageService lang) {
    bool isUser = msg['isUser'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(null),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(
                      "${msg['sender']} • ${DateFormat('h:mm a').format(msg['time'])}",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.bold)),
                ),
                MessageBubble(message: msg['text'], isUser: isUser),
              ],
            ),
          ),
          if (isUser) _buildAvatar(msg['avatar']),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    final String? cleanUrl = url?.replaceFirst('file:///', '');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: ClipOval(
        child: cleanUrl != null
            ? Image.asset(cleanUrl, fit: BoxFit.cover)
            : const Icon(Icons.smart_toy_rounded,
                color: Colors.orange, size: 24),
      ),
    );
  }

  Widget _buildTypingIndicator(LanguageService lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(children: [
        const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.orange)),
        const SizedBox(width: 8),
        Text(lang.translate('bot_thinking'),
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildQuickPrompts(LanguageService lang) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activePrompts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.purple.shade50),
            label: Text(lang.translate(_activePrompts[index]),
                style: const TextStyle(fontSize: 12, color: Colors.black)),
            onPressed: () =>
                _sendMessage(quickText: lang.translate(_activePrompts[index])),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(LanguageService lang) {
    return Column(
      children: [
        if (_isListening)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              const Icon(Icons.fiber_manual_record,
                  color: Colors.white, size: 12),
              const SizedBox(width: 8),
              Text(_sttLocale == 'en_US' ? "Recording..." : "Merakam...",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                  "${(_recordDuration % 60).toString().padLeft(2, '0')}s / 59s",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace')),
            ]),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isListening ? Colors.purple.shade100 : Colors.purple.shade100,
                const Color.fromARGB(255, 225, 190, 231)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: _isListening
                          ? Colors.redAccent.withOpacity(0.5)
                          : Colors.purple.shade50,
                      width: 1.5),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? "Speak now..."
                        : lang.translate('ask_hint'),
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!_isListening && _messageController.text.isEmpty)
              _btn(
                  onTap: _toggleSttLocale,
                  child: Text(_sttLocale == 'en_US' ? 'EN' : 'MS',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
            if (_messageController.text.isNotEmpty)
              _btn(
                  onTap: () => _sendMessage(),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                  color: Colors.purple.shade400),
            const SizedBox(width: 4),
            _btn(
                onTap: _listen,
                child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 22),
                color:
                    _isListening ? Colors.redAccent : Colors.orange.shade400),
          ]),
        ),
      ],
    );
  }

  Widget _btn(
      {required VoidCallback onTap,
      required Widget child,
      Color color = Colors.white}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: color == Colors.white
                  ? Border.all(color: Colors.purple.shade50)
                  : null),
          child: Center(child: child),
        ));
  }

  void _showClearChatDialog(LanguageService lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('clear_chat_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        content: Text(lang.translate('clear_chat_msg'),
            style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.translate('cancel'),
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                Provider.of<GeminiService>(context, listen: false).clearChat();
                setState(() => _chatMessages.clear());
                Navigator.pop(ctx);
              },
              child: Text(lang.translate('clear'),
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
