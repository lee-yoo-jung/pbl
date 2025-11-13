// 테스트 데이터
// 목표량 데이터
class GoalRecord {
  final DateTime date; // 월을 식별하기 위한 날짜
  final int totalGoals; // 총 목표 설정 횟수
  final int achievedGoals; // 달성 성공 횟수
  final double achievementRate; // 달성률(%)

  GoalRecord({
    required this.date,
    required this.totalGoals,
    required this.achievedGoals,
  }) : achievementRate = (totalGoals > 0) ? (achievedGoals / totalGoals) * 100 : 0.0; // 달성률 계산
}

class SalesData{
  SalesData(this.month, this.sales);
  final String month;
  final double sales;
}

// test data
final List<GoalRecord> allGoalData = [
  GoalRecord(date: DateTime(2024, 10), totalGoals: 30, achievedGoals: 25),
  GoalRecord(date: DateTime(2024, 11), totalGoals: 15, achievedGoals: 15),
  GoalRecord(date: DateTime(2024, 12), totalGoals: 20, achievedGoals: 10),
  GoalRecord(date: DateTime(2025, 1), totalGoals: 30, achievedGoals: 15),
  GoalRecord(date: DateTime(2025, 2), totalGoals: 15, achievedGoals: 10),
  GoalRecord(date: DateTime(2025, 3), totalGoals: 22, achievedGoals: 18),
  GoalRecord(date: DateTime(2025, 4), totalGoals: 28, achievedGoals: 12),
  GoalRecord(date: DateTime(2025, 5), totalGoals: 35, achievedGoals: 25),
  GoalRecord(date: DateTime(2025, 6), totalGoals: 40, achievedGoals: 20),
  GoalRecord(date: DateTime(2025, 7), totalGoals: 18, achievedGoals: 15),
  GoalRecord(date: DateTime(2025, 8), totalGoals: 24, achievedGoals: 16),
  GoalRecord(date: DateTime(2025, 9), totalGoals: 32, achievedGoals: 28),
  GoalRecord(date: DateTime(2025, 10), totalGoals: 30, achievedGoals: 30),
  GoalRecord(date: DateTime(2025, 11), totalGoals: 25, achievedGoals: 8),

];

