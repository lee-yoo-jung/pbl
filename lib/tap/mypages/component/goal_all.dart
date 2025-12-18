import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// 목표 모델
class Goal {
  String name;
  List<String> participants;
  int achievement;
  DateTime end;

  Goal({
    required this.name,
    required this.participants,
    required this.achievement,
    required this.end,
  });
}

class GoalAll extends StatefulWidget {
  const GoalAll({super.key});

  @override
  State<GoalAll> createState() => _GoalAllState();
}

class _GoalAllState extends State<GoalAll> {
  List<Goal> _pastGoals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPastGoals();
  }

  // 달성도에 따른 나무 사진 인덱스
  int MaxStage(int progress) {
    if (progress < 15) return 0;
    if (progress < 30) return 1;
    if (progress < 45) return 2;
    if (progress < 60) return 3;
    if (progress < 75) return 4;
    if (progress < 90) return 5;
    if (progress < 100) return 6;
    return 7;
  }

  // 기간 지난 목표 DB 업데이트 로직
  Future<void> _checkAndExpireGoals() async {
    final myUid = supabase.auth.currentUser?.id;
    if (myUid == null) return;

    final now = DateTime.now();
    final todayStartStr = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      await supabase
          .from('goals')
          .update({'is_completed': true})
          .eq('owner_id', myUid)
          .eq('is_completed', false)
          .lt('completed_at', todayStartStr);

      // 공유 목표 업데이트
      await supabase
          .from('goal_shares')
          .update({'is_completed': true})
          .or('owner_id.eq.$myUid,together.cs.{$myUid}')
          .eq('is_completed', false)
          .lt('completed_at', todayStartStr);

    } catch (e) {
      debugPrint("기간 만료 목표 업데이트 중 에러: $e");
    }
  }

  // 과거 목표 데이터 가져오기
  Future<void> _fetchPastGoals() async {
    final myUid = supabase.auth.currentUser?.id;
    if (myUid == null) return;

    setState(() => _isLoading = true);

    await _checkAndExpireGoals();

    try {
      List<Goal> loadedGoals = [];

      final personalData = await supabase
          .from('goals')
          .select('id, title, completed_at, is_completed')
          .eq('owner_id', myUid);

      for (var item in personalData) {
        if (item['is_completed'] == true) {

          DateTime parsed = DateTime.parse(item['completed_at']);
          final endDate = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);

          // 달성률 계산
          final todos = await supabase
              .from('todos')
              .select('is_completed')
              .eq('goal_id', item['id']);

          int total = todos.length;
          int completed = todos.where((t) => t['is_completed'] == true).length;
          int achievement = total == 0 ? 0 : ((completed / total) * 100).round();

          loadedGoals.add(Goal(
            name: item['title'],
            participants: [],
            achievement: achievement,
            end: endDate,
          ));
        }
      }

      final sharedData = await supabase
          .from('goal_shares')
          .select('id, title, completed_at, together, owner_id, is_completed')
          .or('owner_id.eq.$myUid,together.cs.{$myUid}');

      for (var item in sharedData) {
        if (item['is_completed'] == true) {

          DateTime parsed = DateTime.parse(item['completed_at']);
          final endDate = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);

          List<dynamic> memberIds = item['together'] ?? [];
          if (!memberIds.contains(item['owner_id'])) {
            memberIds.add(item['owner_id']);
          }

          final otherMemberIds = memberIds.where((id) => id != myUid).toList();
          List<String> participantNames = [];

          if (otherMemberIds.isNotEmpty) {
            final users = await supabase
                .from('users')
                .select('nickname')
                .filter('id', 'in', otherMemberIds);
            participantNames = List<String>.from(users.map((u) => u['nickname']));
          }

          final todos = await supabase
              .from('todos_shares')
              .select('is_completed')
              .eq('goal_id', item['id']);

          int total = todos.length;
          int completed = todos.where((t) => t['is_completed'] == true).length;
          int achievement = total == 0 ? 0 : ((completed / total) * 100).round();

          loadedGoals.add(Goal(
            name: item['title'],
            participants: participantNames,
            achievement: achievement,
            end: endDate,
          ));
        }
      }

      // 최신순 정렬
      loadedGoals.sort((a, b) => b.end.compareTo(a.end));

      if (mounted) {
        setState(() {
          _pastGoals = loadedGoals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("완료된 목표 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 나무 이미지 에셋
    final List<String> treeImages = [
      'assets/images/tree1_tight.png',
      'assets/images/tree2_tight.png',
      'assets/images/tree3_tight.png',
      'assets/images/tree4_tight.png',
      'assets/images/tree5_tight.png',
      'assets/images/tree6_tight.png',
      'assets/images/tree7_tight.png',
      'assets/images/tree8_tight.png',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "완료한 목표",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard-Regular',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 60.0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pastGoals.isEmpty
          ? const Center(child: Text("완료된 목표가 없습니다."))
          : ListView.builder(
        itemCount: _pastGoals.length,
        itemBuilder: (context, index) {
          final goal = _pastGoals[index];

          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 1.0, vertical: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Divider(
                  color: Colors.grey.shade300,
                  height: 20,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
                Container(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          // 목표 이름
                          Text(
                            goal.name,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 참여한 사용자
                              if (goal.participants.isNotEmpty)
                                Text(
                                  '참여자: ${goal.participants.join(', ')}    |    ',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey),
                                ),

                              // 달성률 표시
                              Text(
                                '달성률: ${goal.achievement} %',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey),
                              ),
                              const SizedBox(width: 20),

                              // 나무 이미지
                              Image.asset(
                                treeImages[MaxStage(goal.achievement)],
                                width: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.park, color: Colors.green);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}