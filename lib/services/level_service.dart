import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  // 레벨업 기준 경험치
  static const int expPerLevel = 500;

  // 계획(Todo) 완료 시 경험치 지급
  Future<void> grantExpForPlanCompletion(BuildContext context, {
    required String goalId,
    required bool isPhotoVerified, // 사진 인증 여부
    required bool isSharedGoal,    // 공동 목표 여부
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 해당 목표에 계획이 총 몇 개인지 카운트
      // 공동 목표면 todos_shares, 개인 목표면 todos 테이블 조회
      final table = isSharedGoal ? 'todos_shares' : 'todos';

      final countRes = await supabase
          .from(table)
          .count(CountOption.exact)
          .eq('goal_id', goalId);

      int totalPlanCount = countRes;

      // 계획 개수에 따른 기본 점수 계산
      int basePoint = 5;

      if (totalPlanCount >= 50) basePoint = 30;
      else if (totalPlanCount >= 40) basePoint = 25;
      else if (totalPlanCount >= 30) basePoint = 20;
      else if (totalPlanCount >= 20) basePoint = 15;
      else if (totalPlanCount >= 10) basePoint = 10;
      else basePoint = 5;

      // 사진 인증 2배 이벤트
      if (isPhotoVerified) {
        basePoint *= 2;
      }

      debugPrint("획득 경험치: $basePoint (계획수: $totalPlanCount, 사진인증: $isPhotoVerified)");

      // 경험치 DB 반영
      await _addExpToUser(context, userId, basePoint);

    } catch (e) {
      debugPrint("경험치 지급 실패: $e");
    }
  }

  // 공동 목표 종료 시 최종 보너스 지급 로직
  Future<void> grantExpForGroupResult(BuildContext context, String goalId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 해당 목표의 모든 참여자 달성률 조회
      final todosData = await supabase
          .from('todos_shares')
          .select('user_id, is_completed')
          .eq('goal_id', goalId);

      // 참여자 목록 추출
      final userIds = todosData.map((e) => e['user_id'] as String).toSet().toList();

      // 내 달성률 계산
      final myTodos = todosData.where((e) => e['user_id'] == userId).toList();
      if (myTodos.isEmpty) return;

      double myRate = myTodos.where((e) => e['is_completed'] == true).length / myTodos.length;
      int myPercentage = (myRate * 100).round();

      //  달성률 구간별 보상 계산
      int rewardPoint = 0;

      if (myPercentage >= 100) rewardPoint = 50;
      else if (myPercentage >= 90) rewardPoint = 40;
      else if (myPercentage >= 80) rewardPoint = 30;
      else if (myPercentage >= 70) rewardPoint = 20;
      else if (myPercentage >= 60) rewardPoint = 10;
      else rewardPoint = 0;

      bool isAllPerfect = true;
      for (var uid in userIds) {
        final userTodos = todosData.where((e) => e['user_id'] == uid).toList();
        if (userTodos.isEmpty) continue;

        double uRate = userTodos.where((e) => e['is_completed'] == true).length / userTodos.length;
        if (uRate < 1.0) {
          isAllPerfect = false;
          break;
        }
      }

      if (isAllPerfect && myPercentage >= 100) {
        rewardPoint += 25;
      }

      if (rewardPoint > 0) {
        debugPrint("공동 목표 보너스 지급: $rewardPoint점 (달성률: $myPercentage%, 팀퍼펙트: $isAllPerfect)");
        await _addExpToUser(context, userId, rewardPoint);
      }

    } catch (e) {
      debugPrint("공동 목표 보너스 계산 실패: $e");
    }
  }

  // 유저에게 경험치 추가 및 레벨업 처리
  Future<void> _addExpToUser(BuildContext context, String userId, int amount) async {
    // 현재 정보 가져오기
    final data = await supabase
        .from('users')
        .select('level, exp')
        .eq('id', userId)
        .single();

    int currentLevel = data['level'] ?? 1;
    int currentExp = data['exp'] ?? 0;

    // 경험치 추가
    int newExp = currentExp + amount;
    int newLevel = currentLevel;

    // 레벨업 체크
    bool leveledUp = false;
    while (newExp >= expPerLevel) {
      newExp -= expPerLevel;
      newLevel++;
      leveledUp = true;
    }

    // DB 업데이트
    await supabase.from('users').update({
      'level': newLevel,
      'exp': newExp,
    }).eq('id', userId);

    // 레벨업 알림
    if (leveledUp && context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🎉 레벨 업!"),
          content: Text("축하합니다!\nLv.$currentLevel -> Lv.$newLevel 달성!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            )
          ],
        ),
      );
    } else if (context.mounted) {
      // 단순 경험치 획득 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("EXP +$amount 획득! (현재: $newExp/$expPerLevel)"),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}