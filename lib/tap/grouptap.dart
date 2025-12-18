import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:pbl/services/badge_service.dart';

// 달성률 계산 함수
double _calculateTimePacedAchievement({
  required DateTime startDate,
  required DateTime endDate,
  required List<dynamic> todos,
}) {
  if (todos.isEmpty) return 0.0;

  int totalGoalDuration = endDate.difference(startDate).inDays + 1;
  if (totalGoalDuration <= 0) return 0.0;

  final firstTodoDate = (todos
      .map((e) => DateTime.parse(e['created_at']).toLocal())
      .toList()
    ..sort((a, b) => a.compareTo(b)))
      .firstOrNull ?? startDate;

  final today = DateTime.now().toLocal();
  DateTime calcPoint = today.isAfter(endDate) ? endDate : today;

  int elapsedDays = calcPoint.difference(firstTodoDate).inDays + 1;
  elapsedDays = elapsedDays.clamp(1, totalGoalDuration);

  final double dailyMaxRate = 100.0 / totalGoalDuration;
  final double maxPossibleRate = elapsedDays * dailyMaxRate;

  final todosUntilToday = todos.where((e) {
    final todoDate = DateTime.parse(e['created_at']).toLocal();
    final differenceInDays = todoDate.difference(firstTodoDate).inDays;
    return differenceInDays < elapsedDays;
  }).toList();

  final totalTodoCountUntilToday = todosUntilToday.length;
  if (totalTodoCountUntilToday == 0) return 0.0;

  final double ratePerTodo = maxPossibleRate / totalTodoCountUntilToday;
  final completedTodoCount = todosUntilToday
      .where((e) => e['is_completed'] == true)
      .length;

  final achievedRate = (completedTodoCount * ratePerTodo).clamp(0.0, 100.0);

  return achievedRate / 100.0;
}

// 데이터 모델
class MemberProgress {
  final String uid;
  final String nickname;
  final int totalTasks;
  final int completedTasks;
  final double calculatedRate;

  MemberProgress({
    required this.uid,
    required this.nickname,
    required this.totalTasks,
    required this.completedTasks,
    required this.calculatedRate,
  });

  int get percentage => (calculatedRate * 100).round();
}

class Goal {
  final String id;
  final String name;
  final String ownerId;
  final double groupRate;
  final Map<String, MemberProgress> members;

  Goal({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.groupRate,
    required this.members,
  });

  List<String> get participantNames => members.values.map((e) => e.nickname).toList();
  int get completionPercentage => (groupRate * 100).round();
  bool get isCompleted => groupRate >= 1.0;
}

// 메인 화면
class GroupGoalPage extends StatefulWidget {
  const GroupGoalPage({super.key});

  @override
  State<GroupGoalPage> createState() => _GroupGoalPageState();
}

class _GroupGoalPageState extends State<GroupGoalPage> {
  final supabase = Supabase.instance.client;
  List<Goal> _goals = [];
  bool _isLoading = true;
  String? _myUid;
  String _myNickname = "나";

  final Set<String> _shownPopups = {};

  // 실시간 구독을 위한 변수 선언
  StreamSubscription? _goalSubscription;
  StreamSubscription? _todoSubscription;

  @override
  void initState() {
    super.initState();
    _fetchGroupGoals(); // 초기 데이터 로드
    _setupRealtimeStreams();
  }

  @override
  void dispose() {
    _goalSubscription?.cancel();
    _todoSubscription?.cancel();
    super.dispose();
  }

  // 실시간 감지 설정 함수
  void _setupRealtimeStreams() {
    _goalSubscription = supabase
        .from('goal_shares')
        .stream(primaryKey: ['id'])
        .listen((data) {
      _fetchGroupGoals();
    });

    _todoSubscription = supabase
        .from('todos_shares')
        .stream(primaryKey: ['id'])
        .listen((data) {
      _fetchGroupGoals();
    });
  }

  Future<void> _fetchGroupGoals() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _myUid = user.id;

    if (!mounted) return;

    if (_goals.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final myProfile = await supabase.from('users').select('nickname').eq('id', _myUid!).single();
      _myNickname = myProfile['nickname'] ?? '나';

      final goalsData = await supabase
          .from('goal_shares')
          .select('id, title, owner_id, together, created_at, completed_at')
          .or('owner_id.eq.$_myUid,together.cs.{$_myUid}');

      List<Goal> loadedGoals = [];

      for (var gData in goalsData) {
        final goalId = gData['id'].toString();
        final title = gData['title'] ?? '제목 없음';
        final ownerId = gData['owner_id'];
        final startDate = DateTime.parse(gData['created_at']);
        DateTime endDateRaw = DateTime.parse(gData['completed_at']).toLocal();
        final endDate = DateTime(endDateRaw.year, endDateRaw.month, endDateRaw.day, 23, 59, 59);

        final List<dynamic> together = gData['together'] ?? [];
        final Set<String> participantIds = {ownerId, ...together.map((e) => e.toString())};

        // 사용자 닉네임 가져오기
        final usersData = await supabase
            .from('users')
            .select('id, nickname')
            .filter('id', 'in', participantIds.toList());

        Map<String, String> idToName = {};
        for (var u in usersData) {
          idToName[u['id']] = u['nickname'];
        }

        // 해당 목표의 투두 리스트 가져오기
        final todosData = await supabase
            .from('todos_shares')
            .select('user_id, is_completed, created_at')
            .eq('goal_id', goalId);

        // 전체 그룹 달성률 계산
        double groupTotalRate = _calculateTimePacedAchievement(
          startDate: startDate,
          endDate: endDate,
          todos: todosData,
        );

        // 멤버별 달성률 계산
        Map<String, MemberProgress> membersMap = {};
        for (var uid in participantIds) {
          final myTasks = todosData.where((t) => t['user_id'] == uid).toList();
          final total = myTasks.length;
          final completed = myTasks.where((t) => t['is_completed'] == true).length;
          double myRate = _calculateTimePacedAchievement(
            startDate: startDate,
            endDate: endDate,
            todos: myTasks,
          );

          membersMap[uid] = MemberProgress(
            uid: uid,
            nickname: idToName[uid] ?? '알 수 없음',
            totalTasks: total,
            completedTasks: completed,
            calculatedRate: myRate,
          );
        }

        loadedGoals.add(Goal(
          id: goalId,
          name: title,
          ownerId: ownerId,
          groupRate: groupTotalRate,
          members: membersMap,
        ));
      }

      if (mounted) {
        final activeGoals = loadedGoals.where((goal) => !goal.isCompleted).toList();

        setState(() {
          _goals = activeGoals;
          _isLoading = false;
        });

        _checkCompletionPopups();
      }

    } catch (e) {
      debugPrint("그룹 목표 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkCompletionPopups() {
    for (var goal in _goals) {
      if (goal.isCompleted && !_shownPopups.contains(goal.id)) {
        _shownPopups.add(goal.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCompletionPopup(goal.name);
        });
      }
    }
  }

  void _showCompletionPopup(String goalName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfettiDialog(goalName: goalName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: const Icon(Icons.groups, size: 30),
        title: const Text("그룹",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 40.0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
          ? const Center(child: Text("참여 중인 그룹 목표가 없습니다."))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                return GoalCard(
                  goal: _goals[index],
                  myUid: _myUid ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailPage(
                          goal: _goals[index],
                          currentUserUid: _myUid ?? '',
                        ),
                      ),
                    ).then((_) {
                      // 상세 페이지에서 돌아왔을 때도 즉시 갱신
                      _fetchGroupGoals();
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// UI 컴포넌트: GoalCard
class GoalCard extends StatelessWidget {
  final Goal goal;
  final String myUid;
  final VoidCallback? onTap;

  const GoalCard({
    required this.goal,
    required this.myUid,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = goal.isCompleted;

    // 나를 제외한 참여자 이름 리스트 생성
    final friendNames = goal.members.values
        .where((m) => m.uid != myUid)
        .map((m) => m.nickname)
        .toList();

    final String participantsList = friendNames.join(', ');

    Widget completionStatusWidget = isCompleted
        ? Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black54),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: PRIMARY_COLOR, size: 20),
          const SizedBox(width: 8),
          const Text(
            "목표 완료됨",
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              color: PRIMARY_COLOR,
            ),
          ),
        ],
      ),
    )
        : const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white10)
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participantsList.isEmpty ? "나만 참여 중" : participantsList,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 목표 이름
                      Expanded(
                        child: Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 퍼센트 텍스트
                      Text(
                        "${goal.completionPercentage}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: goal.completionPercentage >= 100
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // 진행 바
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: goal.groupRate.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: goal.isCompleted ? PRIMARY_COLOR : Colors.blueAccent,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: completionStatusWidget),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// UI 컴포넌트: GoalDetailPage
class GoalDetailPage extends StatelessWidget {
  final Goal goal;
  final String currentUserUid;

  const GoalDetailPage({
    required this.goal,
    required this.currentUserUid,
    super.key
  });

  // 백엔드: 독촉 기능
  Future<void> _nudge(BuildContext context, String targetUid, String targetNickname) async {
    final supabase = Supabase.instance.client;
    final currentUserUid = supabase.auth.currentUser!.id;

    try {
      await supabase.from('notifications').insert({
        'sender_id': currentUserUid,
        'receiver_id': targetUid,
        'type': 'nudge',
        'content': '님이 "$targetNickname"님을 재촉하고 있습니다! 🔥',
        'related_id': goal.id,
        'is_read': false,
      });

      await BadgeService().checkCheerBadges(context, currentUserUid, targetUid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$targetNickname님에게 독촉 알림을 보냈습니다! 🔥')),
        );
      }
    } catch (e) {
      debugPrint("독촉 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = goal.members.values.toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "개인 목표 달성률",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 50.0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          preferBelow: false,
                          verticalOffset: -150,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          triggerMode: TooltipTriggerMode.tap,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          message: "• 개인 보상: 세부 계획 개수에 따라 경험치 추가 \n"
                              "• 그룹 보상: 그룹 평균 달성률에 따라 경험치 추가",
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.info_rounded, size: 16, color: Colors.grey),
                        ),
                        const SizedBox(width: 10,),
                        Text(
                          '참가 중인 인원: ${participants.length}명',
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    )
                )
              ],
            ),
          ),

          // 참가자 리스트
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final member = participants[index];
                final bool isCurrentUser = member.uid == currentUserUid;

                final completedCount = member.completedTasks;
                final totalCount = member.totalTasks;
                final percentage = member.percentage;
                final normalizedRate = member.calculatedRate.clamp(0.0, 1.0);

                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
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
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person_pin, size: 36, color: Colors.grey),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.nickname,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '완료: $completedCount / $totalCount개',
                                        style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 12,
                                            color: Colors.blueGrey
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: LinearProgressIndicator(
                                              value: normalizedRate,
                                              backgroundColor: Colors.grey[200],
                                              color: percentage >= 100
                                                  ? Colors.black54
                                                  : Colors.grey,
                                              minHeight: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "$percentage%",
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: percentage >= 100 ? Colors.black87 : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // 독촉하기 버튼
                                if (!isCurrentUser && percentage < 100)
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () => _nudge(context, member.uid, member.nickname),
                                        icon: const Icon(Icons.local_fire_department_sharp),
                                        iconSize: 30,
                                        color: Colors.red,
                                      ),
                                      const Text('Hurry Up',
                                        style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12
                                        ),
                                      )
                                    ],
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiDialog extends StatefulWidget {
  final String goalName;

  const ConfettiDialog({
    Key? key,
    required this.goalName,
  }) : super(key: key);

  @override
  State<ConfettiDialog> createState() => _ConfettiDialogState();
}

class _ConfettiDialogState extends State<ConfettiDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -pi / 2,
            emissionFrequency: 0.02,
            numberOfParticles: 50,
            maxBlastForce: 25,
            minBlastForce: 15,
            gravity: 0.01,
            colors: const [
              PRIMARY_COLOR,
              Color(0xFF81C7D4),
              Color(0xFFE57373),
              Colors.white,
              Color(0xFFD3D3D3),
              Color(0xFFFFB74D),
              Color(0xFFFFF176),
              Color(0xFFAED581),
            ],
            shouldLoop: false,
          ),
        ),

        AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "목표 완료! 🎉",
            style: TextStyle(
              fontFamily: "Pretendard",
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text.rich(
            TextSpan(
              children: <TextSpan>[
                const TextSpan(
                  text: '축하합니다!\n',
                  style: TextStyle(
                    fontFamily: "Pretendard",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PRIMARY_COLOR,
                  ),
                ),
                TextSpan(
                  text: "공동 목표 '${widget.goalName}'의 달성률이 100%가 되었습니다!",
                  style: const TextStyle(
                    fontFamily: "Pretendard",
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: PRIMARY_COLOR,
                foregroundColor: Colors.black87,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
        const SizedBox(height: 80,),
      ],
    );
  }
}