class Profile {
  final String id;
  final String nickname;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '알 수 없음',
      avatarUrl: map['avatar_url'],
    );
  }
}