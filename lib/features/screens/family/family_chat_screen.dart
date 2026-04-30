import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:little_johor_explorer/data/services/auth_service.dart';
import 'package:little_johor_explorer/data/services/language_service.dart';
import 'package:little_johor_explorer/data/services/chat_service.dart';
import 'package:little_johor_explorer/data/models/chat_message.model.dart';
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
    if (user.role == 'parent') return user.id;
    if (user is ChildProfile) return user.parentId;
    return "unknown";
  }

  String? _getLiveAvatar(String senderId, User? currentUser) {
    if (currentUser == null) return null;
    if (senderId == currentUser.id) return currentUser.avatarUrl;
    if (currentUser is ParentProfile) {
      try {
        return currentUser.children
            .firstWhere((child) => child.id == senderId)
            .avatarUrl;
      } catch (_) {}
    }
    return null;
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  String _getDateText(DateTime date, LanguageService lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);
    if (msgDate == today)
      return lang.currentLanguage == 'ms' ? 'Hari ini' : 'Today';
    if (msgDate == yesterday)
      return lang.currentLanguage == 'ms' ? 'Semalam' : 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _clearChat(String roomId, ChatService chatService, LanguageService lang,
      String currentUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('cancel'),
                  style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await chatService.clearMessagesForUser(currentUserId);
                if (mounted) setState(() {});
              },
              child: Text(lang.translate('clear'),
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            // Family icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('family_title'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  lang.translate('family_sending_as') +
                      (currentUser?.displayName ?? ''),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded,
                color: Colors.grey.shade500, size: 20),
            onPressed: () =>
                _clearChat(roomId, chatService, lang, currentUserId),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE8E8E8)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FamilyMessage>>(
              stream: chatService.getMessages(roomId, currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0A0A0A)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.waving_hand_rounded,
                              size: 32, color: Color(0xFF0A0A0A)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.translate('family_no_messages'),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg.senderId == currentUser?.id;
                    String senderRole =
                        (msg.senderId == roomId) ? 'parent' : 'child';
                    String? liveAvatar =
                        _getLiveAvatar(msg.senderId, currentUser) ??
                            msg.avatarUrl;
                    final avatarClean =
                        liveAvatar?.replaceFirst('file:///', '');

                    bool showDate = false;
                    if (index == messages.length - 1) {
                      showDate = true;
                    } else {
                      showDate = !_isSameDay(
                          msg.timestamp, messages[index + 1].timestamp);
                    }

                    return Column(
                      children: [
                        if (showDate) _dateDivider(msg.timestamp, lang),
                        _messageRow(
                          msg: msg,
                          isMe: isMe,
                          senderRole: senderRole,
                          avatarClean: avatarClean,
                          lang: lang,
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
    );
  }

  Widget _dateDivider(DateTime date, LanguageService lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Container(height: 0.5, color: const Color(0xFFE8E8E8))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _getDateText(date, lang),
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
              child: Container(height: 0.5, color: const Color(0xFFE8E8E8))),
        ],
      ),
    );
  }

  Widget _messageRow({
    required FamilyMessage msg,
    required bool isMe,
    required String senderRole,
    required String? avatarClean,
    required LanguageService lang,
  }) {
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);
    final bool isParent = senderRole == 'parent';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage:
                  avatarClean != null ? AssetImage(avatarClean) : null,
              child: avatarClean == null
                  ? const Icon(Icons.face_rounded, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Name + role badge + time
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe)
                        _roleBadge(senderRole, lang)
                      else ...[
                        Text(
                          msg.senderName,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        _roleBadge(senderRole, lang),
                      ],
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Message bubble
                if (msg.audioPath != null && msg.audioPath!.isNotEmpty)
                  AudioMessageBubble(audioPath: msg.audioPath!, isUser: isMe)
                else
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF0A0A0A) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF0A0A0A),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage:
                  avatarClean != null ? AssetImage(avatarClean) : null,
              child: avatarClean == null
                  ? const Icon(Icons.face_rounded, size: 16, color: Colors.grey)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleBadge(String role, LanguageService lang) {
    final bool isParent = role == 'parent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isParent
            ? const Color(0xFF0A0A0A).withOpacity(0.08)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isParent
            ? lang.translate('parent').toUpperCase()
            : lang.translate('child').toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: isParent ? const Color(0xFF0A0A0A) : Colors.orange.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

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
    _lastFullText = _controller.text;
    await _speech?.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isListening) _startSpeechEngine(isRestart: true);
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
      _stopTimer();
      await _speech!.stop();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted)
      setState(() {
        _isListening = false;
        _recordDuration = 0;
      });
  }

  void _toggleLocale() => setState(() {
        _sttLocale = _sttLocale == 'en_US' ? 'ms_MY' : 'en_US';
      });

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                          color: Colors.redAccent, shape: BoxShape.circle)),
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
                    '$_recordDuration s / 59s',
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
                          : const Color(0xFFE8E8E8),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.lang.translate('family_type_message'),
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
              if (!_isListening && _controller.text.trim().isEmpty)
                _circleBtn(
                  onTap: _toggleLocale,
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
              if (_controller.text.trim().isNotEmpty)
                _circleBtn(
                  onTap: _sendMessage,
                  child: const Icon(Icons.arrow_right_alt_rounded,
                      color: Colors.white, size: 20),
                  color: const Color(0xFF0A0A0A),
                ),
              const SizedBox(width: 6),
              _circleBtn(
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

  Widget _circleBtn({
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
}
