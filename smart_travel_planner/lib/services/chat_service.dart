// lib/services/chat_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smarttravelerplanner-default-rtdb.firebaseio.com',
  );

  DatabaseReference _chatRef(String tripId) =>
      _database.ref('chats/$tripId/messages');

  Stream<List<MessageModel>> getMessages(String tripId) {
    return _chatRef(tripId)
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final map = data as Map<dynamic, dynamic>;
      final messages = map.entries
          .map((e) => MessageModel.fromMap(
        e.value as Map<dynamic, dynamic>,
        e.key.toString(),
      ))
          .toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String tripId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final message = MessageModel(
      id: '',
      tripId: tripId,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    await _chatRef(tripId).push().set(message.toMap());
  }

  Future<void> sendSystemMessage({
    required String tripId,
    required String text,
  }) async {
    await _chatRef(tripId).push().set({
      'tripId': tripId,
      'senderId': 'system',
      'senderName': 'System',
      'senderEmail': '',
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': MessageType.system.name,
    });
  }

  Future<void> deleteMessage(String tripId, String messageId) async {
    await _chatRef(tripId).child(messageId).remove();
  }
}