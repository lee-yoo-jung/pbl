class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  final String id;

  final String username;

  final DateTime createdAt;

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['nickname'] ?? '알 수 없음',
        createdAt = DateTime.parse(map['created_at']?? DateTime.now().toIso8601String());
}