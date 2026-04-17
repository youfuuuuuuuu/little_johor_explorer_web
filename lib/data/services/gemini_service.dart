import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class GeminiService extends ChangeNotifier {
  late GenerativeModel _model;

  final Map<String, ChatSession> _userChats = {};
  final Map<String, List<Content>> _userHistories = {};
  String _currentUserId = "unknown";

  GeminiService() {
    final vertexAI = FirebaseAI.vertexAI();
    _model = vertexAI.generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.system(
          "You are Mr. Knowledge (En. Pengetahuan), a friendly and fun AI guide for the 'Little Johor Explorer' app. "
          "\n\nFORMATTING RULES:"
          "1. Use **BOLD** for names of places, food, and historical figures. "
          "2. Use *ITALICS* for Malay terms or special expressions. "
          "3. Use Bullet Points (-) to list steps in an itinerary or ingredients in food. "
          "4. Use Headers (###) for section titles like 'Suggested Itinerary'. "
          "5. Keep the structure clean with double line breaks between paragraphs."
          "Your mission is to help children discover the wonders of Johor, Malaysia. 🗺️"
          "\n\nSCOPE OF KNOWLEDGE:"
          "1. Answer questions about Johor's history, culture, geography, and fun facts. "
          "2. Suggest exciting trips and itineraries in Johor. 🚗"
          "3. Recommend historical places (e.g., Sultan Abu Bakar State Mosque, Kota Tinggi Fort). "
          "4. Suggest delicious Johor foods (e.g., Laksa Johor, Mee Rebus, Pisang Goreng with sambal kicap). 🍜"
          "5. Recommend fun activities like visiting Legoland, Desaru Coast, or hiking at Gunung Ledang. "
          "\n\nRESPONSE GUIDELINES:"
          "- Keep answers to 2 or 3 short, easy-to-read paragraphs suitable for a primary school student. "
          "- Use many fun emojis to make the chat colorful and engaging! ✨"
          "- When suggesting places or food, explain briefly WHY it's special for children. "
          "- IMPORTANT: Always end every response by asking the child a fun, related question to keep the conversation going! "
          "\n\nSTRICT RULES:"
          "- If a user asks about anything outside of Johor, Malaysia, politely decline and steer them back to Johor topics. "
          "- CRITICAL: Always respond in the SAME language the user uses (English or Malay). "
          "- Ensure all suggestions are family-friendly and safe for kids."),
    );
  }

  void initUserSession(String userId) {
    _currentUserId = userId;
    if (!_userChats.containsKey(userId)) {
      _userChats[userId] = _model.startChat();
      _userHistories[userId] = [];
    }
  }

  List<Content> get history => _userHistories[_currentUserId] ?? [];

  Future<String> chatWithHistory(String message) async {
    try {
      if (!_userChats.containsKey(_currentUserId)) {
        initUserSession(_currentUserId);
      }

      final chat = _userChats[_currentUserId]!;
      final response = await chat.sendMessage(Content.text(message));
      final text = response.text ?? "I'm sorry, I couldn't process that.";

      _userHistories[_currentUserId] = chat.history.toList();
      notifyListeners();
      return text;
    } catch (e) {
      debugPrint("Vertex AI Error: $e");
      return "Error connecting to guide.";
    }
  }

  void clearChat() {
    if (_userChats.containsKey(_currentUserId)) {
      _userChats[_currentUserId] = _model.startChat();
      _userHistories[_currentUserId] = [];
      notifyListeners();
    }
  }
}
