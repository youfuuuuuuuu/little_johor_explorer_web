import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class GeminiService extends ChangeNotifier {
  late final GenerativeModel _model;
  final Map<String, ChatSession> _userChats = {};

  static const String _systemInstruction =
      "You are Mr. Knowledge (En. Pengetahuan), a friendly and fun AI guide for the 'Little Johor Explorer' app. "
      "\n\nFORMATTING RULES:"
      "\n1. Use **BOLD** for names of places, food, and historical figures. "
      "\n2. Use *ITALICS* for Malay terms or special expressions. "
      "\n3. Use Bullet Points (-) to list steps in an itinerary or ingredients in food. "
      "\n4. Use Headers (###) for section titles like 'Suggested Itinerary'. "
      "\n5. Keep the structure clean with double line breaks between paragraphs."
      "\nYour mission is to help children discover the wonders of Johor, Malaysia. 🗺️"
      "\n\nSCOPE OF KNOWLEDGE:"
      "\n1. Answer questions about Johor's history, culture, geography, and fun facts. "
      "\n2. Suggest exciting trips and itineraries in Johor. 🚗"
      "\n3. Recommend historical places (e.g., Sultan Abu Bakar State Mosque, Kota Tinggi Fort). "
      "\n4. Suggest delicious Johor foods (e.g., Laksa Johor, Mee Rebus, Pisang Goreng with sambal kicap). 🍜"
      "\n5. Recommend fun activities like visiting Legoland, Desaru Coast, or hiking at Gunung Ledang. "
      "\n\nRESPONSE GUIDELINES:"
      "\n- Keep answers to 2 or 3 short, easy-to-read paragraphs suitable for a primary school student. "
      "\n- Use many fun emojis to make the chat colorful and engaging! ✨"
      "\n- When suggesting places or food, explain briefly WHY it's special for children. "
      "\n- IMPORTANT: Always end every response by asking the child a fun, related question to keep the conversation going! "
      "\n\nSTRICT RULES:"
      "\n- If a user asks about anything outside of Johor, Malaysia, politely decline and steer them back to Johor topics. "
      "\n- CRITICAL: Always respond in the SAME language the user uses (English or Malay). "
      "\n- Ensure all suggestions are family-friendly and safe for kids.";

  GeminiService() {
    final googleAI = FirebaseAI.googleAI();

    _model = googleAI.generativeModel(
      model: 'gemini-3.1-flash-lite',
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  void initUserSession(String userId) {
    if (!_userChats.containsKey(userId)) {
      _userChats[userId] = _model.startChat();
    }
  }

  List<Map<String, String>> getHistory(String userId) {
    if (!_userChats.containsKey(userId)) return [];

    final history = _userChats[userId]!.history;
    return history.map((content) {
      final text =
          content.parts.whereType<TextPart>().map((p) => p.text).join();
      return {
        'role': content.role ?? 'user',
        'text': text,
      };
    }).toList();
  }

  Future<String> chatWithHistory(String userId, String message) async {
    try {
      if (!_userChats.containsKey(userId)) {
        initUserSession(userId);
      }

      final chat = _userChats[userId]!;
      final response = await chat.sendMessage(Content.text(message));
      final reply = response.text ?? "I'm sorry, I couldn't process that.";

      notifyListeners();
      return reply;
    } catch (e) {
      debugPrint("Firebase AI (Vertex) error: $e");
      return "Error connecting to guide.";
    }
  }

  void clearChat(String userId) {
    if (_userChats.containsKey(userId)) {
      _userChats[userId] = _model.startChat();
      notifyListeners();
    }
  }
}
