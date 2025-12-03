import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/event.dart';

class CalendarService {
  final supabase = Supabase.instance.client;

  // 목표(Goal) + 세부계획(Todos) 추가
  Future<void> addGoalWithTodos(Event event) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final goalResponse = await supabase.from('goals').insert({
        ...event.toJson(userId),
      }).select().single();

      final String newGoalId = goalResponse['id'].toString();

      // 세부 계획(Todos) 저장
      if (event.plans.isNotEmpty) {
        final List<Map<String, dynamic>> plansData = event.plans.map((plan) {
          return plan.toJson(userId, newGoalId);
        }).toList();

        await supabase.from('todos').insert(plansData);
      }
    } catch (e) {
      print('Error adding goal with todos: $e');
      throw e;
    }
  }

  // 내 목표 가져오기 (Plans 포함)
  Future<List<Event>> getGoals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', userId)
          .order('created_at');

      final List<Event> events = [];
      for (var item in response) {
        events.add(Event.fromJson(item));
      }
      return events;
    } catch (e) {
      print('Error loading goals: $e');
      return [];
    }
  }

  // 목표 수정 (내용, 색상 등) + 세부 계획 업데이트는 별도 로직 필요할 수 있음
  Future<void> updateGoal(Event event) async {
    // 이벤트 자체 업데이트
    if (event.id != null) {
      await supabase.from('goals').update({
        'title': event.title,
        'description': event.description,
        'created_at': event.startDate.toIso8601String(),
        'completed_at': event.endDate.toIso8601String(),
        'visibility': event.secret,
        'together': event.togeter,
        'emoji': event.emoji,
        'color': Event.colorToHex(event.color),
      }).eq('id', event.id!);
    }

    if (event.plans.isNotEmpty) {
      for (var plan in event.plans) {
        if (plan.id != null) {
          await supabase.from('todos').update({
            'is_completed': plan.isDone,
            'title': plan.text,
          }).eq('id', plan.id!);
        } else if (event.id != null) {
          await supabase.from('todos').insert(plan.toJson(
              supabase.auth.currentUser!.id,
              event.id! // String ID 사용
          ));
        }
      }
    }
  }

  // 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    try {
      await supabase.from('goals').delete().eq('id', goalId);
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  // 친구의 목표 가져오기
  Future<List<Event>> getFriendGoals(String friendUid) async {
    try {
      final response = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', friendUid)
          .eq('visibility', false)
          .order('created_at');

      final List<Event> events = [];
      for (var item in response) {
        events.add(Event.fromJson(item));
      }
      return events;
    } catch (e) {
      print('친구 목표 로드 에러: $e');
      return [];
    }
  }
}