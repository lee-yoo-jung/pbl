class Message {
  Message({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isMine;

  Message.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  })  : id = map['id'].toString(),
        userId = map['user_id'] ?? '',
        content = map['content'] as String,
        imageUrl = map['image_url'],
        createdAt = DateTime.parse(map['created_at']).toLocal(),
        isMine = myUserId == map['profile_id'];
}

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      id: map['id'].toString(),
      messageId: map['message_id'].toString(),
      userId: map['user_id'] ?? '',
      emoji: map['emoji'] ?? '',
    );
  }
}