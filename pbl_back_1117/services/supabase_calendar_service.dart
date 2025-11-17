import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/event.dart';

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
      print('에러: $e');
      return [];
    }
  }

  // 새로운 목표(Goal/Event)를 추가하는 함수
  Future<Event?> addGoal(Event event) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('로그인 x, 계획 추가 불가능');
      return null;
    }

    try {
      final data = await supabase
          .from('goals')
          .insert(event.toJson(user.id))
          .select()
          .single();

      return Event.fromJson(data);
    } catch (e) {
      print('목표 추가 에러: $e');
      return null;
    }
  }

  // 목표(Goal/Event)를 삭제하는 함수
  Future<void> deleteGoal(int eventId) async {
    try {
      await supabase.from('goals').delete().eq('id', eventId);
    } catch (e) {
      print('목표 삭제 에러: $e');
    }
  }

  // 목표(Event)의 내용을 업데이트하는 함수
  Future<void> updateGoal(Event event) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('로그인x');
      return;
    }

    try {
      await supabase
          .from('goals')
          .update(event.toJson(user.id)) // Event 객체 전체를 JSON으로 변환하여 업데이트
          .eq('id', event.id!);

      print('목표가 성공적으로 업데이트되었습니다.');
    } catch (e) {
      print('목표 업데이트 에러: $e');
    }
  }
}



