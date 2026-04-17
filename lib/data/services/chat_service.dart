import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<FamilyMessage>> getMessages(
      String familyId, String currentUserId) async* {
    final prefs = await SharedPreferences.getInstance();
    final int? clearTime = prefs.getInt('chat_clear_$currentUserId');

    yield* _firestore
        .collection('family_chats')
        .doc(familyId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      List<FamilyMessage> validMessages = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          DateTime parsedTime = DateTime.now();
          if (data['timestamp'] != null) {
            if (data['timestamp'] is Timestamp) {
              parsedTime = (data['timestamp'] as Timestamp).toDate();
            } else if (data['timestamp'] is int) {
              parsedTime =
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
            }
          }

          final msg = FamilyMessage(
            senderId: data['senderId'] ?? '',
            senderName: data['senderName'] ?? 'Unknown',
            text: data['text'] ?? '',
            avatarUrl: data['avatarUrl'],
            timestamp: parsedTime,
            audioPath: data['audioPath'],
          );

          if (clearTime == null ||
              msg.timestamp.millisecondsSinceEpoch > clearTime) {
            validMessages.add(msg);
          }
        } catch (e) {
          print("Skipped broken message: $e");
        }
      }

      return validMessages;
    });
  }

  Future<void> sendMessage(String familyId, FamilyMessage message) async {
    try {
      Map<String, dynamic> safeData = {
        'senderId': message.senderId,
        'senderName': message.senderName,
        'text': message.text,
        'avatarUrl': message.avatarUrl,
        'audioPath': message.audioPath,
        'timestamp': Timestamp.now(),
      };

      await _firestore
          .collection('family_chats')
          .doc(familyId)
          .collection('messages')
          .add(safeData);
    } catch (e) {
      print("🔥 Firebase Send Error: $e");
      throw e;
    }
  }

  Future<void> clearMessagesForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'chat_clear_$userId', DateTime.now().millisecondsSinceEpoch);
  }
}
