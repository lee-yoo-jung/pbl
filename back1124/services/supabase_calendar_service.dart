import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/event.dart';

class CalendarService {
  final supabase = Supabase.instance.client;

  Future<List<Event>> getGoals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', userId)
          .order('created_at');


      final events = data.map((item) => Event.fromJson(item)).toList();
      return events;
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  Future<void> addGoalWithTodos(Event event) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final goalData = await supabase
          .from('goals')
          .insert(event.toJson(user.id))
          .select()
          .single();

      final newGoalId = goalData['id'] as int;

      if (event.plans.isNotEmpty) {
        final todosData = event.plans.map((plan) {
          return plan.toJson(user.id, newGoalId); // goal_id 연결
        }).toList();

        await supabase.from('todos').insert(todosData);
      }

    } catch (e) {
      print('Error adding goal with todos: $e');
    }
  }

  Future<void> updateGoal(Event event) async {
    final user = supabase.auth.currentUser;
    if (user == null || event.id == null) return;

    try {
      await supabase
          .from('goals')
          .update(event.toJson(user.id))
          .eq('id', event.id!);

      await supabase.from('todos').delete().eq('goal_id', event.id!);

      if (event.plans.isNotEmpty) {
        final todosData = event.plans.map((plan) {
          return plan.toJson(user.id, event.id!); // 기존 goal_id 유지
        }).toList();
        await supabase.from('todos').insert(todosData);
      }
    } catch (e) {
      print('Error updating goal: $e');
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await supabase.from('goals').delete().eq('id', goalId);
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  Future<List<Event>> getFriendGoals(String friendId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      final data = await supabase
          .from('goals')
          .select('*, todos(*)')
          .eq('owner_id', friendId) // 친구의 ID로 검색
          .order('created_at');

      final events = data.map((item) => Event.fromJson(item)).toList();

      final filteredEvents = events.where((event) {
        // 공개면 보여줌
        if (!event.secret) return true;
        return false;
      }).toList();

      return filteredEvents;
    } catch (e) {
      print('Error fetching friend goals: $e');
      return [];
    }
  }
}

