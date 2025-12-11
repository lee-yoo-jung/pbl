import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;


class Tree extends StatefulWidget {
  final String goalId;
  const Tree({super.key, required this.goalId});

  @override
  TreeState createState() => TreeState();
}

class TreeState extends State<Tree> {
  // 1. 상태 변수
  int stage = 0;
  double achievementRate = 0.0;
  bool isLoading = true;
  String? currentGoalId;

  // 여러 단계의 나무 사진
  final List<String> treeImages = [
    'assets/images/tree2.png',
    'assets/images/tree3.png',
    'assets/images/tree4.png',
    'assets/images/tree5.png',
    'assets/images/tree6.png',
    'assets/images/tree7.png',
    'assets/images/tree8.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadAchievementAndStage();
  }

  // 2. 달성률 계산 및 단계 로드 함수 (DB 로드 및 currentGoalId 저장)
  void _loadAchievementAndStage() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      // 2-1. todos 테이블에서 현재 사용자의 모든 목표 데이터와 연관된 goal_id를 가져옴
      final goalId = widget.goalId;

      final todosResponse = await supabase
          .from('todos')
          .select('created_at, is_completed')
          .eq('user_id', currentUserId)
          .eq('goal_id', goalId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> todosData = todosResponse.cast<
          Map<String, dynamic>>();

      if (todosData.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      // 2-2. goal_id 추출
      currentGoalId = widget.goalId;


      // 2-3. goals 테이블에서 기간 필드와 tree_stage를 가져옴
      final goalResponse = await supabase
          .from('goals')
          .select('created_at, completed_at, tree_stage')
          .eq('id', widget.goalId)
          .single();

      // 2-4. 기간(D) 계산 및 저장된 단계 로드
      final startDateString = goalResponse['created_at'] as String;
      final endDateString = goalResponse['completed_at'] as String?;
      final savedStage = goalResponse['tree_stage'] as int? ?? 0;

      if (endDateString == null) {
        print("Error: Goal completion date (completed_at) is missing.");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final startDate = DateTime.parse(startDateString).toLocal();
      final endDate = DateTime.parse(endDateString).toLocal();
      final int totalGoalDuration = endDate.difference(startDate).inDays + 1;

      // 2-5. 달성률 계산 로직 호출
      final calculatedRate = _calculateAchievementRate(
          todosData, totalGoalDuration);

      if (mounted) {
        setState(() {
          achievementRate = calculatedRate;
          stage = savedStage;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading goal data or todos: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터 로드 중 오류가 발생했습니다. DB 연결 확인 필요.')),
      );
    }
  }

  // 3. 달성률 계산 로직
  double _calculateAchievementRate(List<Map<String, dynamic>> todos,
      int totalGoalDuration) {
    if (todos.isEmpty || totalGoalDuration <= 0) return 0.0;

    final firstTodoDate = (todos
        .map((e) => DateTime.parse(e['created_at']).toLocal())
        .toList()
      ..sort((a, b) => a.compareTo(b)))
        .first;

    final today = DateTime.now().toLocal();
    int elapsedDays = today
        .difference(firstTodoDate)
        .inDays + 1;

    elapsedDays = elapsedDays.clamp(1, totalGoalDuration);

    final double dailyMaxRate = 100.0 / totalGoalDuration;
    final double maxPossibleRate = elapsedDays * dailyMaxRate;

    final todosUntilToday = todos.where((e) {
      final todoDate = DateTime.parse(e['created_at']).toLocal();
      final differenceInDays = todoDate
          .difference(firstTodoDate)
          .inDays;
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

  // 4. 달성도에 따른 나무 사진 인덱스
  int MaxStage(int progress) {
    if (progress < 15) return 0;
    if (progress < 30) return 1;
    if (progress < 45) return 2;
    if (progress < 60) return 3;
    if (progress < 75) return 4;
    if (progress < 90) return 5;
    if (progress < 100) return 6;
    return 7; // 100% (최종 단계)
  }

  // 5. 빌드 위젯
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: const AssetImage('assets/images/tree1.png'), // 배경 이미지
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('나무 키우기'),
              backgroundColor: Colors.transparent,),
            body: Column(
              children: [
                const SizedBox(height: 170),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: stage > 0
                        ? Image.asset(
                      treeImages[stage - 1],
                      key: ValueKey(stage),
                      width: width * 0.8,
                      height: height * 0.45,
                      fit: BoxFit.contain,
                    )
                        : const SizedBox(
                      width: 200,
                      height: 350,
                    ),
                  ),
                ),

                // 5. 달성률 반영 부분
                Padding(
                  padding: const EdgeInsets.only(
                      left: 50, right: 50, bottom: 5),
                  child: LinearProgressIndicator(
                    value: achievementRate,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                    minHeight: 15,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // 달성률 텍스트 반영
                Text(
                  '${(achievementRate * 100).toInt()}%',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),

                const SizedBox(height: 0),

                // 6. 성장시키기 버튼 (DB 저장 로직 포함)
                ElevatedButton(
                  onPressed: () async {
                    // DB 연결 및 목표 ID 유효성 검사
                    if (supabase.auth.currentUser?.id == null || currentGoalId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('사용자 또는 목표 정보가 없어 성장을 저장할 수 없습니다.')),
                      );
                      return;
                    }

                    int maxS = MaxStage((achievementRate * 100).toInt());

                    if (stage < maxS) {
                      final newStage = stage + 1;

                      try {
                        // goals 테이블에 새로운 stage 값을 저장
                        await supabase
                            .from('goals')
                            .update({'tree_stage': newStage}) // goals 테이블 업데이트
                            .eq('id', widget.goalId);

                        setState(() {
                          stage = newStage; // DB 업데이트 성공 후 로컬 상태 업데이트
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('성장 단계 저장에 실패했습니다. (DB 권한 확인)')),
                        );
                        print("DB Update Error: $e");
                      }

                    } else if (stage == 7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('나무가 최종 단계에 도달했습니다!'),
                          duration: Duration(milliseconds: 1500),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('현재 달성률 ${(achievementRate * 100).toInt()}%로는 더 이상 성장할 수 없습니다.'),
                          duration: Duration(milliseconds: 1500),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('성장시키기', style: TextStyle(fontSize: 18),),
                ),
              ],
            ),
          ),
        )
    );
  }
}