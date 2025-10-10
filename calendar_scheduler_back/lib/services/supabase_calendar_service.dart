import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:calendar_scheduler/component/event.dart';

class calendarService {
  final supabase = Supabase.instance.client;

  // 현재 사용자의 모든 목표(Goal/Event)를 가져오는 함수
  Future<List<Event>> getGoals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return []; // 로그인하지 않았으면 빈 리스트 반환

    try {
      final data = await supabase
          .from('goals')
          .select()
          .eq('owner_id', userId); // 현재 사용자의 데이터만 선택

      // Supabase에서 받은 List<Map>을 List<Event>로 변환
      final events = data.map((item) => Event.fromJson(item)).toList();
      return events;
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  // 새로운 목표(Goal/Event)를 추가하는 함수
  Future<Event?> addGoal(Event event) async {
    try {
      // Event 객체를 Supabase가 이해하는 Map 형태로 변환 (toJson)
      // .select()를 붙여 방금 생성된 데이터를 다시 받아옴
      final data = await supabase
          .from('goals')
          .insert(event.toJson())
          .select()
          .single();

      // 반환된 Map 데이터를 다시 Event 객체로 변환하여 반환
      return Event.fromJson(data);
    } catch (e) {
      print('Error adding goal: $e');
      return null;
    }
  }

  // 목표(Goal/Event)를 삭제하는 함수
  Future<void> deleteGoal(int eventId) async {
    try {
      await supabase.from('goals').delete().eq('id', eventId);
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }
}