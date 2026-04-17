import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/chat_service.dart';
import 'package:little_johor_explorer/data/models/chat_message.model.dart';
import 'package:little_johor_explorer/core/widgets/message_bubble.dart';
import 'package:little_johor_explorer/core/widgets/audio_message_bubble.dart';
import 'package:little_johor_explorer/data/models/user.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getRoomId(User? user) {
    if (user == null) return "unknown";
    if (user.role == 'parent') {
      return user.id;
    } else if (user is ChildProfile) {
      return user.parentId;
    }
    return "unknown";
  }

  String? _getLiveAvatar(String senderId, User? currentUser) {
    if (currentUser == null) return null;

    if (senderId == currentUser.id) {
      return currentUser.avatarUrl;
    }

    if (currentUser is ParentProfile) {
      try {
        return currentUser.children
            .firstWhere((child) => child.id == senderId)
            .avatarUrl;
      } catch (_) {}
    }

    if (currentUser is ChildProfile && senderId == currentUser.parentId) {}

    return null;
  }

  void _clearChat(String roomId, ChatService chatService, LanguageService lang,
      String currentUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(lang.translate('clear_chat_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(lang.translate('clear_chat_msg'),
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'),
                  style: const TextStyle(fontSize: 14))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await chatService.clearMessagesForUser(currentUserId);
              if (mounted) setState(() {});
            },
            child: Text(lang.translate('clear'),
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDateDividerText(DateTime date, LanguageService lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return lang.currentLanguage == 'ms' ? 'Hari ini' : 'Today';
    } else if (msgDate == yesterday) {
      return lang.currentLanguage == 'ms' ? 'Semalam' : 'Yesterday';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  Widget _buildDateDivider(DateTime date, LanguageService lang) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getDateDividerText(date, lang),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade600,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildChatAvatar(String? avatarUrl) {
    final String? cleanUrl = avatarUrl?.replaceFirst('file:///', '');
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ClipOval(
        child: cleanUrl != null
            ? Image.asset(
                cleanUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.face_rounded,
                    color: Colors.blueGrey.shade300,
                    size: 24),
              )
            : Icon(Icons.face_rounded,
                color: Colors.blueGrey.shade300, size: 24),
      ),
    );
  }

  Widget _buildRoleBadge(String role, LanguageService lang) {
    bool isParent = role == 'parent';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isParent ? Colors.teal.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isParent
            ? lang.translate('parent').toUpperCase()
            : lang.translate('child').toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: isParent ? Colors.teal.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final currentUser = authService.currentUser;

    final currentUserId = currentUser?.id ?? "unknown";
    final roomId = _getRoomId(currentUser);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lang.translate('family_title'),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black,
                letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded,
                color: Colors.redAccent, size: 24),
            tooltip: 'Clear Chat',
            onPressed: () =>
                _clearChat(roomId, chatService, lang, currentUserId),
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
                  const Color(0xFFF8F9FE),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<FamilyMessage>>(
                    stream: chatService.getMessages(roomId, currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.purple));
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.waving_hand_rounded,
                                  size: 60, color: Colors.purple.shade100),
                              const SizedBox(height: 16),
                              Text(lang.translate('family_no_messages'),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.purple.shade300,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          bool isMe = msg.senderId == currentUser?.id;
                          String senderRole =
                              (msg.senderId == roomId) ? 'parent' : 'child';

                          String? liveAvatar =
                              _getLiveAvatar(msg.senderId, currentUser) ??
                                  msg.avatarUrl;

                          bool showDateDivider = false;
                          if (index == messages.length - 1) {
                            showDateDivider = true;
                          } else {
                            final previousMsg = messages[index + 1];
                            showDateDivider = !_isSameDay(
                                msg.timestamp, previousMsg.timestamp);
                          }

                          String timeOnly =
                              DateFormat('h:mm a').format(msg.timestamp);

                          return Column(
                            children: [
                              if (showDateDivider)
                                _buildDateDivider(msg.timestamp, lang),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) _buildChatAvatar(liveAvatar),
                                    if (!isMe) const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isMe)
                                                  _buildRoleBadge(
                                                      senderRole, lang),
                                                Text(
                                                  isMe
                                                      ? "${lang.translate('me')} • $timeOnly"
                                                      : "${msg.senderName} • $timeOnly",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors
                                                          .blueGrey.shade400,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                if (!isMe)
                                                  _buildRoleBadge(
                                                      senderRole, lang),
                                              ],
                                            ),
                                          ),
                                          if (msg.audioPath != null &&
                                              msg.audioPath!.isNotEmpty)
                                            AudioMessageBubble(
                                                audioPath: msg.audioPath!,
                                                isUser: isMe)
                                          else
                                            MessageBubble(
                                                message: msg.text,
                                                isUser: isMe),
                                        ],
                                      ),
                                    ),
                                    if (isMe) const SizedBox(width: 8),
                                    if (isMe) _buildChatAvatar(liveAvatar),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                if (currentUser != null)
                  _ChatInputBar(
                    roomId: roomId,
                    currentUser: currentUser,
                    lang: lang,
                    onMessageSent: _scrollToBottom,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  final String roomId;
  final User currentUser;
  final LanguageService lang;
  final VoidCallback onMessageSent;

  const _ChatInputBar({
    super.key,
    required this.roomId,
    required this.currentUser,
    required this.lang,
    required this.onMessageSent,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _sttLocale = 'en_US';

  int _recordDuration = 0;
  Timer? _timer;
  String _lastFullText = "";

  @override
  void initState() {
    super.initState();
    _sttLocale = widget.lang.currentLanguage == 'ms' ? 'ms_MY' : 'en_US';
    _initSpeech();
    _controller.addListener(() {
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

    String existingText = _controller.text;

    await _speech!.listen(
      onResult: (val) {
        if (mounted && val.recognizedWords.isNotEmpty) {
          setState(() {
            String newWords = val.recognizedWords;
            if (isRestart && !newWords.startsWith(existingText)) {
              _controller.text = existingText + " " + newWords;
            } else {
              _controller.text = newWords;
            }

            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
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
        debugPrint(
            "Restarting mic at $_recordDuration seconds to prevent auto-disconnect");
        _rebootMic();
      }

      if (_recordDuration >= 59) {
        _listen();
      }
    });
  }

  void _rebootMic() async {
    if (!_isListening) return;
    _lastFullText = _controller.text;

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
        _controller.clear();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final newMessage = FamilyMessage(
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.displayName,
        text: text,
        avatarUrl: widget.currentUser.avatarUrl,
        timestamp: DateTime.now(),
      );

      try {
        await chatService.sendMessage(widget.roomId, newMessage);
        _controller.clear();
        _lastFullText = "";
        widget.onMessageSent();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint("Chat Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send: $e'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(seconds ~/ 60)}:${twoDigits(seconds % 60)}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech?.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record,
                    color: Colors.white, size: 12),
                const SizedBox(width: 8),
                Text(
                  _sttLocale == 'en_US' ? "Recording..." : "Merakam...",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${_formatDuration(_recordDuration)} / 00:59",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _isListening ? Colors.purple.shade100 : Colors.purple.shade100,
                const Color.fromARGB(255, 225, 190, 231),
              ],
            ),
            borderRadius: _isListening
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.purple.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isListening
                          ? Colors.redAccent.withOpacity(0.5)
                          : Colors.purple.shade50,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? (_sttLocale == 'en_US'
                              ? "Speak now..."
                              : "Cakap sekarang...")
                          : widget.lang.translate('family_type_message'),
                      hintStyle: TextStyle(
                          color: Colors.blueGrey.shade300, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!_isListening && _controller.text.trim().isEmpty)
                _buildSmallButton(
                  onTap: _toggleSttLocale,
                  child: Text(_sttLocale == 'en_US' ? 'EN' : 'MS',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              if (_controller.text.trim().isNotEmpty)
                _buildIconButton(
                  onTap: _sendMessage,
                  icon: Icons.send_rounded,
                  color: Colors.purple.shade400,
                ),
              const SizedBox(width: 4),
              _buildIconButton(
                onTap: _listen,
                icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isListening ? Colors.redAccent : Colors.orange.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
      {required VoidCallback onTap,
      required IconData icon,
      required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ]),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildSmallButton(
      {required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade50),
        ),
        child: Center(child: child),
      ),
    );
  }
}
