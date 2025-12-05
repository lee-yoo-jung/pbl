class Message {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isMine;

  Message({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.isMine,
  });

  factory Message.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  }) {
    return Message(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      isMine: (map['user_id'] == myUserId),
    );
  }
}

