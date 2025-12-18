import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/event.dart';

class CalendarService {
  final supabase = Supabase.instance.client;

  // 목표(Goal) + 세부계획(Todos) 추가
  Future<void> addGoalWithTodos(Event event) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (event.togeter.isNotEmpty) {
        await _addSharedGoal(event, userId);
      } else {
        await _addPersonalGoal(event, userId);
      }
    } catch (e) {
      print('Error adding goal with todos: $e');
      throw e;
    }
  }

  // 개인 목표 저장
  Future<void> _addPersonalGoal(Event event, String userId) async {
    final goalResponse = await supabase.from('goals').insert({
      ...event.toJson(userId),
    }).select().single();

    final String newGoalId = goalResponse['id'].toString();

    if (event.plans.isNotEmpty) {
      final List<Map<String, dynamic>> plansData = event.plans.map((plan) {
        final data = plan.toJson(userId, newGoalId);
        data['start_at'] = plan.selectdate.toIso8601String();
        return data;
      }).toList();

      await supabase.from('todos').insert(plansData);
    }
  }

  // 공유 목표 저장
  Future<void> _addSharedGoal(Event event, String userId) async {
    List<String> participantIds = [];
    if (event.togeter.isNotEmpty) {
      final friendsData = await supabase
          .from('users')
          .select('id')
          .filter('nickname', 'in', event.togeter);

      participantIds = List<String>.from(friendsData.map((e) => e['id']));
    }

    final shareGoalResponse = await supabase.from('goal_shares').insert({
      'owner_id': userId,
      'title': event.title,
      'created_at': event.startDate.toIso8601String(),
      'completed_at': event.endDate.toIso8601String(),
      'color': Event.colorToHex(event.color),
      'emoji': event.emoji,
      'together': participantIds,
    }).select().single();

    final String newShareGoalId = shareGoalResponse['id'].toString();

    if (event.plans.isNotEmpty) {
      final List<Map<String, dynamic>> plansData = event.plans.map((plan) {
        return {
          'goal_id': newShareGoalId,
          'user_id': userId,
          'title': plan.text,
          'is_completed': plan.isDone,
          'hashtag': plan.hashtag,
          'created_at': DateTime.now().toIso8601String(),
          'start_at': plan.selectdate.toIso8601String(),
        };
      }).toList();

      await supabase.from('todos_shares').insert(plansData);
    }

    if (participantIds.isNotEmpty) {
      final myProfile = await supabase.from('users').select('nickname').eq('id', userId).single();
      final myNickname = myProfile['nickname'] ?? '친구';

      List<Map<String, dynamic>> notifications = [];
      for (String friendId in participantIds) {
        notifications.add({
          'sender_id': userId,
          'receiver_id': friendId,
          'type': 'invite_goal',
          'content': '$myNickname님이 공유 목표 "${event.title}"에 초대했습니다.',
          'related_id': newShareGoalId,
          'is_read': false,
        });
      }
      await supabase.from('notifications').insert(notifications);
    }
  }

  // 내 목표 가져오기
  Future<List<Event>> getGoals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 개인 목표
      final personalResponse = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', userId)
          .order('created_at'); // DB 정렬

      // 공유 목표
      final sharedResponse = await supabase
          .from('goal_shares')
          .select('*, todos_shares(*)')
          .or('owner_id.eq.$userId,together.cs.{$userId}')
          .order('created_at'); // DB 정렬

      final List<Event> allEvents = [];

      for (var item in personalResponse) {
        try {
          allEvents.add(Event.fromJson(item));
        } catch (e) {
          print('개인 목표 파싱 에러(건너뜀): $e');
        }
      }

      for (var item in sharedResponse) {
        try {
          allEvents.add(Event.fromJson(item));
        } catch (e) {
          print('공유 목표 파싱 에러(건너뜀): $e');
        }
      }

      allEvents.sort((a, b) {
        try {
          return a.startDate.compareTo(b.startDate);
        } catch (e) {
          return 0;
        }
      });

      return allEvents;
    } catch (e) {
      print('전체 목표 로드 실패 (getGoals): $e');
      return [];
    }
  }

  // 목표 수정
  Future<void> updateGoal(Event event) async {
    if (event.id == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (event.togeter.isNotEmpty) {
      await _updateSharedGoal(event, userId);
    } else {
      await _updatePersonalGoal(event, userId);
    }
  }

  Future<void> _updatePersonalGoal(Event event, String userId) async {
    await supabase.from('goals').update({
      'title': event.title,
      'created_at': event.startDate.toIso8601String(),
      'completed_at': event.endDate.toIso8601String(),
      'visibility': event.secret,
      'emoji': event.emoji,
      'color': Event.colorToHex(event.color),
    }).eq('id', event.id!);

    if (event.plans.isNotEmpty) {
      for (var plan in event.plans) {
        if (plan.id != null) {
          await supabase.from('todos').update({
            'is_completed': plan.isDone,
            'title': plan.text,
            'start_at': plan.selectdate.toIso8601String(),
          }).eq('id', plan.id!);
        } else {
          final planData = plan.toJson(userId, event.id!);
          planData['start_at'] = plan.selectdate.toIso8601String();
          await supabase.from('todos').insert(planData);
        }
      }
    }
  }

  Future<void> _updateSharedGoal(Event event, String userId) async {
    await supabase.from('goal_shares').update({
      'title': event.title,
      'created_at': event.startDate.toIso8601String(),
      'completed_at': event.endDate.toIso8601String(),
      'emoji': event.emoji,
      'color': Event.colorToHex(event.color),
    }).eq('id', event.id!);

    if (event.plans.isNotEmpty) {
      for (var plan in event.plans) {
        if (plan.id != null) {
          await supabase.from('todos_shares').update({
            'is_completed': plan.isDone,
            'title': plan.text,
            'start_at': plan.selectdate.toIso8601String(),
          }).eq('id', plan.id!);
        } else {
          await supabase.from('todos_shares').insert({
            'goal_id': event.id,
            'user_id': userId,
            'title': plan.text,
            'is_completed': plan.isDone,
            'hashtag': plan.hashtag,
            'created_at': DateTime.now().toIso8601String(),
            'start_at': plan.selectdate.toIso8601String(),
          });
        }
      }
    }
  }

  // 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    try {
      await supabase.from('goals').delete().eq('id', goalId);
    } catch (e) {
      try {
        await supabase.from('goal_shares').delete().eq('id', goalId);
      } catch (e2) {
        print('Error deleting goal: $e2');
      }
    }
  }

  // 계획 삭제
  Future<void> deletePlan(String planId, {bool isShared = false}) async {
    try {
      // 공유 목표의 계획이면 'todos_shares'에서 삭제
      if (isShared) {
        await supabase.from('todos_shares').delete().eq('id', planId);
      }
      // 개인 목표의 계획이면 'todos'에서 삭제
      else {
        await supabase.from('todos').delete().eq('id', planId);
      }
    } catch (e) {
      print('계획 삭제 실패: $e');
      throw e;
    }
  }

  // 친구의 개인 목표 가져오기
  Future<List<Event>> getFriendGoals(String friendUid) async {
    try {
      final personalResponse = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', friendUid)
          .eq('visibility', false)
          .order('created_at');

      final sharedResponse = await supabase
          .from('goal_shares')
          .select('*, todos_shares(*)')
          .or('owner_id.eq.$friendUid,together.cs.{$friendUid}')
          .order('created_at');

      final List<Event> allEvents = [];

      // 개인 목표 파싱
      for (var item in personalResponse) {
        try {
          allEvents.add(Event.fromJson(item));
        } catch (e) {
          print('친구 개인 목표 파싱 에러: $e');
        }
      }

      // 공유 목표 파싱
      for (var item in sharedResponse) {
        try {
          allEvents.add(Event.fromJson(item));
        } catch (e) {
          print('친구 공유 목표 파싱 에러: $e');
        }
      }

      // 날짜순 정렬
      allEvents.sort((a, b) {
        try {
          return a.startDate.compareTo(b.startDate);
        } catch (e) {
          return 0;
        }
      });

      return allEvents;
    } catch (e) {
      print('친구 목표 로드 에러: $e');
      return [];
    }
  }
}