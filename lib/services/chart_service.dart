import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/mypages/component/chart/goal_data.dart';

// 막대 그래프용 데이터 모델
class Plan {
  final String title;
  final bool done;
  Plan(this.title, this.done);
}

class Event {
  final String title;
  final List<Plan> plans;
  Event(this.title, this.plans);
}

// 차트 서비스
class ChartService {
  final supabase = Supabase.instance.client;

  // 막대 그래프용 데이터 가져오기
  Future<List<Event>> fetchBarChartData() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    List<Event> allEvents = [];

    try {
      // 개인 목표
      final personalData = await supabase
          .from('goals')
          .select('title, todos(title, is_completed)')
          .eq('owner_id', myId);

      for (var goal in personalData) {
        final List<dynamic> todos = goal['todos'] ?? [];
        final plans = todos.map((t) => Plan(
          t['title'] ?? '계획 없음',
          t['is_completed'] ?? false,
        )).toList();
        allEvents.add(Event(goal['title'] ?? '제목 없음', plans));
      }

      // 공유 목표
      final sharedData = await supabase
          .from('goal_shares')
          .select('title, todos_shares(title, is_completed)')
          .or('owner_id.eq.$myId,together.cs.{$myId}');

      for (var goal in sharedData) {
        final List<dynamic> todos = goal['todos_shares'] ?? [];
        final plans = todos.map((t) => Plan(
          t['title'] ?? '계획 없음',
          t['is_completed'] ?? false,
        )).toList();
        allEvents.add(Event(goal['title'] ?? '공유 목표', plans));
      }

      return allEvents;
    } catch (e) {
      debugPrint("막대 차트 데이터 로드 실패: $e");
      return [];
    }
  }

  // 꺾은선 그래프용 월별 통계 가져오기
  Future<List<GoalRecord>> fetchMonthlyGoalStats() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      // 개인 목표
      final personalData = await supabase
          .from('goals')
          .select('title, created_at, completed_at, todos(created_at, is_completed)')
          .eq('owner_id', myId);

      // 공유 목표
      final sharedData = await supabase
          .from('goal_shares')
          .select('title, created_at, completed_at, todos_shares(created_at, is_completed, user_id)')
          .or('owner_id.eq.$myId,together.cs.{$myId}');

      List<Map<String, dynamic>> allGoals = [];

      for (var g in personalData) {
        allGoals.add({
          'created_at': g['created_at'],
          'completed_at': g['completed_at'],
          'todos': g['todos'] ?? [],
        });
      }

      for (var g in sharedData) {
        final List<dynamic> allTodos = g['todos_shares'] ?? [];
        final myTodos = allTodos.where((t) => t['user_id'] == myId).toList();
        allGoals.add({
          'created_at': g['created_at'],
          'completed_at': g['completed_at'],
          'todos': myTodos,
        });
      }

      // 월별 그룹핑
      Map<String, List<Map<String, dynamic>>> groupedByMonth = {};

      for (var goal in allGoals) {
        if (goal['created_at'] == null) continue;
        final date = DateTime.parse(goal['created_at']).toLocal();
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

        if (groupedByMonth[key] == null) groupedByMonth[key] = [];
        groupedByMonth[key]!.add(goal);
      }

      List<GoalRecord> records = [];

      groupedByMonth.forEach((key, goalsInMonth) {
        int totalGoals = goalsInMonth.length;
        int successCount = 0;
        double sumRates = 0.0;

        for (var goal in goalsInMonth) {
          final startDate = DateTime.parse(goal['created_at']);
          final endDate = DateTime.parse(goal['completed_at']);
          final todos = goal['todos'] as List<dynamic>;

          double rate = calculateTimePacedAchievement(
            startDate: startDate,
            endDate: endDate,
            todos: todos,
          );

          sumRates += rate * 100;
          if (rate >= 1.0) successCount++;
        }

        final parts = key.split('-');
        records.add(GoalRecord(
          date: DateTime(int.parse(parts[0]), int.parse(parts[1])),
          totalGoals: totalGoals,
          achievedGoals: successCount,
          averageRate: totalGoals == 0 ? 0 : sumRates / totalGoals,
        ));
      });

      records.sort((a, b) => a.date.compareTo(b.date));
      return records;

    } catch (e) {
      debugPrint("월별 통계 로드 실패: $e");
      return [];
    }
  }
}