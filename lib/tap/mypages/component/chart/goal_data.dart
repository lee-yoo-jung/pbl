import 'package:flutter/material.dart';

// 목표 기록 데이터 모델
class GoalRecord {
  final DateTime date;        // 날짜 (년-월)
  final int totalGoals;       // 그 달의 총 목표 개수
  final int achievedGoals;    // 그 달의 성공한 목표 개수 (조건 충족 시)
  final double averageRate;   // 그 달 목표들의 평균 달성률 (%)

  GoalRecord({
    required this.date,
    required this.totalGoals,
    required this.achievedGoals,
    required this.averageRate,
  });
}

// 기간 경과형 달성률 계산 로직
double calculateTimePacedAchievement({
  required DateTime startDate,    // 목표 시작일
  required DateTime endDate,      // 목표 종료일
  required List<dynamic> todos,   // 그 목표의 투두 리스트
}) {
  // 유효성 검사
  if (todos.isEmpty) return 0.0;

  // 목표 전체 기간 계산
  int totalGoalDuration = endDate.difference(startDate).inDays + 1;
  if (totalGoalDuration <= 0) return 0.0;

  // 첫 투두 생성일 찾기
  final firstTodoDate = (todos
      .map((e) => DateTime.parse(e['created_at']).toLocal())
      .toList()
    ..sort((a, b) => a.compareTo(b)))
      .first;

  // 오늘 날짜 기준 경과일 계산
  final today = DateTime.now().toLocal();

  // 만약 오늘이 목표 종료일보다 지났다면, 종료일까지만 계산
  DateTime calcPoint = today.isAfter(endDate) ? endDate : today;

  int elapsedDays = calcPoint.difference(firstTodoDate).inDays + 1;

  // 경과일은 1일 이상, 전체 기간 이하
  elapsedDays = elapsedDays.clamp(1, totalGoalDuration);

  // 하루 가치 및 현재 시점 최대 점수 계산
  final double dailyMaxRate = 100.0 / totalGoalDuration;
  final double maxPossibleRate = elapsedDays * dailyMaxRate;

  // 오늘까지 생성된 투두 필터링
  final todosUntilToday = todos.where((e) {
    final todoDate = DateTime.parse(e['created_at']).toLocal();
    final differenceInDays = todoDate.difference(firstTodoDate).inDays;
    return differenceInDays < elapsedDays;
  }).toList();

  final totalTodoCountUntilToday = todosUntilToday.length;

  if (totalTodoCountUntilToday == 0) return 0.0;

  // 개당 점수 및 최종 달성률 계산
  final double ratePerTodo = maxPossibleRate / totalTodoCountUntilToday;

  final completedTodoCount = todosUntilToday
      .where((e) => e['is_completed'] == true)
      .length;

  final achievedRate = (completedTodoCount * ratePerTodo).clamp(0.0, 100.0);

  return achievedRate / 100.0;
}