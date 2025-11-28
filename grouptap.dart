//grouptap.dart  그룹 탭
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pbl/const/colors.dart';

// 세부 계획 데이터 모델
class SubTask {
  final String name;               // 세부 계획 이름
  final List<String> completedBy;  // 완료한 사람 목록

  SubTask({
    required this.name,
    required this.completedBy,
  });

  // 특정 참가자가 이 세부 계획을 완료했는지 확인
  bool isCompletedBy(String userName) => completedBy.contains(userName);
}


// 목표 데이터 모델 (Goal Model)
class Goal {
  final String id;
  String name;
  List<String> participants; // 참가 인원 목록
  List<SubTask> subTasks;

  Goal({
    required this.id,
    required this.name,
    required this.participants,
    required this.subTasks,
  });

  // 목표 달성을 위해 필요한 전체 세부 계획 수 (총 계획 수)
  int get totalSubTasks => subTasks.length;

  // 목표 달성을 위해 전체 참가자가 완료해야 하는 총 계획 단위 (100% 기준)
  // (총 계획 수 * 전체 참가자 수)
  int get totalRequiredPlanUnits => totalSubTasks * participants.length;

  // 현재까지 모든 참가자가 완료한 세부 계획의 총 수
  // (각 세부 계획에 대해 완료한 참가자의 수를 합산)
  int get totalCompletedPlanUnits {
    return subTasks.fold(
      0,
          (sum, task) => sum + task.completedBy.length,
    );
  }

  // 그룹 전체 달성률 계산 로직 (0.0 ~ 1.0)
  // (현재 완료된 계획 단위 수 / 전체 필요 계획 단위 수)
  double get completionRate {
    if (totalRequiredPlanUnits == 0) return 0.0;
    return totalCompletedPlanUnits / totalRequiredPlanUnits;
  }

  // 그룹 전체 달성률 퍼센트 (0 ~ 100)
  int get completionPercentage => (completionRate.clamp(0.0, 1.0) * 100).round();

  // 목표가 완료되었는지 확인 (100% 이상)
  bool get isCompleted => completionRate >= 1.0;

  // 개별 참가자가 완료한 세부 계획 수
  int getIndividualCompletedCount(String userName) {
    return subTasks.where((task) => task.isCompletedBy(userName)).length;
  }

  // 개별 참가자의 달성률 계산
  int getIndividualCompletionPercentage(String userName) {
    if (totalSubTasks == 0) return 0;

    final completedCount = getIndividualCompletedCount(userName);
    final rate = completedCount / totalSubTasks;
    // 100%를 초과할 수 없도록 clamp 적용
    return (rate.clamp(0.0, 1.0) * 100).round();
  }

  // 특정 참가자의 특정 세부 계획 완료 상태를 토글하는 임시 메서드
  void toggleSubTaskCompletion(String userName, SubTask task) {
    if (task.completedBy.contains(userName)) {
      task.completedBy.remove(userName);
    } else {
      task.completedBy.add(userName);
    }
  }
}


// Mock 데이터
final List<Goal> mockGoals = [
  Goal(
    id: 'G001',
    name: "토익 900점 이상 받기",
    participants: ["현재 사용자", "지수", "민준", "유나"],
    // 총 5개의 세부 계획
    subTasks: [
      SubTask(name: "RC 문법 강의 완강", completedBy: ["현재 사용자", "지수"]),
      SubTask(name: "LC 쉐도잉 100회", completedBy: ["현재 사용자", "지수", "민준"]),
      SubTask(name: "실전 모의고사 1회", completedBy: ["현재 사용자"]),
      SubTask(name: "오답 노트 정리", completedBy: []), // 아무도 완료하지 않음
      SubTask(name: "단어장 100% 암기", completedBy: ["현재 사용자", "지수", "민준", "유나"]), // 모두 완료
    ],
  ),
  Goal(
    id: 'G002',
    name: "체중 5kg 감량",
    participants: ["현재 사용자", "선우"],
    // 총 2개의 세부 계획 (100% 달성 상태)
    subTasks: [
      SubTask(name: "매일 30분 달리기", completedBy: ["현재 사용자", "선우"]),
      SubTask(name: "야식 끊기", completedBy: ["현재 사용자", "선우"]),
    ],
  ),
  Goal(
    id: 'G003',
    name: "시험 만점",
    participants: ["현재 사용자", "은지", "태형", "수민", "현우"],
    // 총 4개의 세부 계획
    subTasks: [
      SubTask(name: "개념 요약본 만들기", completedBy: ["현재 사용자", "은지", "태형", "수민", "현우"]),
      SubTask(name: "기출 문제 풀이", completedBy: ["현재 사용자", "은지"]),
      SubTask(name: "심화 문제 풀이", completedBy: []),
      SubTask(name: "핵심 개념 암기", completedBy: ["현재 사용자", "은지", "태형"]),
    ],
  ),
];


// 목표 완료 팝업 기록을 위한 전역 상태 (Static)
// 팝업이 이미 표시되었는지 추적하는 Set을 State 밖으로 옮겨서
// 위젯이 파괴되어도 값이 유지됨
final Set<String> _globallyCompletedGoalsShown = <String>{};


class GroupGoalPage extends StatefulWidget {
  const GroupGoalPage({super.key});

  @override
  State<GroupGoalPage> createState()=>_GroupGoalPageState();
}

class _GroupGoalPageState extends State<GroupGoalPage> {
  final List<Goal> goals = mockGoals;
  final String currentUser = "현재 사용자";


  void _showCompletionPopup(String goalName) {
    // 팝업이 이미 표시되었는지 전역 Set에서 다시 한번 확인
    if (_globallyCompletedGoalsShown.contains(goalName)) return;

    // 팝업 표시 후 전역 Set에 추가 ( setState() 호출 전에)
    // setState를 호출하여 UI를 업데이트할 필요가 없으므로 setState를 제거
    _globallyCompletedGoalsShown.add(goalName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("목표 완료!"),
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
  void initState() {
    super.initState();
    // 위젯이 처음 빌드된 후 (첫 프레임 렌더링 후) 한 번만 실행되도록 예약
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var goal in goals) {
        if (goal.isCompleted) {
          _showCompletionPopup(goal.name);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: const Icon(Icons.groups, size: 30),
        title: const Text("그룹",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard-Regular',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 40.0,
        backgroundColor: Colors.white, // 이미지의 상단 바 색상
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
                return
                  GoalCard(
                  goal: goals[index],
                  // 목표를 탭하면 바로 개인 목표 달성률로 이동
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailPage(
                            goal: goals[index],
                            currentUser: currentUser // 현재 사용자 이름 전달
                        ),
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

// 목표 카드 위젯
class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black54,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.blueGrey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              "목표 완료됨",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      completionStatusWidget = const SizedBox.shrink();
    }

    return Column(
     children: [
       Container(
         margin: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 15),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(5),
           border: Border.all(color:Colors.white10)
         ),
         child: InkWell(
           onTap: onTap,
           child: Padding(
             padding: const EdgeInsets.all(25.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
             // 참가 인원 목록 (현재 사용자 제외한 친구 이름만 표시)
             Text(
             participantsList.isEmpty ? "나만 참여 중" : participantsList,
               style: TextStyle(
                 fontSize: 15,
                 color: Colors.black54,
                 fontFamily: 'Pretendard-Medium',
                 fontWeight: FontWeight.w500,
               ),
             ),
             const SizedBox(height: 5),
            Row(
              children: [// 목표 이름
                Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Pretendard-Bold',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 70),
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
       ),
     ],
    );
  }
}

// 목표 상세 페이지
class GoalDetailPage extends StatelessWidget {
  final Goal goal;
  final String currentUser;
  const GoalDetailPage({required this.goal, required this.currentUser, super.key});


  void _nudge(String userName, int completedCount, int totalCount) {
    // 독촉하기 버튼 클릭 시, 현재 달성률을 콘솔에 출력 (디버깅용)
    print('$userName 님에게 독촉 알림을 보냅니다. (현재 완료 수: $completedCount / $totalCount)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              "개인 목표 달성률",
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 20,
                fontFamily: 'Pretendard-Regular',
                fontWeight: FontWeight.w700,
              ),
            ),
            toolbarHeight: 60.0,
            backgroundColor: Colors.white, // 이미지의 상단 바 색상

          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 목표 이름 헤더
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
                          fontFamily: 'Pretendard-SemiBold',
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 세부 계획 수 정보를 추가로 표시
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
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                            ),
                            message: "• 개인 보상: 세부 계획 개수에 따라 경험치 추가 \n "
                                "e.g 10개:+5 | 20개:+10 | 30개:+15 | 40개:+20 | 50개:+25)\n"
                                "\n • 그룹 보상: 그룹 평균 달성률에 따라 경험치 추가 \n"
                                "e.g 60%:+10 | 70%:+20 | 80%:+30 | 90%:+40 | 100%:+50",
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.info_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 10,),
                          Text(
                            '참가 중인 인원: ${goal.participants.length}명',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Pretendard-Medium',
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

              // 참가자 목록 (개인별 달성률 표시)
              Expanded(
                child: ListView.builder(
                  itemCount: goal.participants.length,
                  itemBuilder: (context, index) {
                    final userName = goal.participants[index];
                    final bool isCurrentUser = userName == currentUser;

                    // 개인이 완료한 세부 계획 수
                    final completedCount = goal.getIndividualCompletedCount(userName);
                    // 개별 달성률 퍼센트
                    final percentage = goal.getIndividualCompletionPercentage(userName);
                    final normalizedRate = percentage / 100.0;

                    return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            Divider(
                              color: Colors.grey.shade300, // 선 색상
                              height: 20,         // 위젯의 높이
                              thickness: 1,       // 선의 실제 두께
                              indent: 10,         // 시작 지점
                              endIndent: 10,      // 끝 지점
                            ),
                            Container(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_pin, size: 36,
                                        color: Colors.grey),
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
                                          // 완료된 세부 계획 수 표시
                                          Text(
                                            '완료: $completedCount / ${goal.totalSubTasks}개',
                                            style: const TextStyle(fontSize: 12,
                                                color: Colors.blueGrey),
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
                                                      ? Colors.black54
                                                      : Colors.grey,
                                                  minHeight: 8,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // 달성률 텍스트
                                              Expanded(
                                                flex: 1,
                                                child:Text(
                                                  "$percentage%",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: percentage >= 100 ? Colors
                                                        .black87 : Colors.grey[700],
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
                                    // isCurrentUser 변수를 사용하여 현재 사용자가 아닐 때+달성률이 100(목표완료)가 아닐때 버튼을 표시
                                    if (!isCurrentUser&&percentage!=100)
                                      Column(
                                        children: [
                                          IconButton(
                                            onPressed: () => _nudge(userName, completedCount, goal.totalSubTasks),
                                            icon: const Icon(Icons.local_fire_department_sharp),iconSize: 30, color: Colors.red,
                                          ),
                                          Text('Hurry Up', style: TextStyle( fontSize: 13),)
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