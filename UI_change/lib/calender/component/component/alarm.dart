import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AlarmList extends StatefulWidget {
  const AlarmList({super.key});

  @override
  State<AlarmList> createState() => _AlarmList();
}


class _AlarmList extends State<AlarmList> {
  List<Widget> alerts = [];

  List<Map<String, dynamic>> friendRequests = [];
  bool _isLoading = true;

  ///DB 릴타임
  @override
  void initState() {
    super.initState();
    _fetchFriendRequests();
  }

  //   alerts.add(TextAlert(text: "사용자 B님이 당신의 목표에 거절했습니다."));
  //   alerts.add(TextAlert(text: "사용자 A님이 당신의 목표의 어떤 계획 완료를 기대하고 있습니다!"));
  //   alerts.add(ButtonAlert(
  //     text: "사용자 A님이 사용자A의 목표에 동참하길 원합니다. \n 동참하시겠습니까?",
  //     buttonTextYes: "예",
  //     buttonTextNo: "아니오",
  //   ));
  // }

  // 친구 요청 가져오기
  Future<void> _fetchFriendRequests() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final data = await supabase
          .from('friends')
          .select('id, requester_id, status, created_at, users!requester_id(nickname)')
          .eq('receiver_id', myId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        friendRequests = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('친구 요청 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 친구 요청 승인
  Future<void> _acceptRequest(String friendRowId) async {
    try {
      await supabase
          .from('friends')
          .update({'status': 'accepted'}) // 상태를 수락으로 변경
          .eq('id', friendRowId); // 해당 요청 행의 ID

    } catch (e) {
      debugPrint('승인 실패: $e');
    }
  }

  // 친구 요청 거절
  Future<void> _rejectRequest(String friendRowId) async {
    try {
      await supabase
          .from('friends')
          .delete()
          .eq('id', friendRowId);
    } catch (e) {
      debugPrint('거절 실패: $e');
    }
  }

  // void addButtonAlert(
  //     {required String text,
  //       required String buttonYes,
  //       required String buttonNo}) {
  //   setState(() {
  //     alerts.add(ButtonAlert(
  //       text: text,
  //       buttonTextYes: buttonYes,
  //       buttonTextNo: buttonNo,
  //     ));
  //   });
  // }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("알림",
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
          : friendRequests.isEmpty
          ? const Center(child: Text("새로운 알림이 없습니다."))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: friendRequests.length,
        itemBuilder: (context, index) {
          final req = friendRequests[index];
          // users 테이블에서 가져온 닉네임
          final senderName = req['users']?['nickname'] ?? '알 수 없음';
          final rowId = req['id'].toString(); // friends 테이블의 PK

          return ButtonAlert(
            text: "$senderName님이 친구 신청을 보냈습니다.\n수락하시겠습니까?",
            buttonTextYes: "수락",
            buttonTextNo: "거절",
            // 승인 버튼 눌렀을 때 실행할 함수
            onYesTap: () async {
              await _acceptRequest(rowId);
            },
            // 거절 버튼 눌렀을 때 실행할 함수
            onNoTap: () async {
              await _rejectRequest(rowId);
            },
          );
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
                  onPressed: () async {
                    await widget.onYesTap();
                    setState(() {
                      result = "승인함";
                      // DB에 추가
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(widget.buttonTextYes),
                ),
                const SizedBox(width: 8),

                OutlinedButton(
                  onPressed: () async {
                    await widget.onNoTap();
                    setState(() {
                      result = "거절함";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    foregroundColor: Colors.black54,
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(widget.buttonTextNo),
                ),
              ],
            )
          else
            Center(
              child: Text(
                result!,
                style:  TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result=="승인함"? Colors.green:Colors.red,
                  fontSize: 14,
                ),
              ),
            )
        ],
      ),
    );
  }
}