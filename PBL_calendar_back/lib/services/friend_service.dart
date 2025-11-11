import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:calendar_scheduler/models/app_user.dart';

class FriendService {
  final supabase = Supabase.instance.client;

  // 현재 로그인한 사용자의 UUID
  String get _currentUserId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('없는 사용자입니다.');
    }
    return user.id;
  }

  // 친구 검색
  // 사용자 아이디(user_id) 또는 닉네임(nickname)으로 유저 검색 + 목표 유형
  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final String currentUserId = _currentUserId;

      final data = await supabase
          .rpc(
          'search_all_users',
          params: {
            'search_term': query,
            'exclude_id': currentUserId
          }
      );

      final users = (data as List).map((item) => AppUser.fromJson(item)).toList();
      return users;

    } catch (e) {
      print('잘못된 검색: $e');
      return [];
    }
  }

  // 친구 요청 보내기
  // 검색된 유저의 UUID를 사용
  Future<void> sendFriendRequest(String receiverUuid) async {
    try {
      await supabase.from('friends').insert({
        'requester_id': _currentUserId,
        'receiver_id': receiverUuid,
        'status': 'pending', // 'pending' (대기중) 상태로 요청
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('이미 친구 요청을 보냈거나 친구 관계입니다.');
      }
      throw Exception('친구 요청 실패: ${e.message}');
    }
  }

  // 내가 받은 친구 요청 목록 보기
  // 요청 보낸 사람의 프로필과 함께
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      // friends 테이블과 users 테이블을 조인
      final data = await supabase
          .from('friends')
          .select(
        // friendship_id, status, 그리고 요청자(requester)의 프로필 정보
        'id, status, requester:requester_id(id, user_id, nickname, level)',
      )
          .eq('receiver_id', _currentUserId) // 내가 '받는 사람'이고
          .eq('status', 'pending'); // 상태가 '대기중'인 요청


      return data;
    } catch (e) {
      print('잘못된 대기 요청: $e');
      return [];
    }
  }

  // 친구 요청 수락하기
  // getPendingRequests() 에서 얻은 'id' (friendship ID)를 사용
  Future<void> acceptFriendRequest(int friendshipId) async {
    try {
      await supabase
          .from('friends')
          .update({'status': 'accepted'}) // 상태를 'accepted' (수락됨)으로 변경
          .eq('id', friendshipId)
          .eq('receiver_id', _currentUserId); // 보안: 요청을 받은 사람만 수락 가능
    } catch (e) {
      print('잘못된 수락 요청: $e');
    }
  }

  // 친구 요청 거절 또는 친구 삭제
  // getPendingRequests() 또는 getMyFriends() 에서 얻은 'id'를 사용
  Future<void> rejectOrDeleteFriend(int friendshipId) async {
    try {
      await supabase
          .from('friends')
          .delete()
          .eq('id', friendshipId)
      // 보안: 나(currentUserId)가 요청자 또는 수신자인 경우에만 삭제 가능
          .or('requester_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId');
    } catch (e) {
      print('잘못된 거절 요청: $e');
    }
  }

  // 내 친구 목록 보기 (수락된 친구들)
  Future<List<Map<String, dynamic>>> getMyFriends() async {
    try {
      // 내가 요청했거나(requester) 받았거나(receiver) 상관없이 'accepted'된 모든 관계
      final data = await supabase
          .from('friends')
          .select(
        'id, requester:requester_id(id, user_id, nickname, level), receiver:receiver_id(id, user_id, nickname, level)',
      )
          .eq('status', 'accepted')
          .or('requester_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId');

      // 데이터를 가공해서 '내 프로필'은 빼고 '친구 프로필'만 남기기
      final List<Map<String, dynamic>> friendsList = [];
      for (var row in data) {
        final requester = AppUser.fromJson(row['requester']);
        final receiver = AppUser.fromJson(row['receiver']);

        // 내가 요청자이면, 상대방(receiver) 정보를 리스트에 추가
        if (requester.id == _currentUserId) {
          friendsList.add({
            'profile': receiver,
            'friendship_id': row['id'] // 나중에 삭제할 때 쓸 ID
          });
        }
        // 내가 수신자이면, 상대방(requester) 정보를 리스트에 추가
        else {
          friendsList.add({
            'profile': requester,
            'friendship_id': row['id']
          });
        }
      }
      return friendsList;

    } catch (e) {
      print('잘못된 친구 요청: $e');
      return [];
    }
  }
}