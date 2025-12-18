import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/const/colors.dart';

class BadgeService {
  final supabase = Supabase.instance.client;

  // 뱃지 ID
  static const int badgeCheerKing = 1; // 응원왕
  static const int badgeSincere = 2;   // 성실이
  static const int badgeStar = 3;      // 인기스타
  static const int badgeSteady = 4;    // 꾸준이

  // 뱃지 획득 시도 및 알림
  Future<void> _awardBadgeIfNotExists(BuildContext context, String userId, int badgeId, String badgeName) async {
    try {
      final check = await supabase
          .from('user_badges')
          .select()
          .eq('user_id', userId)
          .eq('badge_id', badgeId)
          .maybeSingle();

      if (check != null) return; // 이미 있으면 종료

      await supabase.from('user_badges').insert({
        'user_id': userId,
        'badge_id': badgeId,
      });

      final currentUser = supabase.auth.currentUser?.id;
      if (context.mounted && userId == currentUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("축하합니다! '$badgeName' 뱃지를 획득했습니다!")),
              ],
            ),
            backgroundColor: PRIMARY_COLOR,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("뱃지 수여 실패: $e");
    }
  }

  // 응원왕 / 인기스타
  Future<void> checkCheerBadges(BuildContext context, String senderId, String receiverId) async {
    try {
      await supabase.rpc('increment_cheer_counts', params: {
        'sender_id': senderId,
        'receiver_id': receiverId,
      });

      // 응원왕
      final senderData = await supabase.from('users').select('cheer_sent_count').eq('id', senderId).single();
      int sentCount = senderData['cheer_sent_count'] ?? 0;

      // 테스트용
      if (sentCount >= 1) {
        await _awardBadgeIfNotExists(context, senderId, badgeCheerKing, "응원왕");
      }

      // 인기스타
      final receiverData = await supabase.from('users').select('cheer_received_count').eq('id', receiverId).single();
      int receivedCount = receiverData['cheer_received_count'] ?? 0;

      // 테스트용
      if (receivedCount >= 1) {
        await _awardBadgeIfNotExists(context, receiverId, badgeStar, "인기스타");
      }

    } catch (e) {
      debugPrint("응원 뱃지 로직 에러: $e");
    }
  }

  // 꾸준이
  Future<void> checkSteadyBadge(BuildContext context, String goalId, bool isPersonal) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final tableName = isPersonal ? 'todos' : 'todos_shares';

    try {
      final result = await supabase
          .from(tableName)
          .count(CountOption.exact)
          .eq('goal_id', goalId)
          .eq('user_id', userId)
          .eq('is_completed', true);

      final count = result;

      // 테스트용
      if (count >= 1) {
        await _awardBadgeIfNotExists(context, userId, badgeSteady, "꾸준이");
      }
    } catch (e) {
      debugPrint("꾸준이 뱃지 확인 실패: $e");
    }
  }

  // 성실이
  Future<void> checkSincereBadge(BuildContext context, double progressRate) async {
    // 100% 이상일 때만
    if (progressRate >= 1.0) {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _awardBadgeIfNotExists(context, userId, badgeSincere, "성실이");
      }
    }
  }
}