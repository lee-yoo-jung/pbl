import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Tree extends StatefulWidget {
  final String goalId;
  const Tree({Key? key, required this.goalId}) : super(key: key);

  @override
  TreeState createState() => TreeState();
}

class TreeState extends State<Tree> {
  // 상태 변수
  int stage = 0;
  double achievementRate = 0.0;
  bool isLoading = true;

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

  @override
  void didUpdateWidget(covariant Tree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goalId != widget.goalId) {
      setState(() {
        isLoading = true;
        stage = 0;
        achievementRate = 0.0;
      });
      _loadAchievementAndStage();
    }
  }

  // 달성률 계산 및 단계 로드 함수
  Future<void> _loadAchievementAndStage() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final todosResponse = await supabase
          .from('todos')
          .select('created_at, is_completed')
          .eq('user_id', currentUserId)
          .eq('goal_id', widget.goalId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> todosData = todosResponse.cast<Map<String, dynamic>>();

      // 투두가 하나도 없으면 로딩 종료
      if (todosData.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final goalResponse = await supabase
          .from('goals')
          .select('created_at, completed_at, tree_stage')
          .eq('id', widget.goalId)
          .single();

      final startDateString = goalResponse['created_at'] as String;
      final endDateString = goalResponse['completed_at'] as String?;

      // DB에 저장된 단계가 없으면 0으로 시작
      final savedStage = goalResponse['tree_stage'] as int? ?? 0;

      if (endDateString == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final startDate = DateTime.parse(startDateString).toLocal();
      final endDate = DateTime.parse(endDateString).toLocal();
      final int totalGoalDuration = endDate.difference(startDate).inDays + 1;

      // 달성률 계산 로직 호출
      final calculatedRate = _calculateAchievementRate(todosData, totalGoalDuration);

      if (mounted) {
        setState(() {
          achievementRate = calculatedRate;
          stage = savedStage;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading tree data: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 달성률 계산 로직
  double _calculateAchievementRate(List<Map<String, dynamic>> todos, int totalGoalDuration) {
    if (todos.isEmpty || totalGoalDuration <= 0) return 0.0;

    final firstTodoDate = (todos
        .map((e) => DateTime.parse(e['created_at']).toLocal())
        .toList()
      ..sort((a, b) => a.compareTo(b)))
        .first;

    final today = DateTime.now().toLocal();
    int elapsedDays = today.difference(firstTodoDate).inDays + 1;
    elapsedDays = elapsedDays.clamp(1, totalGoalDuration);

    final double dailyMaxRate = 100.0 / totalGoalDuration;
    final double maxPossibleRate = elapsedDays * dailyMaxRate;

    final todosUntilToday = todos.where((e) {
      final todoDate = DateTime.parse(e['created_at']).toLocal();
      final differenceInDays = todoDate.difference(firstTodoDate).inDays;
      return differenceInDays < elapsedDays;
    }).toList();

    if (todosUntilToday.isEmpty) return 0.0;

    final double ratePerTodo = maxPossibleRate / todosUntilToday.length;
    final completedTodoCount = todosUntilToday.where((e) => e['is_completed'] == true).length;
    final achievedRate = (completedTodoCount * ratePerTodo).clamp(0.0, 100.0);

    return achievedRate / 100.0;
  }

  // 최대 성장 가능 단계 계산
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/tree1.png'), // 배경
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('나무 키우기', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: Column(
            children: [
              const SizedBox(height: 150),

              // 나무 이미지
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
                  child: stage > 0 && stage <= treeImages.length
                      ? Image.asset(
                    treeImages[stage - 1],
                    key: ValueKey('${widget.goalId}_$stage'),
                    width: width * 0.8,
                    height: height * 0.45,
                    fit: BoxFit.contain,
                  )
                      : const SizedBox(width: 200, height: 350),
                ),
              ),

              // 달성률 게이지
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                child: LinearProgressIndicator(
                  value: achievementRate,
                  backgroundColor: Colors.white54,
                  color: const Color(0xFF4CAF50), // 진한 초록색
                  minHeight: 15,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                '${(achievementRate * 100).toInt()}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),

              const SizedBox(height: 20),

              // 성장 버튼
              ElevatedButton(
                onPressed: () async {
                  if (supabase.auth.currentUser?.id == null) return;

                  int maxS = MaxStage((achievementRate * 100).toInt());

                  if (stage < maxS) {
                    final newStage = stage + 1;
                    try {
                      await supabase
                          .from('goals')
                          .update({'tree_stage': newStage})
                          .eq('id', widget.goalId);

                      setState(() {
                        stage = newStage;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('나무가 $newStage단계로 성장했습니다! 🌱')),
                      );
                    } catch (e) {
                      print("DB Update Error: $e");
                    }
                  } else if (stage >= 7) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('나무가 완전히 자랐습니다! 🌳')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('아직 성장할 수 없습니다. 투두를 더 완료하세요! (현재: ${(achievementRate*100).toInt()}%)')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // 숲색 버튼
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text('성장시키기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}