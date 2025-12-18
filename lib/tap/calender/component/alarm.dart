import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/calender/component/alarm_notifer.dart';

final supabase = Supabase.instance.client;

class AlarmList extends StatefulWidget {
  const AlarmList({super.key});

  @override
  State<AlarmList> createState() => _AlarmListState();
}

class _AlarmListState extends State<AlarmList> {
  List<Map<String, dynamic>> allNotifications = []; // 친구 요청 + 목표 초대 통합 리스트
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllNotifications();
  }

  // 모든 알림 데이터 가져오기
  Future<void> _fetchAllNotifications() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      // 친구 요청 가져오기
      final friendData = await supabase
          .from('friends')
          .select('id, requester_id, status, created_at, users!requester_id(nickname)')
          .eq('receiver_id', myId)
          .eq('status', 'pending');

      // 목표 초대 + 독촉 알림 가져오기
      final notificationData = await supabase
          .from('notifications')
          .select('id, sender_id, type, content, related_id, created_at, users!sender_id(nickname)')
          .eq('receiver_id', myId)
          .inFilter('type', ['invite_goal', 'nudge'])
          .eq('is_read', false);

      List<Map<String, dynamic>> combined = [];

      // 친구 요청 변환
      for (var item in friendData) {
        final sender = item['users']?['nickname'] ?? '알 수 없음';

        combined.add({
          'category': 'friend',
          'type': 'friend_request',
          'id': item['id'],
          'sender_name': sender,
          'content': '$sender님이 친구 신청을 보냈습니다.\n수락하시겠습니까?',
          'created_at': DateTime.parse(item['created_at']),
          'original_data': item,
        });
      }

      // 알림(초대, 독촉) 변환
      for (var item in notificationData) {
        final type = item['type'];
        final sender = item['users']?['nickname'] ?? '알 수 없음';
        final dbContent = item['content'] as String;

        String displayContent = "";

        if (dbContent.startsWith(sender)) {
          displayContent = dbContent;
        } else {
          displayContent = '$sender$dbContent';
        }

        combined.add({
          'category': 'noti',
          'type': type,
          'id': item['id'],
          'sender_name': sender,
          'content': displayContent,
          'created_at': DateTime.parse(item['created_at']),
          'related_id': item['related_id'],
          'original_data': item,
        });
      }

      // 날짜순 정렬
      combined.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      if (mounted) {
        setState(() {
          allNotifications = combined;
          _isLoading = false;
          alarmCountNotifier.value = combined.length;
        });
      }
    } catch (e) {
      debugPrint('알림 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }


  }

  void removeAndUpdate(String notiId) {
    setState(() {
      allNotifications.removeWhere(
            (item) => item['id'].toString() == notiId,
      );
      alarmCountNotifier.value = allNotifications.length;
    });
  }

  // 친구 요청 처리 함수들
  Future<void> _acceptFriend(String rowId) async {
    try {
      await supabase.from('friends').update({'status': 'accepted'}).eq('id', rowId);
    } catch (e) {
      debugPrint('친구 승인 실패: $e');
    }
  }

  Future<void> _rejectFriend(String rowId) async {
    try {
      await supabase.from('friends').delete().eq('id', rowId);
    } catch (e) {
      debugPrint('친구 거절 실패: $e');
    }
  }
  Future<void> _markAsRead(String notiId) async {
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', notiId);
      removeAndUpdate(notiId);
    } catch (e) {
      debugPrint("읽음 처리 실패: $e");
    }
  }

  // 목표 초대 처리 함수들
  Future<void> _acceptGoalInvite(String notiId, String goalId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      // goal_shares 테이블 조회
      final goalData = await supabase
          .from('goal_shares')
          .select('together')
          .eq('id', goalId)
          .single();

      List<dynamic> currentParticipants = goalData['together'] ?? [];

      // 이미 포함되어 있지 않다면 추가
      if (!currentParticipants.contains(myId)) {
        currentParticipants.add(myId);

        await supabase
            .from('goal_shares')
            .update({'together': currentParticipants})
            .eq('id', goalId);
      }

      // 알림을 읽음(처리됨) 상태로 변경
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notiId);

    } catch (e) {
      debugPrint('목표 수락 실패: $e');
      throw e;
    }
    await _markAsRead(notiId);
  }

  Future<void> _rejectGoalInvite(String notiId) async {
    await supabase.from('notifications').delete().eq('id', notiId);
    removeAndUpdate(notiId);

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("알림",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard-Regular',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 40.0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNotifications.isEmpty
          ? const Center(child: Text("새로운 알림이 없습니다."))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allNotifications.length,
        itemBuilder: (context, index) {
          final item = allNotifications[index];

          final String type = item['type'];
          final String senderName = item['sender_name'];
          final String content = item['content'];

          if (type == 'nudge') {
            // 독촉 알림: 버튼 1개 (확인)
            return ButtonAlert(
              text: content,
              buttonTextYes: "확인",
              buttonTextNo: "",
              onYesTap: () async {
                await _markAsRead(item['id'].toString());
              },
              onNoTap: () async {},
            );
          } else {
            // 친구 요청, 목표 초대: 버튼 2개 (수락/거절)
            return ButtonAlert(
              text: content,
              buttonTextYes: "수락",
              buttonTextNo: "거절",

              onYesTap: () async {
                if (type == 'friend_request') {
                  await _acceptFriend(item['id'].toString());
                  removeAndUpdate(item['id'].toString());
                } else if (type == 'invite_goal') {
                  await _acceptGoalInvite(item['id'].toString(), item['related_id'].toString());
                }
              },

              onNoTap: () async {
                if (type == 'friend_request') {
                  await _rejectFriend(item['id'].toString());
                  removeAndUpdate(item['id'].toString());
                } else if (type == 'invite_goal') {
                  await _rejectGoalInvite(item['id'].toString());
                }
              },
            );
          }
        },
      ),
    );
  }
}

class TextAlert extends StatelessWidget {
  final String text;
  const TextAlert({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class ButtonAlert extends StatefulWidget {
  final String text;
  final String buttonTextYes;
  final String buttonTextNo;
  final Future<void> Function() onYesTap;
  final Future<void> Function() onNoTap;

  const ButtonAlert({
    super.key,
    required this.text,
    required this.buttonTextYes,
    required this.buttonTextNo,
    required this.onYesTap,
    required this.onNoTap,
  });

  @override
  State<ButtonAlert> createState() => ButtonAlertState();
}

class ButtonAlertState extends State<ButtonAlert> {
  String? result;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    bool isSingleButton = widget.buttonTextNo.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),

          if (result == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: isProcessing ? null : () async {
                    setState(() => isProcessing = true);
                    try {
                      await widget.onYesTap();
                      if (mounted) {
                        setState(() {
                          // 독촉 확인인 경우 '확인됨'으로, 그 외는 '승인함'
                          result = isSingleButton ? "확인됨" : "승인함";
                        });
                      }
                    } catch(e) {
                      print("처리 실패: $e");
                      setState(() => isProcessing = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.buttonTextYes),
                ),

              if (!isSingleButton) ...[
                const SizedBox(width: 8),

                OutlinedButton(
                  onPressed: isProcessing ? null : () async {
                    setState(() => isProcessing = true);
                    try {
                      await widget.onNoTap();
                      if (mounted) {
                        setState(() {
                          result = "거절함";
                        });
                      }
                    } catch(e) {
                      setState(() => isProcessing = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(widget.buttonTextNo),
                ),
              ],
            ],
          )
          else
            Center(
              child: Text(
                result!,
                style:  TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (result=="승인함" || result=="확인됨") ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            )        ],
      ),
    );

  }
}