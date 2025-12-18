import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
final ValueNotifier<int> alarmCountNotifier = ValueNotifier<int>(0);

final supabase = Supabase.instance.client;

Future<void> loadAlarmCount() async {
  final myId = supabase.auth.currentUser?.id;
  if (myId == null) return;

  try {
    // 친구 요청
    final friendData = await supabase
        .from('friends')
        .select('id')
        .eq('receiver_id', myId)
        .eq('status', 'pending');

    // 알림
    final notificationData = await supabase
        .from('notifications')
        .select('id')
        .eq('receiver_id', myId)
        .eq('is_read', false)
        .inFilter('type', ['invite_goal', 'nudge']);

    alarmCountNotifier.value =
        friendData.length + notificationData.length;
  } catch (e) {
    debugPrint('알람 개수 로드 실패: $e');
  }
}