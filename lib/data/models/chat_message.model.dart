import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMessage {
  final String senderId;
  final String senderName;
  final String text;
  final String? avatarUrl;
  final DateTime timestamp;
  final String? audioPath;

  FamilyMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    this.avatarUrl,
    required this.timestamp,
    this.audioPath,
  });

  factory FamilyMessage.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp;
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return FamilyMessage(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      avatarUrl: map['avatarUrl'],
      timestamp: parsedTimestamp,
      audioPath: map['audioPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'avatarUrl': avatarUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'audioPath': audioPath,
    };
  }
}
