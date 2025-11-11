
class AppUser {
  final String id; // 시스템 UUID
  final String userId; // 사용자가 정한 아이디
  final String nickname; // 닉네임
  final int level;
  final List<String> goalTypes;

  AppUser({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.level,
    required this.goalTypes,
  });

  // DB에서 받은 Map(JSON)을 AppUser 객체로 변환
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      userId: json['user_id'] ?? '알 수 없음',
      nickname: json['nickname'] ?? '이름 없음',
      level: json['level'] ?? 1,
      goalTypes: List<String>.from(json['goal_types'] ?? []),
    );
  }
}