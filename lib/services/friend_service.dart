import 'package:supabase_flutter/supabase_flutter.dart';

class FriendService {
  final supabase = Supabase.instance.client;

  // 친구 요청 보내기
  Future<void> sendFriendRequest(String targetUid) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    // requester_id: 나, receiver_id: 상대방, status: pending
    await supabase.from('friends').insert({
      'requester_id': myId,
      'receiver_id': targetUid,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 친구 삭제
  Future<void> deleteFriend(String targetUid) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    // 내가 요청자이거나, 내가 수신자인 경우 모두 삭제
    await supabase.from('friends').delete().or(
        'and(requester_id.eq.$myId,receiver_id.eq.$targetUid),and(requester_id.eq.$targetUid,receiver_id.eq.$myId)'
    );
  }

  // 유저 검색
  Future<List<Map<String, dynamic>>> searchUsersWithStatus(String query) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      // 닉네임 검색
      final usersData = await supabase
          .from('users')
          .select()
          .ilike('nickname', '%$query%')
          .neq('id', myId);

      //  내 친구 관계 조회
      final myFriends = await supabase
          .from('friends')
          .select()
          .or('requester_id.eq.$myId,receiver_id.eq.$myId');

      // 친구인 사람들의 ID 목록 추출
      final Set<String> friendIds = {};
      for (var f in myFriends) {
        // status가 'accepted'인 경우만 친구로 인정
        if (f['status'] == 'accepted') {
          if (f['requester_id'] == myId) friendIds.add(f['receiver_id']);
          else friendIds.add(f['requester_id']);
        }
      }

      // 결과 합치기
      return List<Map<String, dynamic>>.from(usersData).map((user) {
        return {
          ...user,
          'is_friend': friendIds.contains(user['id']),
        };
      }).toList();

    } catch (e) {
      print('검색 에러: $e');
      return [];
    }
  }

  // 내 친구 목록 조회
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    try {

      // 친구 관계 조회 (status = accepted)
      final friendships = await supabase
          .from('friends')
          .select()
          .eq('status', 'accepted')
          .or('requester_id.eq.$myId,receiver_id.eq.$myId');

      if (friendships.isEmpty) return [];

      // 친구들의 ID만 추출
      final Set<String> friendIds = {};
      for (var f in friendships) {
        if (f['requester_id'] == myId) friendIds.add(f['receiver_id']);
        else friendIds.add(f['requester_id']);
      }

      // 친구들의 상세 정보 조회
      final friendsData = await supabase
          .from('users')
          .select('id, nickname, avatar_url, goal_types, level')
          .filter('id', 'in', friendIds.toList());

      final mySharedGoals = await supabase
          .from('goal_shares')
          .select('title, owner_id, together')
          .or('owner_id.eq.$myId,together.cs.{$myId}');

      return friendsData.map((friend) {
        final friendId = friend['id'];

        List<String> sharedTitles = [];

        for (var goal in mySharedGoals) {
          final ownerId = goal['owner_id'];
          final List<dynamic> together = goal['together'] ?? [];

          bool isFriendInvolved = (ownerId == friendId) || together.contains(friendId);

          if (isFriendInvolved) {
            sharedTitles.add(goal['title'] ?? '제목 없음');
          }
        }

        return {
          ...friend as Map<String, dynamic>,
          'shared_goals': sharedTitles,
        };
      }).toList();

    } catch (e) {
      print('친구 목록 로드 실패: $e');
      return [];
    }
  }
}