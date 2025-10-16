//grouptap.dart  그룹 탭
import 'package:flutter/material.dart';

// 목표 데이터 모델 (Goal Model)
class Goal {
  final String id;
  String name;
  List<String> participants; // 참가 인원 목록
  double totalTargetTimeHours; // 목표 달성 총 시간 (1인당 기준 시간)
  Map<String, double> userCompletedTimeHours; // { '참가자 이름': 완료 시간 }

  Goal({
    required this.id,
    required this.name,
    required this.participants,
    required this.totalTargetTimeHours,
    required this.userCompletedTimeHours,
  });

  // 목표 달성을 위해 전체 참가자가 완료해야 하는 총 시간 (100% 기준)
  double get totalRequiredHours => totalTargetTimeHours * participants.length;

  // 현재까지 참가자들이 완료한 총 시간 (분자)
  double get currentCompletedHours {
    return userCompletedTimeHours.values.fold(0.0, (sum, time) => sum + time);
  }

  // 그룹 전체 달성률 계산 로직 (0.0 ~ 1.0)
  double get completionRate {
    if (totalRequiredHours == 0) return 0.0;
    return currentCompletedHours / totalRequiredHours;
  }

  // 그룹 전체 달성률 퍼센트 (0 ~ 100)
  int get completionPercentage => (completionRate * 100).round();

  // 목표가 완료되었는지 확인 (100% 이상)
  bool get isCompleted => completionRate >= 1.0;

  // 개별 참가자의 달성률 계산
  int getIndividualCompletionPercentage(String userName) {
    final completedTime = userCompletedTimeHours[userName] ?? 0.0;
    if (totalTargetTimeHours == 0) return 0;

    final rate = completedTime / totalTargetTimeHours;
    // 100%를 초과할 수 없도록 clamp 적용
    return (rate.clamp(0.0, 1.0) * 100).round();
  }

  // 특정 참가자의 완료 시간을 업데이트하는 메서드
  void addCompletionTime(String userName, double hours) {
    userCompletedTimeHours[userName] = (userCompletedTimeHours[userName] ?? 0.0) + hours;
  }
}


// Mock 데이터 (가상 데이터)
final List<Goal> mockGoals = [
  Goal(
    id: 'G001',
    name: "토익 900점 이상 받기",
    participants: ["현재 사용자", "지수", "민준", "유나"],
    totalTargetTimeHours: 20.0,
    userCompletedTimeHours: {"현재 사용자": 5.0, "지수": 5.0, "민준": 3.0, "유나": 0.0},
  ),
  Goal(
    id: 'G002',
    name: "체중 5kg 감량",
    participants: ["현재 사용자", "선우"],
    totalTargetTimeHours: 5.0,
    userCompletedTimeHours: {"현재 사용자": 5.0, "선우": 5.0},
  ),
  Goal(
    id: 'G003',
    name: "시험 만점",
    participants: ["현재 사용자", "은지", "태형", "수민", "현우"],
    totalTargetTimeHours: 30.0,
    userCompletedTimeHours: {"현재 사용자": 2.0, "은지": 1.0, "태형": 0.5, "수민": 2.0, "현우": 1.5},
  ),
];

class GroupGoalPage extends StatefulWidget {
  const GroupGoalPage({super.key});

  @override
  State<GroupGoalPage> createState() => _GroupGoalPageState();
}

class _GroupGoalPageState extends State<GroupGoalPage> {
  final List<Goal> goals = mockGoals;
  final String currentUser = "현재 사용자";

  // 목표 완료 팝업을 표시하는 함수
  void _showCompletionPopup(String goalName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("🎉 목표 완료!"),
          content: Text("공동 목표 '$goalName'이(가) 달성률 100%로 완료되었습니다! 축하합니다!", style: const TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.group, size: 30),
        title: const Text('그룹'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 목록
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return GoalCard(
                  goal: goals[index],
                  // 목표를 탭하면 바로 개인 목표 달성률로 이동
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailPage(goal: goals[index]),
                      ),
                    );
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


// 목표 카드 위젯 (GoalCard) - 그룹 목표 리스트 항목
class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap; // 탭 이벤트 콜백 추가

  const GoalCard({
    required this.goal,
    this.onTap,
    super.key,
  });

  static const String _currentUserIdentifier = "현재 사용자";

  @override
  Widget build(BuildContext context) {
    final double normalizedRate = goal.completionRate.clamp(0.0, 1.0);
    final bool isCompleted = goal.isCompleted;

    final List<String> friendParticipants = goal.participants
        .where((name) => name != _currentUserIdentifier)
        .toList();

    final String participantsList = friendParticipants.join(', ');

    Widget completionStatusWidget;
    if (isCompleted) {
      completionStatusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              "목표 완료됨",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      completionStatusWidget = const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      // Card 위젯을 InkWell로 감싸서 탭 이벤트를 추가
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Card의 BorderRadius와 일치시킴
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 참가 인원 목록 (현재 사용자 제외한 친구 이름만 표시)
              Text(
                participantsList.isEmpty ? "나만 참여 중" : participantsList,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),

              // 목표 이름
              Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // 목표 달성률 진행 바
                  Expanded(
                    child: LinearProgressIndicator(
                      value: normalizedRate,
                      backgroundColor: Colors.grey[300],
                      color: isCompleted ? Colors.green : Colors.blueAccent,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 달성률 텍스트
                  Text(
                    "${goal.completionPercentage}%",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isCompleted ? Colors.green : Colors.blueAccent,
                    ),
                  ),
                ],
              ),

              // 완료 상태 위젯 추가
              if (isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: completionStatusWidget,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}


// 목표 상세 페이지 (GoalDetailPage) - 개인 목표 달성률 표시
class GoalDetailPage extends StatelessWidget {
  final Goal goal;

  const GoalDetailPage({required this.goal, super.key});

  // 독촉하기 버튼 클릭 시 실행될 임시 함수
  void _nudge(String userName) {
    print('$userName 님에게 독촉 알림을 보냅니다');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "개인 목표 달성률",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 이름 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              goal.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),

          // 참가자 목록 (개인별 달성률 표시)
          Expanded(
            child: ListView.builder(
              itemCount: goal.participants.length,
              itemBuilder: (context, index) {
                final userName = goal.participants[index];
                // 각 참가자의 완료 시간 (시간 단위)
                final completedHours = goal.userCompletedTimeHours[userName] ??
                    0.0;
                final percentage = goal.getIndividualCompletionPercentage(
                    userName);
                final normalizedRate = percentage / 100.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin, size: 36,
                              color: Colors.blueGrey),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName, // 닉네임
                                  style: const TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),

                                // 달성률 진행 바와 텍스트
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: LinearProgressIndicator(
                                        value: normalizedRate,
                                        backgroundColor: Colors.grey[200],
                                        color: percentage >= 100
                                            ? Colors.green
                                            : Colors.blueAccent,
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 달성률 텍스트
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "$percentage%",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: percentage >= 100 ? Colors
                                              .green : Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 독촉하기 버튼
                          ElevatedButton(
                            onPressed: () => _nudge(userName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              elevation: 3,
                            ),
                            child: const Text(
                              "독촉하기",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}